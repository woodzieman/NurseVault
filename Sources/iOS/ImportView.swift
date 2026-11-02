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
    case book

    var id: String { rawValue }

    var title: String {
        switch self {
        case .files: "Import Files"
        case .photos: "Import Photos"
        case .note: "New Note"
        case .camera: "Take Photo"
        case .ocr: "Scan & OCR"
        case .book: "Import Book"
        }
    }

    var systemImage: String {
        switch self {
        case .files: "folder"
        case .photos: "photo"
        case .note: "note.text"
        case .camera: "camera"
        case .ocr: "text.viewfinder"
        case .book: "book.closed.fill"
        }
    }
}

struct ImportView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    let kind: ImportKind
    let section: VaultSection?
    /// The folder the import was started from, if any. Defaults the
    /// "Save to" picker to this location.
    let folder: VaultFolder?

    /// Where the imported content lands.
    private enum SaveLocation: Hashable {
        /// The containing section's top level (or the vault root).
        case section
        case folder(VaultFolder)
        case newFolder
    }

    @State private var showingFileImporter = false
    @State private var showingBookFileImporter = false
    @State private var pickedPhotos: [PhotosPickerItem] = []
    @State private var loadingPhotos = false
    @State private var noteTitle = ""
    @State private var noteBody = ""
    @State private var saveLocation: SaveLocation?
    @State private var newFolderName = ""
    /// The folder created for the "New Folder…" option, created at most
    /// once per sheet so repeated saves (e.g. a multi-file import) all go
    /// to the same folder.
    @State private var createdNewFolder: VaultFolder?
    @State private var showingErrorAlert = false
    @State private var errorMessage: String?
    @State private var scanFlow = CzurBookScanFlow()
    @State private var scannerTitle = ""
    @State private var scannerAutoCapture = false
    @State private var scannerVideoPreview = false
    @State private var scannerConvertToPdf = false
    @State private var scannerDeviceId: String? = nil

    /// Folders the user can choose: everything in the current section
    /// (nested included, path-labeled), or the whole vault at the top level.
    private var candidateFolders: [VaultFolder] {
        let pool = section == nil
            ? library.folders
            : library.folders.filter { $0.section === section }
        return pool.sorted {
            $0.pathLabel.localizedCompare($1.pathLabel) == .orderedAscending
        }
    }

    private var resolvedLocation: SaveLocation {
        if let saveLocation { return saveLocation }
        if let folder { return .folder(folder) }
        return .section
    }

    private var scanPhaseIsActive: Bool {
        switch scanFlow.phase {
        case .idle, .completed:
            return false
        case .connecting, .scanning, .processing, .saving:
            return true
        case .failed:
            return false
        }
    }

    // MARK: - CZUR ET Max scan state

    /// The folder the content should be stored in, or nil for the section
    /// top level.
    ///
    /// This performs a mutation (it may create the "New Folder…" folder), so
    /// it must only be called from save actions — never from `body`.
    private func makeSaveFolder() -> VaultFolder? {
        switch resolvedLocation {
        case .section:
            return nil
        case .folder(let target):
            return target
        case .newFolder:
            if let created = createdNewFolder {
                return created
            }
            let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let created = library.addFolder(name: trimmed, in: section, parent: folder)
            createdNewFolder = created
            return created
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                saveToSection

                switch kind {
                case .files:
                    Section {
                        Button("Choose Files or Folders…") {
                            showingFileImporter = true
                        }
                    } footer: {
                        let limitMB = FileSupport.maxFileBytes / (1024 * 1024)
                        Text(
                            "PDFs, images, text files, and folders. Folders are imported as vault folders with their contents. "
                            + "You can also drag files or folders onto a list in the app. Files up to \(limitMB) MB are stored and synced to iCloud."
                        )
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
                case .book:
                    Section {
                        Button("Choose a PDF, Text, or RTF file…") {
                            showingBookFileImporter = true
                        }
                        Button("Scan with CZUR ET Max…") {
                            Task { await runCzurBookScan() }
                        }
                        TextField("Book title", text: $scannerTitle)
                            .disabled(scanPhaseIsActive)
                        if scanPhaseIsActive {
                            CzurScanProgressView(phase: scanFlow.phase)
                        }
                        Toggle("Auto page-turn capture", isOn: $scannerAutoCapture)
                            .disabled(scanPhaseIsActive)
                        Toggle("Show video preview", isOn: $scannerVideoPreview)
                            .disabled(scanPhaseIsActive)
                        Toggle("Save converted PDF", isOn: $scannerConvertToPdf)
                            .disabled(scanPhaseIsActive)
                        if !scanPhaseIsActive, !scanFlow.devices.isEmpty {
                            Picker("Scanner device", selection: Binding<String>(
                                get: { scannerDeviceId ?? scanFlow.devices.first?.deviceId ?? "" },
                                set: { scannerDeviceId = $0 }
                            )) {
                                ForEach(scanFlow.devices, id: \.deviceId) { device in
                                    Text(device.name ?? device.deviceId)
                                        .tag(device.deviceId)
                                }
                            }
                        }
                        if scanPhaseIsActive, scanFlow.phase == .scanning, let deviceId = scanFlow.activeDeviceId {
                            CzurVideoPreview(client: CzurOpenRuntimeClient.shared, deviceId: deviceId)
                                .frame(height: 240)
                        }
                    } footer: {
                        let limitMB = FileSupport.maxFileBytes / (1024 * 1024)
                        Text(
                            "Books are imported with text extracted automatically "
                            + "so they become searchable immediately. Files up to "
                            + "\(limitMB) MB."
                        )
                    }
                case .camera, .ocr:
                    // The camera capture UI (and its state) lives in a
                    // dedicated view; keep this `#if` branch a single view
                    // so no conditionally-compiled captures nest in here.
                    // Folder resolution is deferred to save time via the
                    // closure, because the "New Folder…" folder is created
                    // by this view, not by the camera section.
                    #if canImport(UIKit)
                    CameraImportSection(
                        kind: kind,
                        section: section,
                        folder: folder
                    ) { makeSaveFolder() }
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
                            saveNote()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.pdf, .image, .plainText, .rtf, .folder, .item],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    let targetFolder = makeSaveFolder()
                    var failures: [String] = []
                    var folderSummaries: [String] = []
                    for url in urls {
                        if FileSupport.isDirectory(at: url) {
                            let summary = library.importFolder(
                                at: url,
                                to: targetFolder?.section ?? section,
                                in: targetFolder
                            ).summary
                            folderSummaries.append(summary)
                        } else {
                            do {
                                let imported = try FileSupport.importFile(at: url)
                                library.addDocument(
                                    imported: imported,
                                    to: targetFolder?.section ?? section,
                                    in: targetFolder
                                )
                            } catch {
                                failures.append(error.localizedDescription)
                            }
                        }
                    }
                    if !folderSummaries.isEmpty {
                        errorMessage = folderSummaries.joined(separator: "\n")
                        showingErrorAlert = true
                    } else if let first = failures.first {
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
            .fileImporter(
                isPresented: $showingBookFileImporter,
                allowedContentTypes: [.pdf, .plainText, .rtf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importBookFile(from: url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
            .alert("Import", isPresented: $showingErrorAlert) {
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

    // MARK: - Save location

    private var saveToSection: some View {
        Section("Save to") {
            Picker("Location", selection: Binding(
                get: { resolvedLocation },
                set: { saveLocation = $0 }
            )) {
                Text(section?.name ?? "No Section")
                    .tag(SaveLocation.section)
                ForEach(candidateFolders, id: \.self) { candidate in
                    Text(candidate.pathLabel)
                        .tag(SaveLocation.folder(candidate))
                }
                Text("New Folder…")
                    .tag(SaveLocation.newFolder)
            }
            if resolvedLocation == .newFolder {
                TextField("New folder name", text: $newFolderName)
            }
        }
    }

    private func saveNote() {
        let trimmed = noteTitle.trimmingCharacters(in: .whitespaces)
        let targetFolder = makeSaveFolder()
        library.addNote(
            title: trimmed.isEmpty ? "Untitled Note" : trimmed,
            body: noteBody,
            to: targetFolder?.section ?? section,
            in: targetFolder
        )
        dismiss()
    }

    private func importPhotos() {
        loadingPhotos = true
        let targetFolder = makeSaveFolder()
        let targetSection = targetFolder?.section ?? section
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
                    library.addDocument(
                        imported: imported,
                        to: targetSection,
                        in: targetFolder
                    )
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
    
    /// Scans the current book with the CZUR ET Max via the local CZUR Open
    /// runtime and saves the searchable text into the library.
    private func runCzurBookScan() async {
        // A scan honors the sheet's save-location picker, like file imports.
        let targetFolder = makeSaveFolder()
        let trimmedTitle = scannerTitle.trimmingCharacters(in: .whitespaces)
        let title = trimmedTitle.isEmpty
            ? "CZUR Scan \(Date.now.formatted(.dateTime.day().month().year()))"
            : trimmedTitle
        let outcome = await CzurBookScanFlow.shared.scanAndSaveBook(
            library: library,
            title: title,
            section: targetFolder?.section,
            folder: targetFolder,
            options: CzurBookScanFlow.ScanOptions(
                autoCaptureEnabled: scannerAutoCapture,
                videoPreviewEnabled: scannerVideoPreview,
                convertCapturedPagesToPdf: scannerConvertToPdf,
                deviceId: scannerDeviceId
            )
        )
        switch outcome {
        case .saved:
            dismiss()
        case .cancelled:
            break
        case .failed(let message):
            errorMessage = message
            showingErrorAlert = true
        }
    }

    /// Imports a book file through the BookIngestionEngine.
    private func importBookFile(from url: URL) {
        // Start security scope (no-op for Mac unscoped URLs).
        let neededScope = url.startAccessingSecurityScopedResource()
        defer {
            if neededScope { url.stopAccessingSecurityScopedResource() }
        }
        
        Task {
            let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
            if let extractedText = await BookIngestionEngine.shared
                .extractText(from: url, mimeType: mimeType, fileName: url.lastPathComponent),
               let data = try? Data(contentsOf: url) {
                let name = url.lastPathComponent
                let title = URL(fileURLWithPath: name).deletingPathExtension()
                    .lastPathComponent
                let imported = ImportedFile(
                    data: data,
                    fileName: name,
                    title: title,
                    mimeType: mimeType
                )
                let targetFolder = makeSaveFolder()
                library.addDocument(
                    imported: imported,
                    noteText: extractedText,
                    to: targetFolder?.section,
                    in: targetFolder
                )
                if errorMessage != nil {
                    showingErrorAlert = true
                } else {
                    dismiss()
                }
            } else {
                errorMessage = "Couldn't extract text from this file."
                showingErrorAlert = true
            }
        }
    }
}
