import SwiftUI
import NurseVaultCore

private extension Array {
    /// Bounds-checked subscript for picker indices, which can briefly lag
    /// behind a changing options list.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct DocDetailView: View {
    @Environment(Library.self) private var library
    let doc: VaultDoc

    @State private var isEditing = false

    private var kind: DocKind {
        DocKind.kind(mimeType: doc.mimeType, fileName: doc.fileName, hasFile: doc.fileData != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = doc.fileData {
                fileContent(data: data)
            } else if let note = doc.noteText, !note.isEmpty {
                Text(note)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ContentUnavailableView("Empty Document", systemImage: "doc")
            }

            if let note = doc.noteText, !note.isEmpty, doc.fileData != nil {
                Divider()
                Text("Notes")
                    .font(.headline)
                Text(note)
                    .textSelection(.enabled)
            }

            Divider()
            HStack(spacing: 12) {
                if let fileName = doc.fileName, !fileName.isEmpty {
                    Label(fileName, systemImage: "doc")
                }
                if let size = doc.fileData {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(size.count), countStyle: .file))
                }
                if let added = doc.addedDate {
                    Text("Added \(added.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(doc.title ?? "Untitled")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    library.deleteDocument(doc)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            DocEditView(doc: doc)
        }
    }

    @ViewBuilder
    private func fileContent(data: Data) -> some View {
        switch kind {
        case .pdf:
            VaultPDFView(data: data)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .image:
            VaultImageView(data: data)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .text:
            ScrollView {
                Text(FileSupport.text(from: data) ?? "…")
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .other:
            VStack(spacing: 8) {
                Image(systemName: "doc.zipper")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No preview for \(doc.fileName ?? "this file").")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .note:
            EmptyView()
        }
    }
}

// MARK: - Editing

struct DocEditView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    let doc: VaultDoc

    @State private var title = ""
    @State private var note = ""
    @State private var selectedSectionIndex: Int?
    @State private var selectedFolderIndex: Int?

    /// All folders, path-labeled and section-grouped, for the move picker.
    private var folderOptions: [VaultFolder] {
        library.folders.sorted {
            $0.pathLabel.localizedCompare($1.pathLabel) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Notes", text: $note, axis: .vertical)
                    .lineLimit(4...12)
                Picker("Section", selection: $selectedSectionIndex) {
                    Text("No Section")
                        .tag(Int?.none)
                    ForEach(Array(library.sections.enumerated()), id: \.offset) { index, section in
                        Text(section.name ?? "Untitled")
                            .tag(Int?.some(index))
                    }
                }
                Picker("Folder", selection: $selectedFolderIndex) {
                    Text("No Folder")
                        .tag(Int?.none)
                    ForEach(Array(folderOptions.enumerated()), id: \.offset) { index, folder in
                        Text(folder.pathLabel)
                            .tag(Int?.some(index))
                    }
                }
                .onChange(of: selectedFolderIndex) { _, newIndex in
                    // A folder's section wins over the picker above.
                    if let newIndex, let folder = folderOptions[safe: newIndex],
                       let folderSection = folder.section {
                        selectedSectionIndex = library.sections.firstIndex {
                            $0 === folderSection
                        }
                    }
                }
            }
            .navigationTitle("Edit Document")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let section = selectedSectionIndex.flatMap { index in
                            library.sections.indices.contains(index) ? library.sections[index] : nil
                        }
                        let folder = selectedFolderIndex.flatMap { index in
                            folderOptions.indices.contains(index) ? folderOptions[index] : nil
                        }
                        library.updateDocument(
                            doc,
                            title: title,
                            noteText: note,
                            section: section,
                            folder: folder
                        )
                        dismiss()
                    }
                }
            }
            .onAppear {
                title = doc.title ?? ""
                note = doc.noteText ?? ""
                selectedSectionIndex = doc.section.flatMap { saved in
                    library.sections.firstIndex { $0 === saved }
                }
                selectedFolderIndex = doc.folder.flatMap { saved in
                    folderOptions.firstIndex { $0 === saved }
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 460, minHeight: 300)
            #endif
        }
    }
}
