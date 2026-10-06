import SwiftUI
import NurseVaultCore

@main
struct NurseVaultApp: App {
    @State private var library = Library()
    @State private var drugLibrary = DrugLibrary()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(drugLibrary)
                .onAppear {
                    library.ensureDefaultSections()
                    drugLibrary.loadIfNeeded()
                }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 720)
        #endif
    }
}
