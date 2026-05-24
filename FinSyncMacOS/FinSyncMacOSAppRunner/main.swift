import SwiftUI
#if SWIFT_PACKAGE
import FinSyncCore
#endif

@main
struct FinSyncMacOSAppRunner: App {
    var body: some Scene {
        WindowGroup("FinSync") {
            FinSyncMacOSRootView()
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowStyle(.titleBar)
    }
}
