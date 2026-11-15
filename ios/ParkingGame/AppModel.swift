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

    /// iCloud（キー値ストレージ）に保存するゲームのデータ。中身は Web 側の localStorage と同じ文字列
    private let cloud = NSUbiquitousKeyValueStore.default
    private static let cloudKeys: Set<String> = ["stageUnlocked", "hardUnlocked", "bestScores", "badges", "parkingSettings", "tutorialSeen"]
    #if DEBUG
    private let cloudOff = UserDefaults.standard.bool(forKey: "screenshots")   // スクリーンショット用の場面は保存しない
    #else
    private let cloudOff = false
    #endif

    init() {
        store.onChange = { [weak self] in
            self?.objectWillChange.send()
            self?.pushState()
        }
        // ほかの端末で進んだら、ゲームに知らせて合わせる
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.sendCloud() }
        }
        cloud.synchronize()
    }

    /// iCloud に保存してあるデータをゲームへ送る（ゲーム側で、端末の記録と合わせて進んでいる方を残す）
    private func sendCloud() {
        var data: [String: String] = [:]
        if !cloudOff { for k in Self.cloudKeys { if let v = cloud.string(forKey: k) { data[k] = v } } }
        guard let json = try? JSONSerialization.data(withJSONObject: data), let str = String(data: json, encoding: .utf8) else { return }
        sendToWeb?("window.cloudLoad && cloudLoad(\(str))")
    }

    /// アプリが前面に出たとき
    func start() {
        appActive = true
        startAdsIfReady()
    }

    /// 前面に出ていて、ゲームの読み込みと初回の説明が終わったら、トラッキング許可を聞いてから広告 SDK を始める
    private func startAdsIfReady() {
        guard appActive, webReady, !tutorialOpen, !started else { return }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "screenshots") { return }   // スクリーンショット用：許可の確認も広告も出さない
        #endif
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
            sendCloud()
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
            Task { await store.buy() }
        case "cloudSave":
            // ゲームの進み具合を iCloud に保存
            guard !cloudOff, let data = msg["data"] as? [String: String] else { break }
            for (k, v) in data where Self.cloudKeys.contains(k) { cloud.set(v, forKey: k) }
            cloud.synchronize()
        case "restore":
            Task { await store.restore() }
        case "openURL":
            // プライバシーポリシーなど、自分のサイトのページだけ Safari で開く
            if let str = msg["url"] as? String, let url = URL(string: str), url.scheme == "https", url.host == "endomotoki.github.io" {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }

    func pushState() {
        let s: [String: Any] = [
            "owned": store.owned,
            "price": store.price ?? "",
            "busy": store.busy,
            "message": store.message ?? "",
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: s),
              let json = String(data: data, encoding: .utf8) else { return }
        sendToWeb?("window.appState && window.appState(\(json))")
    }
}
