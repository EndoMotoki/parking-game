import SwiftUI
import GoogleMobileAds

/// AdMob の広告ユニット ID
/// 開発中（Debug ビルド）は Google のテスト用 ID を使う。自分の端末で本番の広告を表示・タップすると、
/// 不正なトラフィックとみなされて AdMob のアカウントが止められることがあるため
enum AdUnit {
    #if DEBUG
    static let banner = "ca-app-pub-3940256099942544/2934735716"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    #else
    static let banner = "ca-app-pub-3350766982337275/4915398171"
    static let interstitial = "ca-app-pub-3350766982337275/9333155330"
    #endif
}

@MainActor
final class AdManager: NSObject, FullScreenContentDelegate {
    private var interstitial: InterstitialAd?
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        // 広告に音声の設定を変えさせない（アプリの .ambient のまま、音楽を止めない）
        MobileAds.shared.audioVideoManager.isAudioSessionApplicationManaged = true
        MobileAds.shared.start(completionHandler: nil)
    }

    func loadInterstitial() {
        InterstitialAd.load(with: AdUnit.interstitial, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                if let error { print("interstitial load failed:", error.localizedDescription) }
                self.interstitial = ad
                ad?.fullScreenContentDelegate = self
            }
        }
    }

    /// 読み込み済みなら全画面広告を出す。出せたら true
    func showInterstitial() -> Bool {
        guard let ad = interstitial, let root = UIApplication.shared.rootViewController else { return false }
        interstitial = nil
        ad.present(from: root)
        return true
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in self.loadInterstitial() }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.loadInterstitial() }
    }
}

/// 下に出すバナー広告
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdUnit.banner
        banner.rootViewController = UIApplication.shared.rootViewController
        banner.load(Request())
        return banner
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

extension UIApplication {
    var rootViewController: UIViewController? {
        let scene = connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var vc = scene?.windows.first(where: \.isKeyWindow)?.rootViewController ?? scene?.windows.first?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}
