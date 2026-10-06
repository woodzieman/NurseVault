import SwiftUI

/// The "Drug Reference" column: a searchable list of the bundled drugs,
/// drilling into the full drug information. Read-only by design — the
/// reference ships with the app and is not part of the editable vault.
struct DrugReferenceView: View {
    @Environment(DrugLibrary.self) private var drugs

    @State private var searchText = ""
    @State private var contentHits: [DrugSearchHit] = []
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleHits) { hit in
                    NavigationLink(value: hit.entry) {
                        DrugRow(entry: hit.entry, snippet: hit.snippet)
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
            }
            .overlay { emptyState }
            .searchable(text: $searchText, prompt: "Name, brand, or content")
            .navigationTitle("Drug Reference")
            .navigationDestination(for: DrugEntry.self) { entry in
                DrugDetailView(entry: entry)
            }
            .task(id: searchText) {
                await runContentSearch()
            }
        }
    }

    // MARK: - Search

    /// The rows to show: everything when the query is empty; otherwise
    /// the name hits plus the (debounced, background) content hits,
    /// deduplicated by drug.
    private var visibleHits: [DrugSearchHit] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return drugs.entries.map { DrugSearchHit(entry: $0) }
        }
        var best: [String: DrugSearchHit] = [:]
        for hit in contentHits { best[hit.id] = hit }
        for hit in drugs.nameHits(for: query) {
            if best[hit.id] == nil { best[hit.id] = hit }
        }
        return best.values.sorted {
            $0.entry.drugName.localizedCaseInsensitiveCompare($1.entry.drugName) == .orderedAscending
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
        // Retyping cancels this task (via `.task(id:)`), so only a paused
        // query pays for a full scan of the bundled files.
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }
        let hits = await drugs.contentHits(for: query)
        guard !Task.isCancelled else { return }
        contentHits = hits
        isScanning = false
    }

    // MARK: - Empty states

    @ViewBuilder
    private var emptyState: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if drugs.isMissing {
            ContentUnavailableView(
                "Drug Reference Unavailable",
                systemImage: "cross.case",
                description: Text("The bundled drug information wasn't found in this app.")
            )
        } else if query.isEmpty, drugs.isLoading, drugs.entries.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading drug reference…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else if query.isEmpty {
            ContentUnavailableView(
                "No Drugs",
                systemImage: "pills",
                description: Text("The bundled reference is empty.")
            )
        } else if !isScanning {
            ContentUnavailableView(
                "No Matches",
                systemImage: "magnifyingglass",
                description: Text("Nothing in the reference matches “\(query)”.")
            )
        }
    }
}

// MARK: - Rows

struct DrugRow: View {
    let entry: DrugEntry
    let snippet: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "pills")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.drugName)
                    .lineLimit(2)
                if let snippet {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if !entry.brandNames.isEmpty {
                    Text(brandSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var brandSummary: String {
        let shown = entry.brandNames.prefix(3).joined(separator: ", ")
        let extra = entry.brandNames.count > 3 ? " +\(entry.brandNames.count - 3) more" : ""
        return shown + extra
    }
}

// MARK: - Detail

struct DrugDetailView: View {
    @Environment(DrugLibrary.self) private var drugs
    let entry: DrugEntry

    @State private var content: String?
    @State private var didLoad = false

    var body: some View {
        ScrollView {
            if let content {
                Text(content)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if !entry.hasInfo {
                ContentUnavailableView(
                    "No Information",
                    systemImage: "doc.questionmark",
                    description: Text("This drug doesn't have an information file.")
                )
                .padding()
            } else if !didLoad {
                ProgressView("Loading…")
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(entry.drugName)
        .toolbar {
            if let content {
                ShareLink(item: content) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .task {
            guard !didLoad else { return }
            content = await drugs.content(for: entry)
            didLoad = true
        }
    }
}
