import Foundation
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

/// Firebase（利用状況の分析 Analytics と、クラッシュの報告 Crashlytics）
/// 設定ファイル GoogleService-Info.plist（公開リポジトリには入れない）があるときだけ動く
enum Telemetry {
    private(set) static var enabled = false

    static func start() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        FirebaseApp.configure()
        enabled = true
        #if DEBUG
        // 開発中の操作は集計に入れない（起動引数 -FIRDebugEnabled のときだけ送る）
        let debugSend = ProcessInfo.processInfo.arguments.contains("-FIRDebugEnabled")
        Analytics.setAnalyticsCollectionEnabled(debugSend)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #endif
    }

    /// ゲームの出来事を記録する（名前は英小文字と _ 、値は文字列か数）
    static func log(_ name: String, _ params: [String: Any] = [:]) {
        guard enabled else { return }
        var clean: [String: Any] = [:]
        for (k, v) in params {
            if let s = v as? String { clean[k] = String(s.prefix(100)) }
            else if let n = v as? NSNumber { clean[k] = n }
        }
        Analytics.logEvent(String(name.prefix(40)), parameters: clean)
        #if DEBUG
        print("[telemetry]", name, clean)
        #endif
    }
}
