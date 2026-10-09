import SwiftUI
import NurseVaultCore

struct WatchMerckReferenceView: View {
    @State private var library = WatchMerckLibrary()
    @State private var searchText = ""
    @State private var query = ""

    private var results: [WatchMerckEntry] {
        library.search(query)
    }

    var body: some View {
        List {
            Section {
                TextField("Topic search", text: $searchText)
                    .autocorrectionDisabled()
            }

            if library.isMissing {
                Section {
                    Label(
                        "The Merck index isn't available on this watch yet.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else if query.isEmpty {
                Section {
                    Label("Search topics by title or specialty. \(library.entries.count) topics loaded.", systemImage: "book")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if results.isEmpty {
                Section {
                    Text("No topics match “\(query)”.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(results.prefix(25)) { entry in
                    NavigationLink(value: entry) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.footnote)
                            Text(entry.specialty)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Merck Manual")
        .navigationDestination(for: WatchMerckEntry.self) { entry in
            WatchMerckDetailView(entry: entry)
        }
        .task { library.loadIfNeeded() }
        .onChange(of: searchText) { _, newValue in
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

struct WatchMerckDetailView: View {
    let entry: WatchMerckEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.specialty)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !entry.subspecialty.isEmpty {
                    Text(entry.subspecialty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(entry.summary)
                    .font(.caption)
                Text("Full article is available in the Nurse Vault app on your iPhone or Mac.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(entry.title)
    }
}
