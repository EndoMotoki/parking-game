package com.endomotoki.parking

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams

/**
 * 買い切りの課金アイテム（Google Play Billing）。iOS 版の Store.swift にあたる
 * 1回の購入で「広告を削除」と「ハードステージの解放」の両方
 */
class Store(private val activity: Activity, private val onChange: () -> Unit) : PurchasesUpdatedListener {
    companion object {
        const val PRODUCT_ID = "com.endomotoki.parking.premium"
        private const val SAVED_KEY = "premiumOwned"
    }

    private val prefs = activity.getSharedPreferences("store", Context.MODE_PRIVATE)
    private val main = Handler(Looper.getMainLooper())

    var owned: Boolean = prefs.getBoolean(SAVED_KEY, false); private set
    var price: String? = null; private set
    var busy = false; private set
    var message: String? = null; private set

    /** エミュレーターで Google Play なしに流れを確かめるための疑似ストア（Debug ビルドで、起動時に mockStore を渡したときだけ） */
    private val mock = BuildConfig.DEBUG && activity.intent.getBooleanExtra("mockStore", false)

    private var product: ProductDetails? = null
    private val client: BillingClient = BillingClient.newBuilder(activity)
        .setListener(this)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .build()

    init {
        if (mock) price = "¥360" else connect()
    }

    private fun changed() {
        prefs.edit().putBoolean(SAVED_KEY, owned).apply()
        main.post(onChange)
    }

    private var connecting = false
    private val waiting = mutableListOf<() -> Unit>()

    /** Google Play につなぐ（つながったら then を呼ぶ。つなげなかったときも呼ぶ） */
    private fun connect(then: (() -> Unit)? = null) {
        if (client.isReady) { then?.invoke(); return }
        then?.let { waiting += it }
        if (connecting) return
        connecting = true
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                main.post {
                    connecting = false
                    if (result.responseCode == BillingClient.BillingResponseCode.OK) { loadProduct(); refresh() }
                    else Log.w("store", "billing setup failed: ${result.debugMessage}")
                    val list = waiting.toList(); waiting.clear(); list.forEach { it() }
                }
            }
            override fun onBillingServiceDisconnected() { main.post { connecting = false } }   // 次に使うときにつなぎ直す
        })
    }

    private fun loadProduct(then: (() -> Unit)? = null) {
        val params = QueryProductDetailsParams.newBuilder().setProductList(listOf(
            QueryProductDetailsParams.Product.newBuilder().setProductId(PRODUCT_ID).setProductType(BillingClient.ProductType.INAPP).build()
        )).build()
        client.queryProductDetailsAsync(params) { _, result ->
            product = result.productDetailsList.firstOrNull()
            price = product?.oneTimePurchaseOfferDetails?.formattedPrice
            changed()
            then?.let { main.post(it) }
        }
    }

    /** 購入済みかどうかを Google Play の記録から確かめる */
    fun refresh(then: (() -> Unit)? = null) {
        if (mock) { then?.invoke(); return }
        if (!client.isReady) { if (then != null) connect { if (client.isReady) refresh(then) else then() } else connect(); return }
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                owned = purchases.any { PRODUCT_ID in it.products && it.purchaseState == Purchase.PurchaseState.PURCHASED }
                purchases.forEach { acknowledge(it) }
                changed()
            }
            then?.let { main.post(it) }
        }
    }

    fun buy(activity: Activity) {
        if (busy || owned) return
        message = null
        if (mock) {
            busy = true; changed()
            main.postDelayed({ busy = false; owned = true; message = "購入しました（テスト）"; changed() }, 600)
            return
        }
        busy = true; changed()
        connect {
            val launch = {
                val p = product
                if (p == null) {
                    busy = false; message = "Google Play に接続できませんでした"; changed()
                } else {
                    val flow = BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(
                        BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(p).build()
                    )).build()
                    val r = client.launchBillingFlow(activity, flow)
                    if (r.responseCode != BillingClient.BillingResponseCode.OK) { busy = false; message = "購入できませんでした"; changed() }
                }
            }
            if (product == null && client.isReady) loadProduct(launch) else main.post(launch)
        }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        busy = false
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> purchases?.forEach { p ->
                if (PRODUCT_ID !in p.products) return@forEach
                when (p.purchaseState) {
                    Purchase.PurchaseState.PURCHASED -> {
                        acknowledge(p)
                        owned = true
                        message = "購入ありがとうございます。広告を削除し、ハードステージを解放しました"
                        Telemetry.log("premium_purchased")
                    }
                    Purchase.PurchaseState.PENDING -> message = "購入の承認待ちです"
                    else -> {}
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {}
            BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> { refresh(); message = "購入を復元しました" }
            else -> message = "購入できませんでした"
        }
        changed()
    }

    /** 購入を Google Play に確定させる（3日以内に確定しないと自動で返金される） */
    private fun acknowledge(p: Purchase) {
        if (p.purchaseState != Purchase.PurchaseState.PURCHASED || p.isAcknowledged) return
        client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.purchaseToken).build()) {}
    }

    fun restore() {
        if (busy) return
        message = null
        busy = true; changed()
        val done = {
            busy = false
            message = if (owned) "購入を復元しました" else "復元できる購入はありませんでした"
            changed()
        }
        if (mock) main.postDelayed(done, 400) else connect { refresh(done) }
    }

    fun end() { if (client.isReady) client.endConnection() }
}
