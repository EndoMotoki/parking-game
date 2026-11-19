import SwiftUI
import AVFoundation

@main
struct ParkingGameApp: App {
    @StateObject private var model: AppModel

    init() {
        // ゲームの音は、ほかのアプリで再生中の音楽と混ぜて鳴らす（音楽を止めない。消音スイッチにも従う）
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        Telemetry.start()   // AppModel より先に（購入などの記録に使うため）
        _model = StateObject(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
        }
    }
}
