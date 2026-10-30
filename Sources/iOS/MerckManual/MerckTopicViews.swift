import SwiftUI

// MARK: - Merck Manual Reference View (main entry)
/// The "Merck Manual" column: browsable by specialty or searchable.
struct MerckManualView: View {
    @Environment(MerckTopicLibrary.self) private var topics

    @State private var searchText = ""
    @State private var contentHits: [MerckTopicSearchHit] = []
    @State private var isScanning = false
    @State private var selectedSpecialty: String? = nil

    var body: some View {
        NavigationStack {
            List {
                // When searching, show results. Otherwise show specialty browser.
                if !searchText.isEmpty {
                    ForEach(visibleHits) { hit in
                        NavigationLink {
                            MerckTopicDetailView(entry: hit.entry)
                        } label: {
                            MerckTopicRow(entry: hit.entry, snippet: hit.snippet)
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
                    // Hierarchical specialty browser
                    ForEach(topics.entriesBySpecialty().keys.sorted {
                        $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
                    }, id: \.self) { specialty in
                        let specialtyEntries = topics.entriesBySpecialty()[specialty, default: []]
                        Section(specialty) {
                            ForEach(specialtyEntries) { entry in
                                NavigationLink {
                                    MerckTopicDetailView(entry: entry)
                                } label: {
                                    MerckTopicRow(entry: entry)
                                }
                            }
                        }
                    }
                }
            }
            .overlay { emptyState }
            .searchable(text: $searchText, prompt: "Topic, specialty, or content")
            .navigationTitle("Merck Manual")
            .task(id: searchText) {
                await runContentSearch()
            }
        }
    }

    // MARK: - Search

    private var visibleHits: [MerckTopicSearchHit] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var best: [String: MerckTopicSearchHit] = [:]
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

    private func runContentSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            contentHits = []
            isScanning = false
            return
        }
        isScanning = true
        contentHits = []
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }
        let hits = await topics.contentHits(for: query)
        guard !Task.isCancelled else { return }
        contentHits = hits
        isScanning = false
    }

    // MARK: - Empty states

    @ViewBuilder
    private var emptyState: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if topics.isMissing {
            ContentUnavailableView(
                "Merck Manual Unavailable",
                systemImage: "book.pages",
                description: Text("The bundled medical reference wasn't found in this app.")
            )
        } else if query.isEmpty, topics.isLoading {
            ContentUnavailableView(
                "Loading Reference",
                systemImage: "book.pages",
                description: Text("Building the medical topics index…")
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
struct MerckTopicRow: View {
    let entry: MerckTopicEntry
    let snippet: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.displayName)
                .font(.subheadline)
                .lineLimit(2)

            if !entry.subspecialty.isEmpty {
                Text(entry.specialty)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let snippet {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 2)
    }

    init(entry: MerckTopicEntry, snippet: String? = nil) {
        self.entry = entry
        self.snippet = snippet
    }
}

// MARK: - Topic Detail View
struct MerckTopicDetailView: View {
    let entry: MerckTopicEntry
    @Environment(MerckTopicLibrary.self) private var topics

    @State private var fullText: String?
    @State private var isLoading = true
    
    /// Cached processed body text string (split and joined once per fullText change).
    @State private var cachedBodyString: String? = nil
    
    /// Recomputes the body string when fullText changes.
    private func ensureCachedBodyString() {
        guard let text = fullText else { cachedBodyString = nil; return }
        if cachedBodyString == nil || (cachedBodyString?.count ?? 0) != text.count - headerLength(text) {
            // Recompute: extract body lines and join them
            let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            var bodyLines: [String] = []
            var pastHeader = false
            for line in lines {
                if !pastHeader {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    let isHeader = trimmed.hasPrefix("===")
                        || trimmed.hasPrefix("Section:")
                        || trimmed.hasPrefix("Source:")
                        || trimmed.hasPrefix("Retrieved:")
                        || trimmed.isEmpty
                    if isHeader { continue }
                    pastHeader = true
                }
                bodyLines.append(String(line))
            }
            cachedBodyString = bodyLines.joined(separator: "\n")
        }
    }
    
    /// Estimates the header length for cache invalidation.
    private func headerLength(_ text: String) -> Int {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var count = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.hasPrefix("===") && !trimmed.hasPrefix("Section:")
                && !trimmed.hasPrefix("Source:") && !trimmed.hasPrefix("Retrieved:")
                && !trimmed.isEmpty {
                break
            }
            count += line.count + 1 // +1 for newline
        }
        return count
    }

    var body: some View {
        ScrollView {
            if let text = fullText {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    headerView(text)

                    Divider()

                    // Body text
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
        .navigationTitle(entry.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: entry) {
            await loadContent()
        }
        .onChange(of: fullText) { _ in
            ensureCachedBodyString()
        }
    }

    // MARK: - Header with extracted info
    @ViewBuilder
    private func headerView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Topic title from file header
            let title = topics.topicTitle(from: text)
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
            }

            // Section path
            let section = topics.topicSection(from: text)
            if !section.isEmpty && section != "Specialty: \(entry.specialty)" {
                Text(section)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }

            // Specialty + subspecialty badges
            HStack(spacing: 8) {
                BadgeView(label: entry.specialty, color: .blue)
                if !entry.subspecialty.isEmpty {
                    BadgeView(label: entry.subspecialty, color: .gray)
                }
            }
        }
    }

    // MARK: - Body text (the full article, minus the metadata header)
    private func bodyText(_ text: String) -> some View {
        // Use cached processed string to avoid re-splitting on every render
        let bodyString = cachedBodyString ?? text
        return Text(bodyString)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }

    // MARK: - Loading
    private func loadContent() async {
        fullText = await topics.fullText(for: entry)
        isLoading = false
    }
}

// MARK: - Small badge for specialty/subspecialty
struct BadgeView: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15),
                        in: Capsule())
    }
}
