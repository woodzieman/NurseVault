import SwiftUI
import NurseVaultCore

/// The watch's Drug Reference: a searchable, offline, at-a-glance lookup of
/// the bundled drug index. (The full prescribing text lives only in the
/// iPhone/Mac app.) Shown from the home screen as a top-level entry.
struct WatchDrugReferenceView: View {
    @State private var library = WatchDrugLibrary()
    @State private var searchText = ""
    @State private var query = ""

    private var results: [WatchDrugEntry] {
        library.search(query)
    }

    var body: some View {
        List {
            Section {
                TextField("Drug name or brand", text: $searchText)
                    .autocorrectionDisabled()
            }

            if library.isMissing {
                Section {
                    Label(
                        "The drug index isn't available on this watch yet.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else if query.isEmpty {
                Section {
                    Label(
                        "Search a drug or brand. \(library.entries.count) drugs loaded.",
                        systemImage: "pills"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else if results.isEmpty {
                Section {
                    Text("No drugs match “\(query)”.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(results.prefix(25)) { drug in
                    NavigationLink(value: drug) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(drug.name)
                                .font(.footnote)
                            if !drug.brands.isEmpty {
                                Text(drug.brands.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Drug Reference")
        .navigationDestination(for: WatchDrugEntry.self) { drug in
            WatchDrugDetailView(drug: drug)
        }
        .task { library.loadIfNeeded() }
        .onChange(of: searchText) { _, newValue in
            // Short debounce keeps the crown/typing responsive without
            // re-filtering on every intermediate keystroke.
            let text = newValue
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                if !Task.isCancelled && searchText == text {
                    query = text
                }
            }
        }
    }
}

/// A single drug's quick-reference summary, rendered for the watch's small
/// screen.
struct WatchDrugDetailView: View {
    let drug: WatchDrugEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Generic name + up to two brand names (kept short for a watch).
                if !drug.brands.isEmpty {
                    Text("Brands: \(drug.brands.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !drug.summary.isEmpty {
                    Text(drug.summary)
                        .font(.caption)
                }

                Text("Full prescribing information is in the Nurse Vault app on your iPhone or Mac.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(drug.name)
    }
}
