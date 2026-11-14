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
    var showBanner: Bool { !tutorialOpen && !store.adFree && (screen == "menu" || screen == "result") }

    /// Web 側へ状態を送る関数（GameWebView が設定する）
    var sendToWeb: ((String) -> Void)?
    private var resultsLeft = 0
    private var started = false
    private var appActive = false
    private var webReady = false
    /// 初回の説明（チュートリアル）を表示中か。表示中はトラッキング許可を聞かず、バナーの場所も空けない
    @Published private var tutorialOpen = true

    init() {
        store.onChange = { [weak self] in
            self?.objectWillChange.send()
            self?.pushState()
        }
    }

    /// アプリが前面に出たとき
    func start() {
        appActive = true
        startAdsIfReady()
    }

    /// 前面に出ていて、ゲームの読み込みと初回の説明が終わったら、トラッキング許可を聞いてから広告 SDK を始める
    private func startAdsIfReady() {
        guard appActive, webReady, !tutorialOpen, !started else { return }
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
            webReady = true
            tutorialOpen = msg["tutorial"] as? Bool ?? false
            pushState()
            startAdsIfReady()
        case "tutorialDone":
            tutorialOpen = false
            startAdsIfReady()
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
                if resultsLeft >= 3, !store.adFree, ads.showInterstitial() {
                    resultsLeft = 0
                    // 全画面広告が指の操作に割り込むので、ハンドル・ペダルを放したことにする
                    sendToWeb?("window.releaseTouchInputs && releaseTouchInputs()")
                }
            }
        case "log":
            #if DEBUG
            print("[web]", msg["msg"] as? String ?? "")
            #endif
        case "haptic":
            // 衝突したら iPhone を振動させる（車・壁は強め、縁石は軽め）
            let strong = (msg["strong"] as? Double) ?? 1
            if strong >= 0.8 {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        case "buy":
            if let item = Store.Item(webName: msg["product"] as? String) { Task { await store.buy(item) } }
        case "restore":
            Task { await store.restore() }
        default:
            break
        }
    }

    func pushState() {
        let s: [String: Any] = [
            "adFree": store.adFree,
            "price": store.prices[.noAds] ?? "",
            "hardOwned": store.hardOwned,
            "hardPrice": store.prices[.hard] ?? "",
            "busy": store.busy,
            "message": store.message ?? "",
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: s),
              let json = String(data: data, encoding: .utf8) else { return }
        sendToWeb?("window.appState && window.appState(\(json))")
    }
}
