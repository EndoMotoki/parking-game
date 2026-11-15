import SwiftUI

@main
struct ParkingGameApp: App {
    @StateObject private var model: AppModel

    init() {
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
