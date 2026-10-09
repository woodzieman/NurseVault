import SwiftUI
import NurseVaultCore

/// The watch's Drug Reference: the **full** bundled prescribing data, paged
/// ~25 rows at a time with a short preview per row. Selecting a drug reads
/// just that drug's text from the on-watch content blob (see
/// `WatchReference`), so the watch holds the whole reference without ever
/// loading it all into RAM.
struct WatchDrugReferenceView: View {
    @State private var reference = WatchReference(.drugs)
    @State private var searchText = ""
    @State private var query = ""
    @State private var visibleCount = 25

    private var all: [WatchReferenceEntry] {
        query.isEmpty ? reference.entries : reference.search(query)
    }

    var body: some View {
        WatchReferenceListView(
            reference: reference,
            placeholder: "Drug name, brand, or class",
            browseHint: "Browse or search \(reference.entries.count) drugs",
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

/// Shared paged list for a `WatchReference` dataset: search field, ~25 rows
/// (growable via "Show more"), title + preview per row.
struct WatchReferenceListView: View {
    let reference: WatchReference
    let placeholder: String
    let browseHint: String
    @Binding var searchText: String
    let all: [WatchReferenceEntry]
    @Binding var visibleCount: Int

    private static let pageSize = 25

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        List {
            Section {
                TextField(placeholder, text: $searchText)
                    .autocorrectionDisabled()
            }

            if reference.isMissing {
                Section {
                    Label(
                        "The reference data isn't available on this watch yet.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else if all.isEmpty {
                Section {
                    if isSearching {
                        Text("No matches for “\(searchText)”.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if reference.isLoading {
                        ProgressView()
                    } else {
                        Text(browseHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    ForEach(all.prefix(visibleCount)) { entry in
                        NavigationLink(value: entry) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.footnote)
                                if !entry.preview.isEmpty {
                                    Text(entry.preview)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    if all.count > visibleCount {
                        Button {
                            visibleCount += Self.pageSize
                        } label: {
                            Text("Show \(min(Self.pageSize, all.count - visibleCount)) more")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}

/// The full text of one reference entry: seek + read + inflate of that entry
/// only, rendered scrollable on the watch.
struct WatchReferenceDetailView: View {
    let reference: WatchReference
    let entry: WatchReferenceEntry

    @State private var text: String?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !entry.extra.isEmpty {
                    Text(entry.extra)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let text {
                    Text(Self.bodyText(for: text))
                        .font(.footnote)
                } else if isLoading {
                    ProgressView("Loading…")
                } else {
                    Text("This entry's text couldn't be loaded.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(entry.title)
        .task {
            text = await reference.text(for: entry)
            isLoading = false
        }
    }

    /// Drops the leading metadata header (`===` / `Source:` / `Retrieved:` /
    /// `Section:` lines) so the article starts at real content. Everything
    /// else — including the nursing quick-reference summary block — stays.
    private static func bodyText(for text: String) -> String {
        let headerPrefixes = ["===", "Section:", "Source:", "Retrieved:"]
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || headerPrefixes.contains(where: trimmed.hasPrefix) {
                index += 1
                continue
            }
            break
        }
        return lines.dropFirst(index).joined(separator: "\n")
    }
}
