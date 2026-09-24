import SwiftUI
import UniformTypeIdentifiers
import NurseVaultCore

struct DocListView: View {
    @Environment(Library.self) private var library
    let section: VaultSection?

    @State private var importKind: ImportKind?
    @State private var isDropTargeted = false
    @State private var showingImportAlert = false
    @State private var importErrorMessage: String?

    private var visibleDocs: [VaultDoc] {
        library.docs(in: section)
    }

    var body: some View {
        List {
            ForEach(visibleDocs, id: \.self) { doc in
                NavigationLink {
                    DocDetailView(doc: doc)
                } label: {
                    DocRow(doc: doc)
                }
                .contextMenu {
                    docContextMenu(doc)
                }
            }
            .onDelete(perform: deleteDocuments)
        }
        .navigationTitle(section?.name ?? "All Documents")
        .overlay {
            if visibleDocs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No documents yet")
                    Button("Add Documents") {
                        importKind = .files
                    }
                }
                .padding()
            }
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        Label("Drop to import", systemImage: "square.and.arrow.down")
                            .font(.title3.weight(.semibold))
                    }
                    .padding(12)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { importKind = .files } label: {
                        Label("Import Files…", systemImage: "folder")
                    }
                    Button { importKind = .photos } label: {
                        Label("Import Photos…", systemImage: "photo")
                    }
                    Button { importKind = .note } label: {
                        Label("New Note", systemImage: "note.text")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                SyncBadge()
            }
        }
        .sheet(item: $importKind) { kind in
            ImportView(kind: kind, section: section)
        }
        .alert("Import Problem", isPresented: $showingImportAlert) {
            Button("OK") { }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            for provider in providers {
                provider.loadItem(
                    forTypeIdentifier: UTType.fileURL.identifier,
                    options: nil
                ) { item, _ in
                    guard let url = item as? URL else { return }
                    Task { @MainActor in
                        importFileURL(url)
                    }
                }
            }
            return true
        }
    }

    @ViewBuilder
    private func docContextMenu(_ doc: VaultDoc) -> some View {
        ShareLink(
            item: doc.fileData ?? Data(),
            preview: SharePreview(doc.title ?? "Document")
        ) {
            Label("Share File", systemImage: "square.and.arrow.up")
        }
        .disabled(doc.fileData == nil)
        Button(role: .destructive) {
            library.deleteDocument(doc)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func deleteDocuments(_ offsets: IndexSet) {
        let snapshot = visibleDocs
        for index in offsets where index < snapshot.count {
            library.deleteDocument(snapshot[index])
        }
    }

    private func importFileURL(_ url: URL) {
        do {
            let imported = try FileSupport.importFile(at: url)
            library.addDocument(imported: imported, to: section)
        } catch {
            importErrorMessage = error.localizedDescription
            showingImportAlert = true
        }
    }
}

// MARK: - Row

struct DocRow: View {
    let doc: VaultDoc

    private var kind: DocKind {
        DocKind.kind(mimeType: doc.mimeType, fileName: doc.fileName, hasFile: doc.fileData != nil)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: kind.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.title ?? "Untitled")
                    .lineLimit(2)
                if let fileName = doc.fileName, !fileName.isEmpty {
                    Text("\(fileName) · \(Self.dateString(for: doc))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let added = doc.addedDate {
                    Text(Self.dateString(for: doc))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    static func dateString(for doc: VaultDoc) -> String {
        guard let added = doc.addedDate else { return "" }
        return added.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Sync status badge

struct SyncBadge: View {
    @Environment(Library.self) private var library

    var body: some View {
        Group {
            switch library.syncState {
            case .synced:
                Label("Synced", systemImage: "icloud.fill")
                    .foregroundStyle(.secondary)
            case .syncing:
                Label("Syncing…", systemImage: "icloud")
                    .foregroundStyle(.secondary)
            case .offline:
                Label("Offline", systemImage: "icloud.slash")
                    .foregroundStyle(.orange)
            case .notSignedIn:
                Label("iCloud Sign-In Needed", systemImage: "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
        .help(
            "Synced: connected to iCloud. Offline: changes are saved on this device and sync later. "
            + "Sign in to iCloud in Settings to sync across devices."
        )
    }
}
