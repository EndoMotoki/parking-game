import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            GameWebView()
                .ignoresSafeArea(edges: model.showBanner ? [.top, .horizontal] : .all)
            if model.showBanner {
                BannerAdView()
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
