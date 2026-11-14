import SwiftUI
import AppTrackingTransparency

/// ゲーム画面（Web）・広告・課金をつなぐ
@MainActor
final class AppModel: ObservableObject {
    let store = Store()
    let ads = AdManager()

    /// ゲームの今の画面（menu / play / result / demo）
    @Published private(set) var screen = "menu"
    /// 広告 SDK を始めたか（トラッキング許可を聞き終えてから）
    @Published private(set) var adsStarted = false
    /// 下のバナー広告を出すか
    var showBanner: Bool { adsStarted && !store.adFree && (screen == "menu" || screen == "result") }

    /// Web 側へ状態を送る関数（GameWebView が設定する）
    var sendToWeb: ((String) -> Void)?
    private var resultsLeft = 0
    private var started = false

    init() {
        store.onChange = { [weak self] in
            self?.objectWillChange.send()
            self?.pushState()
        }
    }

    /// 初回表示のあと：トラッキング許可を聞いてから広告 SDK を始める
    func start() {
        guard !started else { return }
        started = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                _ = await ATTrackingManager.requestTrackingAuthorization()
            }
            ads.start()
            adsStarted = true
            if !store.adFree { ads.loadInterstitial() }
        }
    }

    // MARK: Web からのメッセージ
    func handle(_ msg: [String: Any]) {
        switch msg["type"] as? String {
        case "ready":
            pushState()
        case "screen":
            let name = msg["name"] as? String ?? ""
            let prev = screen
            screen = name
            // 結果画面から次の練習へ進むとき、3回に1回だけ全画面広告
            #if DEBUG
            // 動作確認用：起動引数 -adTestOnStart で、スタートのたびに全画面広告
            if ProcessInfo.processInfo.arguments.contains("-adTestOnStart"), prev == "menu", name == "play", !store.adFree {
                _ = ads.showInterstitial()
            }
            #endif
            if prev == "result" && name != "result" && name != "menu" {
                resultsLeft += 1
                if resultsLeft >= 3, !store.adFree, ads.showInterstitial() { resultsLeft = 0 }
            }
        case "buy":
            Task { await store.buy() }
        case "restore":
            Task { await store.restore() }
        default:
            break
        }
    }

    func pushState() {
        let s: [String: Any] = [
            "adFree": store.adFree,
            "price": store.price ?? "",
            "busy": store.busy,
            "message": store.message ?? "",
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: s),
              let json = String(data: data, encoding: .utf8) else { return }
        sendToWeb?("window.appState && window.appState(\(json))")
    }
}
