package com.endomotoki.parking

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.crashlytics.FirebaseCrashlytics
import org.json.JSONObject

/**
 * Firebase（Analytics・Crashlytics）。iOS 版の Telemetry.swift にあたる
 * google-services.json がないビルドでは何もしない。Debug ビルドでは集計しない
 */
object Telemetry {
    private var analytics: FirebaseAnalytics? = null

    fun start(ctx: Context) {
        if (FirebaseApp.getApps(ctx).isEmpty()) return
        analytics = FirebaseAnalytics.getInstance(ctx).apply { setAnalyticsCollectionEnabled(!BuildConfig.DEBUG) }
        FirebaseCrashlytics.getInstance().isCrashlyticsCollectionEnabled = !BuildConfig.DEBUG
    }

    fun log(name: String, params: JSONObject? = null) {
        val b = Bundle()
        params?.keys()?.forEach { k ->
            when (val v = params.opt(k)) {
                is Int -> b.putLong(k, v.toLong())
                is Long -> b.putLong(k, v)
                is Double -> b.putDouble(k, v)
                is Boolean -> b.putLong(k, if (v) 1 else 0)
                null -> {}
                else -> b.putString(k, v.toString())
            }
        }
        if (BuildConfig.DEBUG) Log.d("telemetry", "$name $b")
        analytics?.logEvent(name, b)
    }
}
