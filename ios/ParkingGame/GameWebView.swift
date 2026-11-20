import SwiftUI
import WebKit

/// アプリに同梱したゲーム（index.html）を表示する
struct GameWebView: UIViewRepresentable {
    @EnvironmentObject var model: AppModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(WeakHandler(context.coordinator), name: "app")
        // 同梱のゲームと決まった CDN しか読まないので、Safari のセーフブラウジング（詐欺サイトの確認）は使わない。
        // iPadOS 17 の古い iPad で、この確認の処理（SafariSafeBrowsing）の中でアプリが落ちることがあるため
        config.preferences.isFraudulentWebsiteWarningEnabled = false

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        // ページ自体の拡大縮小はしない（ゲーム内のズームは Web 側で扱う）
        web.scrollView.minimumZoomScale = 1
        web.scrollView.maximumZoomScale = 1
        web.scrollView.pinchGestureRecognizer?.isEnabled = false
        #if DEBUG
        if #available(iOS 16.4, *) { web.isInspectable = true }
        // スクリーンショット用：起動引数 -js "<コード>" を、ページを読み込んだあとに実行（場面を用意する）
        if let js = UserDefaults.standard.string(forKey: "js") {
            config.userContentController.addUserScript(WKUserScript(
                source: "setTimeout(() => { \(js) }, 2500);",
                injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        #endif

        let coordinator = context.coordinator
        model.sendToWeb = { [weak web] js in web?.evaluateJavaScript(js) }
        _ = coordinator

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: Bundle.main.bundleURL)
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let model: AppModel
        init(model: AppModel) { self.model = model }

        func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }
            Task { @MainActor in self.model.handle(body) }
        }
    }

    /// WKUserContentController が handler を強参照するので、循環参照を避ける
    final class WeakHandler: NSObject, WKScriptMessageHandler {
        weak var target: WKScriptMessageHandler?
        init(_ target: WKScriptMessageHandler) { self.target = target }
        func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
            target?.userContentController(ucc, didReceive: message)
        }
    }
}
