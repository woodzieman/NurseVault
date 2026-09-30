import SwiftUI
import UniformTypeIdentifiers
import NurseVaultCore

/// Where `VaultListView` is looking: the whole vault, one section, or one
/// folder. The list is recursive — folders navigate one level deeper,
/// documents open their detail view.
enum VaultContainer: Hashable {
    case section(VaultSection)
    case folder(VaultFolder)
}

struct VaultListView: View {
    @Environment(Library.self) private var library
    let container: VaultContainer?

    @State private var importKind: ImportKind?
    @State private var showingNewFolder = false
    @State private var renameTarget: RenameTarget?
    @State private var deleteTarget: DeleteTarget?
    @State private var isDropTargeted = false
    @State private var showingImportAlert = false
    @State private var importErrorMessage: String?
    @State private var searchText = ""

    enum VaultItem: Hashable {
        case doc(VaultDoc)
        case folder(VaultFolder)
    }

    struct RenameTarget: Identifiable {
        let id = UUID()
        let folder: VaultFolder
    }

    struct DeleteTarget: Identifiable {
        let id = UUID()
        let folder: VaultFolder
    }

    // MARK: - Container helpers

    private var currentSection: VaultSection? {
        switch container {
        case nil:
            return nil
        case .section(let section):
            return section
        case .folder(let folder):
            return folder.section
        }
    }

    private var currentFolder: VaultFolder? {
        if case .folder(let folder) = container {
            return folder
        }
        return nil
    }

    /// Folders directly inside the container.
    private var directFolders: [VaultFolder] {
        switch container {
        case nil:
            return library.folders(in: nil)
        case .section(let section):
            return library.folders(in: section)
        case .folder(let folder):
            return library.subfolders(of: folder)
        }
    }

    /// Documents directly inside the container.
    private var directDocs: [VaultDoc] {
        switch container {
        case nil:
            return library.docs
                .filter { $0.folder == nil }
                .sorted { ($0.title ?? "").localizedCompare($1.title ?? "") == .orderedAscending }
        case .section(let section):
            return library.docs(in: section).filter { $0.folder == nil }
        case .folder(let folder):
            return library.docs(in: folder)
        }
    }

    /// Every folder in the container's subtree (for search + move menus).
    private var subtreeFolders: [VaultFolder] {
        switch container {
        case nil:
            return library.folders
        case .section(let section):
            return library.folders.filter { $0.section === section }
        case .folder(let folder):
            return library.subtreeFolders(of: folder)
        }
    }

    /// Every document in the container's subtree, regardless of nesting.
    private var subtreeDocs: [VaultDoc] {
        switch container {
        case nil:
            return library.docs
        case .section(let section):
            return library.docs(in: section)
        case .folder(let folder):
            return library.allDocs(in: folder)
        }
    }

    private var visibleItems: [VaultItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let items: [VaultItem]
        if trimmed.isEmpty {
            items = directFolders.map { VaultItem.folder($0) }
                + directDocs.map { VaultItem.doc($0) }
        } else {
            // Searching looks through the whole subtree so documents in
            // nested folders are still findable.
            let scope = Set(subtreeDocs.map(\.objectID))
            let matchingDocs = library.docs(matching: trimmed)
                .filter { scope.contains($0.objectID) }
                .map { VaultItem.doc($0) }
            let matchingFolders = subtreeFolders
                .filter { ($0.name ?? "").localizedCaseInsensitiveContains(trimmed) }
                .map { VaultItem.folder($0) }
            items = matchingDocs + matchingFolders
        }

        return items.sorted {
            let weight1 = itemWeight($0)
            let weight2 = itemWeight($1)
            if weight1 != weight2 { return weight1 < weight2 }
            return itemName($0).localizedCompare(itemName($1)) == .orderedAscending
        }
    }

    private func itemWeight(_ item: VaultItem) -> Int {
        switch item {
        case .folder: return 0
        case .doc: return 1
        }
    }

    private func itemName(_ item: VaultItem) -> String {
        switch item {
        case .doc(let doc): return doc.title ?? "Untitled"
        case .folder(let folder): return folder.name ?? "Untitled"
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            ForEach(visibleItems, id: \.self) { item in
                switch item {
                case .folder(let folder):
                    NavigationLink {
                        VaultListView(container: .folder(folder))
                    } label: {
                        FolderRow(folder: folder)
                    }
                    .contextMenu {
                        folderContextMenu(folder)
                    }
                case .doc(let doc):
                    NavigationLink {
                        DocDetailView(doc: doc)
                    } label: {
                        DocRow(doc: doc)
                    }
                    .contextMenu {
                        docContextMenu(doc)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(navigationTitle)
        .searchable(text: $searchText, prompt: "Search documents")
        .overlay {
            if visibleItems.isEmpty {
                VStack(spacing: 12) {
                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Nothing here yet")
                        HStack(spacing: 12) {
                            Button("New Folder") {
                                showingNewFolder = true
                            }
                            Button("Add Documents") {
                                importKind = .files
                            }
                        }
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No matches for “\(searchText.trimmingCharacters(in: .whitespaces))”")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
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
                    #if canImport(UIKit)
                    if CameraSupport.isAvailable {
                        Button { importKind = .camera } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                        Button { importKind = .ocr } label: {
                            Label("Scan & OCR", systemImage: "text.viewfinder")
                        }
                    }
                    #endif
                    Divider()
                    Button { showingNewFolder = true } label: {
                        Label("New Folder…", systemImage: "folder.badge.plus")
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
            ImportView(
                kind: kind,
                section: currentSection,
                folder: currentFolder
            )
        }
        .sheet(isPresented: $showingNewFolder) {
            NewFolderView(section: currentSection, folder: currentFolder)
        }
        .sheet(item: $renameTarget) { target in
            RenameFolderView(folder: target.folder)
        }
        .confirmationDialog(
            "Delete “\(deleteTarget?.folder.name ?? "")”?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Folder and Contents", role: .destructive) {
                if let target = deleteTarget {
                    library.deleteFolder(target.folder)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            if let target = deleteTarget {
                let docCount = library.allDocs(in: target.folder).count
                let subfolderCount = library.subtreeFolders(of: target.folder).count - 1
                Text(
                    "This deletes the folder, \(subfolderCount) subfolder\(subfolderCount == 1 ? "" : "s"), "
                    + "and \(docCount) document\(docCount == 1 ? "" : "s")."
                )
            }
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

    private var navigationTitle: String {
        switch container {
        case nil:
            return "All Documents"
        case .section(let section):
            return section.name ?? "Documents"
        case .folder(let folder):
            return folder.name ?? "Folder"
        }
    }

    // MARK: - Menus and actions

    @ViewBuilder
    private func folderContextMenu(_ folder: VaultFolder) -> some View {
        Button {
            renameTarget = RenameTarget(folder: folder)
        } label: {
            Label("Rename…", systemImage: "pencil")
        }

        Menu {
            Button {
                library.moveFolder(folder, to: nil)
            } label: {
                Label("Move to Top Level", systemImage: "arrow.up.to.line")
            }
            let candidates = moveCandidates(for: folder)
            if candidates.isEmpty {
                Text("No Other Folders")
            } else {
                ForEach(candidates, id: \.self) { candidate in
                    Button {
                        library.moveFolder(folder, to: candidate)
                    } label: {
                        Label("Move to \(candidate.name ?? "Folder")", systemImage: "folder")
                    }
                }
            }
        } label: {
            Label("Move To…", systemImage: "folder")
        }

        Divider()
        Button(role: .destructive) {
            deleteTarget = DeleteTarget(folder: folder)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    /// Valid move targets: folders in the same section, excluding the
    /// folder itself and its descendants (moving into a descendant would
    /// create a cycle).
    private func moveCandidates(for folder: VaultFolder) -> [VaultFolder] {
        subtreeFolders.filter { candidate in
            !folder.isAncestor(of: candidate)
        }
        .sorted { $0.pathLabel.localizedCompare($1.pathLabel) == .orderedAscending }
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

    private func importFileURL(_ url: URL) {
        do {
            let imported = try FileSupport.importFile(at: url)
            library.addDocument(
                imported: imported,
                to: currentSection,
                in: currentFolder
            )
        } catch {
            importErrorMessage = error.localizedDescription
            showingImportAlert = true
        }
    }
}

// MARK: - Rows

struct FolderRow: View {
    @Environment(Library.self) private var library
    let folder: VaultFolder

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name ?? "Untitled")
                    .lineLimit(2)
                let count = library.docs(in: folder).count
                if count > 0 {
                    Text("\(count) document\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

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
                } else if doc.addedDate != nil {
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

// MARK: - Folder management sheets

struct NewFolderView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    let section: VaultSection?
    let folder: VaultFolder?

    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Folder name", text: $name)
            }
            .navigationTitle("New Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        library.addFolder(name: trimmed, in: section, parent: folder)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(width: 380, height: 180)
            #endif
        }
    }
}

struct RenameFolderView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    let folder: VaultFolder
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Folder name", text: $name)
            }
            .navigationTitle("Rename Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        library.renameFolder(folder, to: trimmed)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = folder.name ?? ""
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(width: 380, height: 180)
            #endif
        }
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
