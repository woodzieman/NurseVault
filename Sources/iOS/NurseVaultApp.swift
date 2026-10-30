import SwiftUI
import NurseVaultCore

@main
struct NurseVaultApp: App {
    @State private var library = Library()
    @State private var drugLibrary = DrugLibrary()
    @State private var merckLibrary = MerckTopicLibrary()
    @State private var dsmLibrary = DsmTopicLibrary()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(drugLibrary)
                .environment(merckLibrary)
                .environment(dsmLibrary)
                .onAppear {
                    // Ensure default sections exist and write the watch summary
                    // immediately so the watch app has data as soon as possible.
                    library.ensureDefaultSections()
                    library.writeWatchSummaryForced()
                    drugLibrary.loadIfNeeded()
                    merckLibrary.loadIfNeeded()
                    dsmLibrary.loadIfNeeded()
                }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 720)
        #endif
    }
}
