import SwiftUI
import NurseVaultCore

@main
struct NurseVaultWatchApp: App {
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(library)
                .onAppear {
                    library.reload()
                }
        }
    }
}

// MARK: - Home: the sections

/// A non-document destination for the watch home screen.
enum WatchHomeDestination: Hashable {
    case search
}

struct WatchHomeView: View {
    @Environment(Library.self) private var library

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(value: WatchHomeDestination.search) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                ForEach(library.sections, id: \.self) { section in
                    NavigationLink(value: section) {
                        Label(section.name ?? "Untitled", systemImage: section.icon ?? "folder")
                    }
                }
            }
            .navigationTitle("Nurse Vault")
            .navigationDestination(for: VaultSection.self) { section in
                WatchDocListView(section: section)
            }
            .navigationDestination(for: WatchHomeDestination.self) { destination in
                if destination == .search {
                    WatchSearchView()
                }
            }
            .overlay {
                if library.sections.isEmpty {
                    ContentUnavailableView(
                        "No Sections",
                        systemImage: "books.vertical",
                        description: Text("Add sections in the Nurse Vault app on your phone or Mac.")
                    )
                }
            }
        }
    }
}

// MARK: - Documents in a section

struct WatchDocListView: View {
    @Environment(Library.self) private var library
    let section: VaultSection

    @State private var searchText = ""

    private var visibleDocs: [VaultDoc] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return library.docs(in: section)
        }
        let matches = library.docs(matching: trimmed)
        return matches.filter { $0.section === section }
    }

    var body: some View {
        List {
            Section {
                TextField("Search \(section.name ?? "this section")", text: $searchText)
                    .autocorrectionDisabled()
            }
            Section {
                ForEach(visibleDocs, id: \.self) { doc in
                    NavigationLink(value: doc) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.title ?? "Untitled")
                            if let added = doc.addedDate {
                                Text(added, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(section.name ?? "Documents")
        .navigationDestination(for: VaultDoc.self) { doc in
            WatchDocDetailView(doc: doc)
        }
        .overlay {
            if visibleDocs.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "Empty" : "No Matches",
                    systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                    description: Text(
                        searchText.isEmpty
                            ? "Documents you add on your phone, iPad, or Mac appear here."
                            : "Nothing in this section matches your search."
                    )
                )
            }
        }
    }
}

// MARK: - Search across all sections

struct WatchSearchView: View {
    @Environment(Library.self) private var library

    @State private var searchText = ""

    private var visibleDocs: [VaultDoc] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return library.docs(matching: trimmed)
    }

    var body: some View {
        List {
            Section {
                TextField("Search all documents", text: $searchText)
                    .autocorrectionDisabled()
            }
            ForEach(visibleDocs, id: \.self) { doc in
                NavigationLink(value: doc) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.title ?? "Untitled")
                        if let section = doc.section {
                            Text(section.name ?? "No section")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationDestination(for: VaultDoc.self) { doc in
            WatchDocDetailView(doc: doc)
        }
        .overlay {
            if visibleDocs.isEmpty {
                ContentUnavailableView(
                    "No Matches",
                    systemImage: "magnifyingglass",
                    description: Text("Search by title, file name, notes, or the text inside PDFs and text files.")
                )
            }
        }
    }
}

// MARK: - Document detail

struct WatchDocDetailView: View {
    let doc: VaultDoc

    private var kind: DocKind {
        DocKind.kind(mimeType: doc.mimeType, fileName: doc.fileName, hasFile: doc.fileData != nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let data = doc.fileData {
                    switch kind {
                    case .pdf:
                        VaultPDFView(data: data)
                    case .image:
                        VaultImageView(data: data)
                    case .text:
                        Text(FileSupport.text(from: data) ?? "…")
                            .font(.caption)
                    case .other, .note:
                        Label("No preview for this file type", systemImage: "doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let note = doc.noteText, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                } else {
                    Label("Empty document", systemImage: "doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let note = doc.noteText, !note.isEmpty, doc.fileData != nil {
                    Divider()
                    Text("Notes")
                        .font(.caption.bold())
                    Text(note)
                        .font(.caption)
                }
            }
            .padding()
        }
    }
}
