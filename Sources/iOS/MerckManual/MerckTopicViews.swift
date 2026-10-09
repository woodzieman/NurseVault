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
                        NavigationLink(value: hit.entry) {
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
                                NavigationLink(value: entry) {
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
            .navigationDestination(for: MerckTopicEntry.self) { entry in
                MerckTopicDetailView(entry: entry)
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
        } else if !query.isEmpty && (contentHits.isEmpty && !isScanning) {
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
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

    // MARK: - Body text (skip the header block)
    private func bodyText(_ text: String) -> some View {
        let lines = text.split(whereSeparator: \.isNewline)

        // Body text starts from References section onward
        var bodyLines: [String.SubSequence] = []
        var inReferences = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("References") {
                inReferences = true
            }
            if inReferences {
                bodyLines.append(line)
            }
        }

        return Text(String(bodyLines.joined(separator: "\n")))
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
