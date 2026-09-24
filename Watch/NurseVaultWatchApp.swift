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

struct WatchHomeView: View {
    @Environment(Library.self) private var library

    var body: some View {
        NavigationStack {
            List {
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

    var body: some View {
        List(library.docs(in: section), id: \.self) { doc in
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
        .navigationTitle(section.name ?? "Documents")
        .navigationDestination(for: VaultDoc.self) { doc in
            WatchDocDetailView(doc: doc)
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
