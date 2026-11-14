import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            GameWebView()
                .ignoresSafeArea(edges: model.showBanner ? [.top, .horizontal] : .all)
            if model.showBanner {
                // 広告の準備ができる前から場所だけ空けておく（あとからバナーが出て画面がずれ、ボタンを押し間違えないように）
                Group {
                    if model.adsStarted { BannerAdView() } else { Color.black }
                }
                .frame(width: 320, height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.black)
            }
        }
        .background(Color.black.ignoresSafeArea())
        // トラッキング許可のダイアログは、アプリが前面に出てからでないと表示されない
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.start() } }
        .onAppear { if scenePhase == .active { model.start() } }
    }
}
