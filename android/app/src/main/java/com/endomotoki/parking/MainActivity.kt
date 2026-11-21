package com.endomotoki.parking

import android.annotation.SuppressLint
import android.app.backup.BackupManager
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.webkit.WebViewAssetLoader
import org.json.JSONObject

/** ゲーム画面（Web）・広告・課金をつなぐ（iOS 版の AppModel と GameWebView にあたる） */
class MainActivity : AppCompatActivity() {
    private lateinit var web: WebView
    private lateinit var bannerBox: FrameLayout
    private lateinit var store: Store
    private lateinit var ads: Ads

    /** ゲームの今の画面（menu / play / result / demo） */
    private var screen = "menu"
    private var webReady = false
    /** 初回の説明（チュートリアル）を表示中か。表示中は広告を始めず、バナーも出さない */
    private var tutorialOpen = true
    private var adsStarted = false
    private var resultsLeft = 0

    /** 進み具合（Web 側の localStorage と同じ文字列）。この SharedPreferences だけを Google のバックアップに入れる */
    private val cloud by lazy { getSharedPreferences("cloud", MODE_PRIVATE) }
    private val cloudKeys = setOf("stageUnlocked", "hardUnlocked", "bestScores", "badges", "parkingSettings", "tutorialSeen")

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Telemetry.start(this)

        // 画面いっぱいに表示し、切り欠き（カメラ部分）だけ避ける。ステータスバーとナビゲーションバーは隠す（端からスワイプで一時表示）
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setBackgroundColor(0xFF000000.toInt()) }
        web = WebView(this)
        bannerBox = FrameLayout(this).apply { visibility = View.GONE }
        root.addView(web, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        root.addView(bannerBox, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        setContentView(root)
        ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
            val i = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            v.setPadding(i.left, i.top, i.right, i.bottom)
            insets
        }
        hideSystemBars()

        store = Store(this) { runOnUiThread { pushState(); updateBanner() } }
        ads = Ads(this, bannerBox)

        // 同梱したゲームを https://appassets.androidplatform.net/assets/ として読み込む（localStorage が使えるように）
        val loader = WebViewAssetLoader.Builder().addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this)).build()
        web.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            mediaPlaybackRequiresUserGesture = false
            setSupportZoom(false)
            builtInZoomControls = false
            allowFileAccess = false
        }
        web.setBackgroundColor(0xFF000000.toInt())
        web.isVerticalScrollBarEnabled = false
        web.isHorizontalScrollBarEnabled = false
        web.overScrollMode = View.OVER_SCROLL_NEVER
        WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG)
        web.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? =
                loader.shouldInterceptRequest(request.url)
            // ゲームの外へのリンクはアプリの中で開かない
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean =
                request.url.host != "appassets.androidplatform.net"
            override fun onPageFinished(view: WebView, url: String) {
                // 動作確認・スクリーンショット用：起動時に渡したコード（js）を、読み込みのあとに実行（Debug ビルドのみ）
                if (BuildConfig.DEBUG) Log.d("web", "page finished $url js=${intent.getStringExtra("js") != null}")
                if (BuildConfig.DEBUG) intent.getStringExtra("js")?.let { js -> view.postDelayed({ view.evaluateJavascript(js, null) }, 2500) }
            }
        }
        if (BuildConfig.DEBUG) web.webChromeClient = object : WebChromeClient() {
            // 動作確認用：ゲームのエラーやログを logcat に出す（Debug ビルドのみ）
            override fun onConsoleMessage(m: ConsoleMessage): Boolean {
                Log.d("web", "${m.messageLevel()} ${m.message()} (${m.sourceId()}:${m.lineNumber()})"); return true
            }
        }
        web.addJavascriptInterface(Bridge(), "AndroidApp")
        web.loadUrl("https://appassets.androidplatform.net/assets/index.html")

        // 戻るボタン：メニューならアプリを閉じる（バックグラウンドへ）、運転中などならメニューを開く
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (screen == "menu" && !tutorialOpen) moveTaskToBack(true)
                else sendToWeb("window.dispatchEvent(new KeyboardEvent('keydown', { code: 'Escape', key: 'Escape' }))")
            }
        })
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        ads.reloadBanner()   // 向きが変わったら、画面の幅に合わせてバナーを作り直す
    }

    override fun onPause() { web.onPause(); super.onPause() }
    override fun onResume() { super.onResume(); web.onResume(); store.refresh() }
    override fun onDestroy() { ads.destroy(); store.end(); web.destroy(); super.onDestroy() }

    private fun hideSystemBars() {
        WindowInsetsControllerCompat(window, window.decorView).apply {
            hide(WindowInsetsCompat.Type.systemBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    private fun sendToWeb(js: String) = runOnUiThread { web.evaluateJavascript(js, null) }

    /** ゲームから届くメッセージ（JavaScript の AndroidApp.postMessage） */
    inner class Bridge {
        @JavascriptInterface
        fun postMessage(json: String) {
            val msg = try { JSONObject(json) } catch (e: Exception) { return }
            runOnUiThread { handle(msg) }
        }
    }

    // 結果の画像と文章を、端末の共有画面（X・LINE・Instagram など）で送る。画像はアプリのキャッシュに書き、FileProvider で渡す
    private fun shareResult(dataUrl: String, text: String) {
        val comma = dataUrl.indexOf(',')
        if (comma < 0) return
        val bytes = try { android.util.Base64.decode(dataUrl.substring(comma + 1), android.util.Base64.DEFAULT) } catch (e: Exception) { return }
        val dir = java.io.File(cacheDir, "share").apply { mkdirs() }
        val file = java.io.File(dir, "parking-result.jpg")
        file.writeBytes(bytes)
        val uri = androidx.core.content.FileProvider.getUriForFile(this, "$packageName.share", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/jpeg"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, text)
            // 共有画面（プレビュー）と送り先のアプリの両方が画像を読めるように、ClipData にも入れて読み取りを許可する
            clipData = android.content.ClipData.newRawUri(null, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(send, "結果を共有").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
        Telemetry.log("share_open", null)
    }

    private fun handle(msg: JSONObject) {
        when (msg.optString("type")) {
            "ready" -> {
                webReady = true
                tutorialOpen = msg.optBoolean("tutorial", false)
                pushState()
                sendCloud()
                startAdsIfReady()
            }
            "tutorialDone" -> {
                tutorialOpen = false
                Telemetry.log("tutorial_complete")
                startAdsIfReady()
                updateBanner()
            }
            "screen" -> {
                val name = msg.optString("name")
                val prev = screen
                screen = name
                // 結果画面から次の練習へ進むとき、3回に1回だけ全画面広告
                if (prev == "result" && name != "result" && name != "menu") {
                    resultsLeft += 1
                    if (resultsLeft >= 3 && !store.owned && ads.showInterstitial()) {
                        resultsLeft = 0
                        // 全画面広告が指の操作に割り込むので、ハンドル・ペダルを放したことにする
                        sendToWeb("window.releaseTouchInputs && releaseTouchInputs()")
                    }
                }
                updateBanner()
            }
            "log" -> if (BuildConfig.DEBUG) Log.d("web", msg.optString("msg"))
            "haptic" -> vibrate(msg.optDouble("strong", 1.0) >= 0.8)
            "buy" -> store.buy(this)
            "restore" -> store.restore()
            "share" -> shareResult(msg.optString("image"), msg.optString("text"))
            "cloudSave" -> {
                // ゲームの進み具合を保存（Google のバックアップで、入れ直しや機種変更のあとに戻る）
                val data = msg.optJSONObject("data") ?: return
                val e = cloud.edit()
                for (k in data.keys()) if (k in cloudKeys) e.putString(k, data.optString(k))
                e.apply()
                BackupManager(this).dataChanged()
            }
            "event" -> {
                // ゲーム側の出来事（ステージ開始・結果など）を Analytics に記録
                val name = msg.optString("name")
                if (name.isNotEmpty()) Telemetry.log(name, msg.optJSONObject("params"))
            }
            "openURL" -> {
                // プライバシーポリシーなど、自分のサイトのページだけブラウザで開く
                val uri = Uri.parse(msg.optString("url"))
                if (uri.scheme == "https" && uri.host == "endomotoki.github.io") {
                    try { startActivity(Intent(Intent.ACTION_VIEW, uri)) } catch (e: Exception) {}
                }
            }
        }
    }

    /** 保存してある進み具合をゲームへ送る（ゲーム側で、端末の記録と合わせて進んでいる方を残す） */
    private fun sendCloud() {
        val data = JSONObject()
        for (k in cloudKeys) cloud.getString(k, null)?.let { data.put(k, it) }
        sendToWeb("window.cloudLoad && cloudLoad($data)")
    }

    private fun pushState() {
        if (!webReady) return
        val s = JSONObject().apply {
            put("owned", store.owned)
            put("price", store.price ?: "")
            put("busy", store.busy)
            put("message", store.message ?: "")
        }
        sendToWeb("window.appState && window.appState($s)")
    }

    /** ゲームの読み込みと初回の説明が終わったら、広告 SDK を始める */
    private fun startAdsIfReady() {
        if (!webReady || tutorialOpen || adsStarted) return
        adsStarted = true
        ads.start { if (!store.owned) ads.loadInterstitial(); updateBanner() }
    }

    /** バナー：メニューと結果画面の下だけ。運転中・説明中・購入済みは出さない */
    private fun updateBanner() {
        val show = adsStarted && !tutorialOpen && !store.owned && (screen == "menu" || screen == "result")
        ads.showBanner(show)
    }

    @Suppress("DEPRECATION")
    private fun vibrate(strong: Boolean) {
        // 衝突したら振動させる（車・壁は強め、縁石は軽め）
        val v: Vibrator? = if (Build.VERSION.SDK_INT >= 31) getSystemService(VibratorManager::class.java)?.defaultVibrator
                           else getSystemService(Vibrator::class.java)
        if (v == null || !v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= 29) v.vibrate(VibrationEffect.createPredefined(if (strong) VibrationEffect.EFFECT_HEAVY_CLICK else VibrationEffect.EFFECT_CLICK))
        else v.vibrate(if (strong) 60L else 25L)
    }
}
