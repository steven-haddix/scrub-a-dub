import SwiftUI

@main
struct ScrubadubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settings = SettingsStore.shared

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(settings)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ClipboardWatcher.shared.start()
    }
}
