import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Safari Extension") {
                Text("Tideline reads and writes bookmarks through its Safari extension. If your bookmarks aren't syncing, make sure it's enabled:")
                    .foregroundStyle(.secondary)
                #if os(macOS)
                Text("Safari → Settings → Extensions → Tideline")
                #else
                Text("Settings → Apps → Safari → Extensions → Tideline")
                #endif
            }
        }
        .padding()
        .frame(minWidth: 380, minHeight: 160)
    }
}

#Preview {
    SettingsView()
}
