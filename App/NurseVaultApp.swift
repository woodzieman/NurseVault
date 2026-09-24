import SwiftUI
import NurseVaultCore

@main
struct NurseVaultApp: App {
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .onAppear {
                    library.ensureDefaultSections()
                }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 720)
        #endif
    }
}
