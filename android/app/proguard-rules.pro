# ゲーム（JavaScript）から呼ぶメソッドを消さない
-keepclassmembers class com.endomotoki.parking.MainActivity$Bridge {
    @android.webkit.JavascriptInterface <methods>;
}
