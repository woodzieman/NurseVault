import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import NurseVaultCore

enum ImportKind: String, Identifiable, CaseIterable {
    case files
    case photos
    case note
    case camera
    case ocr

    var id: String { rawValue }

    var title: String {
        switch self {
        case .files: "Import Files"
        case .photos: "Import Photos"
        case .note: "New Note"
        case .camera: "Take Photo"
        case .ocr: "Scan & OCR"
        }
    }

    var systemImage: String {
        switch self {
        case .files: "folder"
        case .photos: "photo"
        case .note: "note.text"
        case .camera: "camera"
        case .ocr: "text.viewfinder"
        }
    }
}

struct ImportView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    let kind: ImportKind
    let section: VaultSection?

    @State private var showingFileImporter = false
    @State private var pickedPhotos: [PhotosPickerItem] = []
    @State private var loadingPhotos = false
    @State private var noteTitle = ""
    @State private var noteBody = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                switch kind {
                case .files:
                    Section {
                        Button("Choose Files…") {
                            showingFileImporter = true
                        }
                    } footer: {
                        Text("PDFs, images, text files, and more. Files up to \(FileSupport.maxFileBytes / (1024 * 1024)) MB are stored and synced to iCloud.")
                    }
                case .photos:
                    Section {
                        PhotosPicker(
                            selection: $pickedPhotos,
                            maxSelectionCount: nil,
                            selectionBehavior: .ordered,
                            matching: .images
                        ) {
                            Label("Choose Photos", systemImage: "photo.on.rectangle")
                        }
                        if !pickedPhotos.isEmpty {
                            Button(
                                loadingPhotos ? "Importing…" : "Import \(pickedPhotos.count) Photo\(pickedPhotos.count == 1 ? "" : "s")",
                                action: importPhotos
                            )
                            .disabled(loadingPhotos)
                        }
                    }
                case .note:
                    Section("Note") {
                        TextField("Title", text: $noteTitle)
                        TextField("Reference text", text: $noteBody, axis: .vertical)
                            .lineLimit(5...16)
                    }
                case .camera, .ocr:
                    // The camera capture UI (and its state) lives in a
                    // dedicated view; keep this `#if` branch a single view
                    // so no conditionally-compiled captures nest in here.
                    #if canImport(UIKit)
                    CameraImportSection(kind: kind, section: section)
                    #else
                    Section {
                        Text("The camera is only available on iPhone and iPad.")
                    }
                    #endif
                }
            }
            .navigationTitle(kind.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if kind == .note {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = noteTitle.trimmingCharacters(in: .whitespaces)
                            library.addNote(
                                title: trimmed.isEmpty ? "Untitled Note" : trimmed,
                                body: noteBody,
                                to: section
                            )
                            dismiss()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf, .image, .plainText, .rtf, .item],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    var failures: [String] = []
                    for url in urls {
                        do {
                            let imported = try FileSupport.importFile(at: url)
                            library.addDocument(imported: imported, to: section)
                        } catch {
                            failures.append(error.localizedDescription)
                        }
                    }
                    if let first = failures.first {
                        errorMessage = first
                        showingErrorAlert = true
                    } else {
                        dismiss()
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
            .alert("Couldn't Import", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "")
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 460, minHeight: 320)
            #endif
        }
    }

    private func importPhotos() {
        loadingPhotos = true
        Task {
            var failures = 0
            for (index, item) in pickedPhotos.enumerated() {
                let name = "photo-\(Int(Date.now.timeIntervalSince1970))-\(index + 1).jpg"
                if let data = try? await item.loadTransferable(type: Data.self),
                   let imported = try? FileSupport.importFile(
                       data: data,
                       suggestedName: name,
                       suggestedMIMEType: "image/jpeg"
                   ) {
                    library.addDocument(imported: imported, to: section)
                } else {
                    failures += 1
                }
            }
            if failures > 0 {
                errorMessage = "Some photos couldn't be imported."
                showingErrorAlert = true
            }
            loadingPhotos = false
            if failures == 0 {
                dismiss()
            }
        }
    }
}
