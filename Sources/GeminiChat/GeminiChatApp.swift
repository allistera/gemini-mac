import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct GeminiChatApp: App {
    @StateObject private var viewModel = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if viewModel.hasAPIKey {
                    MainView()
                        .environmentObject(viewModel)
                } else {
                    APIKeyView()
                        .environmentObject(viewModel)
                }
            }
            .onAppear {
                #if os(macOS)
                // Ensure the app takes focus when launched via terminal (swift run)
                NSApp.activate(ignoringOtherApps: true)
                #endif
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }
    }
}
