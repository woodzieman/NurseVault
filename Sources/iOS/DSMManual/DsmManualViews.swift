import SwiftUI

// MARK: - DSM-5-TR Nursing Reference View (main entry)
/// The "DSM-5-TR" column: browsable by specialty or searchable.
struct DsmManualView: View {
    @Environment(DsmTopicLibrary.self) private var topics

    @State private var searchText = ""
    @State private var contentHits: [DsmTopicSearchHit] = []
    @State private var isScanning = false
    @State private var selectedSpecialty: String? = nil

    private var visibleHits: [DsmTopicSearchHit] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var best: [String: DsmTopicSearchHit] = [:]
        for hit in contentHits { best[hit.id] = hit }
        for hit in topics.nameHits(for: query) {
            if best[hit.id] == nil { best[hit.id] = hit }
        }
        return best.values.sorted {
            $0.entry.specialty.localizedCaseInsensitiveCompare($1.entry.specialty) == .orderedAscending
                || ($0.entry.specialty == $1.entry.specialty &&
                    $0.entry.title.localizedCaseInsensitiveCompare($1.entry.title) == .orderedAscending)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    ForEach(visibleHits) { hit in
                        NavigationLink {
                            DsmTopicDetailView(entry: hit.entry)
                        } label: {
                            DsmTopicRow(entry: hit.entry, snippet: hit.snippet)
                        }
                    }
                    if isScanning {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Searching content…")
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(topics.entriesBySpecialty().keys.sorted {
                        $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
                    }, id: \.self) { specialty in
                        let specialtyEntries = topics.entriesBySpecialty()[specialty, default: []]
                        Section(specialty) {
                            ForEach(specialtyEntries) { entry in
                                NavigationLink {
                                    DsmTopicDetailView(entry: entry)
                                } label: {
                                    DsmTopicRow(entry: entry)
                                }
                            }
                        }
                    }
                }
            }
            .overlay { emptyState }
            .searchable(text: $searchText, prompt: "Topic, code, or content")
            .navigationTitle("DSM-5-TR")
            .task(id: searchText) {
                await runContentSearch()
            }
        }
    }

    // MARK: - Search

    private func runContentSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            contentHits = []
            isScanning = false
            return
        }
        isScanning = true
        contentHits = await topics.contentHits(for: query)
        isScanning = false
    }

    // MARK: - Empty states

    @ViewBuilder
    private var emptyState: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if topics.isMissing {
            ContentUnavailableView(
                "DSM-5-TR Reference Unavailable",
                systemImage: "book.pages",
                description: Text("The bundled DSM-5-TR reference wasn't found in this app.")
            )
        } else if query.isEmpty, topics.isLoading {
            ContentUnavailableView(
                "Loading Reference",
                systemImage: "book.pages",
                description: Text("Building the DSM-5-TR index…")
            )
        } else if !query.isEmpty && visibleHits.isEmpty && !isScanning {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("Try a different search term or browse specialties below.")
            )
        }
    }
}

// MARK: - Topic Row
struct DsmTopicRow: View {
    let entry: DsmTopicEntry
    var snippet: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.displayName)
                .font(.subheadline)
                .lineLimit(2)

            if !entry.specialty.isEmpty {
                Text(entry.specialty)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let snippet {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Topic Detail
struct DsmTopicDetailView: View {
    let entry: DsmTopicEntry
    @Environment(DsmTopicLibrary.self) private var topics
    @Environment(\.dismiss) private var dismiss

    @State private var fullText: String?
    @State private var isLoading = true

    @State private var cachedBodyString: String? = nil

    /// Leading lines that are file metadata, not article content: the
    /// `===` title, `ICD-10-CM:` code (already shown in the header), and the
    /// `DSM-5-TR CONTENT:` generator label (plus the generic Merck-style
    /// header lines, for safety).
    private static let headerPrefixes = ["===", "ICD-10-CM:", "DSM-5-TR CONTENT:", "Section:", "Source:", "Retrieved:"]

    private func ensureCachedBodyString() {
        guard let text = fullText else { cachedBodyString = nil; return }
        if cachedBodyString == nil || (cachedBodyString?.count ?? 0) != text.count - headerLength(text) {
            let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            var bodyLines: [String] = []
            var pastHeader = false
            for line in lines {
                if !pastHeader {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    let isHeader = trimmed.isEmpty || Self.headerPrefixes.contains(where: { trimmed.hasPrefix($0) })
                    if isHeader { continue }
                    pastHeader = true
                }
                bodyLines.append(String(line))
            }
            cachedBodyString = bodyLines.joined(separator: "\n")
        }
    }

    private func headerLength(_ text: String) -> Int {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var count = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isHeader = trimmed.isEmpty || Self.headerPrefixes.contains(where: { trimmed.hasPrefix($0) })
            if !isHeader { break }
            count += line.count + 1
        }
        return count
    }

    var body: some View {
        ScrollView {
            if let text = fullText {
                VStack(alignment: .leading, spacing: 16) {
                    headerView(text)

                    Divider()

                    bodyText(text)
                }
                .padding()
            } else if isLoading {
                ContentUnavailableView(
                    "Loading",
                    systemImage: "book.pages",
                    description: Text("Loading topic content…")
                )
            }
        }
        .navigationTitle(entry.displayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: entry) {
            await loadContent()
        }
        .onChange(of: fullText) { _, _ in
            ensureCachedBodyString()
        }
    }

    private func loadContent() async {
        fullText = await topics.fullText(for: entry)
        isLoading = false
    }

    private func bodyText(_ text: String) -> some View {
        // Use the cached body (metadata header stripped), falling back to the
        // raw text if the cache hasn't been computed yet.
        let bodyString = cachedBodyString ?? text
        return Text(bodyString)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }

    // MARK: - Header with extracted info
    @ViewBuilder
    private func headerView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let title = text
                .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .map(String.init)
                .first { $0.trimmingCharacters(in: .whitespaces).hasPrefix("===") }
            if let title, !title.trimmingCharacters(in: .whitespaces).isEmpty {
                Button {
                    dismiss()
                } label: {
                    Text(title.trimmingCharacters(in: .whitespaces))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }

            if !entry.code.isEmpty {
                Text("ICD-10-CM: \(entry.code)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
