package com.endomotoki.parking

import android.app.Activity
import android.view.View
import android.widget.FrameLayout
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback

/** AdMob の広告（バナーと全画面広告）。iOS 版の AdManager.swift にあたる。広告ユニット ID は app/build.gradle.kts */
class Ads(private val activity: Activity, private val box: FrameLayout) {
    private var started = false
    private var banner: AdView? = null
    private var wantBanner = false
    private var interstitial: InterstitialAd? = null
    private var loadingInterstitial = false

    fun start(then: () -> Unit) {
        if (started) { then(); return }
        started = true
        MobileAds.initialize(activity) { activity.runOnUiThread(then) }
    }

    /** 画面の幅に合わせたバナー（アダプティブ バナー） */
    private fun makeBanner() {
        val dm = activity.resources.displayMetrics
        val widthDp = ((box.width.takeIf { it > 0 } ?: dm.widthPixels) / dm.density).toInt()
        banner = AdView(activity).apply {
            adUnitId = BuildConfig.AD_BANNER
            setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp))
            adListener = object : AdListener() {
                override fun onAdFailedToLoad(e: LoadAdError) { box.visibility = View.GONE }
                override fun onAdLoaded() { if (wantBanner) box.visibility = View.VISIBLE }
            }
        }
        box.removeAllViews()
        box.addView(banner, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT))
        banner?.loadAd(AdRequest.Builder().build())
    }

    fun showBanner(show: Boolean) {
        wantBanner = show && started
        if (!wantBanner) { box.visibility = View.GONE; return }
        if (banner == null) makeBanner() else box.visibility = View.VISIBLE
    }

    fun reloadBanner() {
        if (banner == null) return
        banner?.destroy(); banner = null
        if (wantBanner) box.post { makeBanner() }
    }

    fun loadInterstitial() {
        if (!started || interstitial != null || loadingInterstitial) return
        loadingInterstitial = true
        InterstitialAd.load(activity, BuildConfig.AD_INTERSTITIAL, AdRequest.Builder().build(), object : InterstitialAdLoadCallback() {
            override fun onAdLoaded(ad: InterstitialAd) { loadingInterstitial = false; interstitial = ad }
            override fun onAdFailedToLoad(e: LoadAdError) { loadingInterstitial = false }
        })
    }

    /** 全画面広告を出せたら true。閉じたら次の分を読み込んでおく */
    fun showInterstitial(): Boolean {
        val ad = interstitial ?: run { loadInterstitial(); return false }
        interstitial = null
        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() { loadInterstitial() }
            override fun onAdFailedToShowFullScreenContent(e: com.google.android.gms.ads.AdError) { loadInterstitial() }
        }
        ad.show(activity)
        return true
    }

    fun destroy() { banner?.destroy() }
}
