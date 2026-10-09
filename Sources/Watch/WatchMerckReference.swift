import SwiftUI
import NurseVaultCore

/// The watch's Merck Manual: the **full** bundled articles, paged ~25 topics
/// at a time with a short preview per row. Selecting a topic reads just that
/// topic's text from the on-watch content blob (see `WatchReference`), so the
/// watch holds the whole manual without ever loading it all into RAM.
struct WatchMerckReferenceView: View {
    @State private var reference = WatchReference(.merck)
    @State private var searchText = ""
    @State private var query = ""
    @State private var visibleCount = 25

    private var all: [WatchReferenceEntry] {
        query.isEmpty ? reference.entries : reference.search(query)
    }

    var body: some View {
        WatchReferenceListView(
            reference: reference,
            placeholder: "Topic, specialty, or condition",
            browseHint: "Browse or search \(reference.entries.count) topics",
            searchText: $searchText,
            all: all,
            visibleCount: $visibleCount
        )
        .navigationTitle(reference.name.label)
        .navigationDestination(for: WatchReferenceEntry.self) { entry in
            WatchReferenceDetailView(reference: reference, entry: entry)
        }
        .task { reference.loadIfNeeded() }
        .onChange(of: searchText) { _, newValue in
            // Short debounce keeps the crown/typing responsive without
            // re-filtering on every intermediate keystroke.
            let text = newValue
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                if !Task.isCancelled && searchText == text {
                    query = text
                    visibleCount = 25
                }
            }
        }
    }
}
