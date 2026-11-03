import SwiftUI
import UniformTypeIdentifiers
import NurseVaultCore

/// Lists user-imported books and provides an "Add Book" button.
///
/// Books are documents whose MIME type or filename extension signals a
/// book-like format (PDF, plain text, RTF). The dedicated import path
/// runs the document through `BookIngestionEngine` so the text is
/// immediately available for search.
struct BooksView: View {
    let library: Library

    @Environment(\.dismiss) private var dismiss
    @State private var importState = BookImportState()

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    ContentUnavailableView(
                        "No Books Yet",
                        systemImage: "book.closed",
                        description: Text("Tap the + button to import a PDF, text file, or RTF.")
                    )
                } else {
                    bookList
                }
            }
            .navigationTitle("Books")
            .toolbar {
                // `.confirmationAction` exists on both iOS and macOS, so the
                // "Add Book" button works cross-platform without a `#if os(iOS)` guard.
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingBookImport = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                    .disabled(importState.isActive)
                }
            }
            .fileImporter(
                isPresented: $showingBookImport,
                allowedContentTypes: [.pdf, .plainText, .rtf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importBook(from: url)
                case .failure:
                    break
                }
            }
            .overlay {
                if importState.isActive {
                    BookImportProgressOverlay(state: importState)
                }
            }
            .alert(
                "Couldn’t Import Book",
                isPresented: Binding(
                    get: { importState.error != nil },
                    set: { if !$0 { importState.error = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importState.error ?? "Unknown error")
            }
        }
    }

    // MARK: - Data

    /// Documents whose extension or MIME type suggests a book.
    private var books: [VaultDoc] {
        library.docs.filter { doc in
            let mimeType = (doc.mimeType ?? "").lowercased()
            let name = (doc.fileName ?? "").lowercased()

            // PDFs, text, and RTF files
            if mimeType == "application/pdf" || name.hasSuffix(".pdf") { return true }
            if mimeType == "text/plain" || name.hasSuffix(".txt") { return true }
            if mimeType == "application/rtf" || name.hasSuffix(".rtf") { return true }

            return false
        }
    }

    // MARK: - Import flow

    @State private var showingBookImport = false

    /// Imports a single book file through the ingestion engine.
    ///
    /// The security scope is started *inside* the task. If it were started in
    /// the synchronous caller and stopped on return, the async file reads
    /// would run after the scope closed and silently fail on iOS.
    private func importBook(from url: URL) {
        importState.begin(url.lastPathComponent)

        let importModel = importState

        Task { @MainActor in
            do {
                let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType

                let extractedText = await BookIngestionEngine.shared.extractText(
                    from: url,
                    mimeType: mimeType,
                    fileName: url.lastPathComponent
                ) { fraction in
                    Task { @MainActor in
                        importModel.update(fraction)
                    }
                }

                guard let extractedText else {
                    throw CancellationError()
                }

                let imported = try await FileSupport.importFileAsync(at: url)
                importModel.update(1)

                library.addDocument(
                    imported: imported,
                    extractedText: extractedText,
                    to: nil,
                    in: nil
                )

                importModel.finish()
            } catch is CancellationError {
                importModel.fail("Couldn’t extract searchable text from this file. The PDF may be scanned images without a text layer.")
            } catch {
                importModel.fail("Couldn’t import \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - List

    private var bookList: some View {
        List(books) { doc in
            BookRow(doc: doc)
        }
    }
}

// MARK: - Book Row

private struct BookRow: View {
    let doc: VaultDoc

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(doc.title ?? doc.fileName ?? "Untitled")
                .font(.body)
                .lineLimit(2)

            if let noteText = doc.noteText, !noteText.isEmpty {
                Text(notesPreview(noteText))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 2)
    }

    /// Shows the first ~120 characters of the extracted text.
    private func notesPreview(_ text: String) -> String {
        let preview = String(text.prefix(120))
        return preview + (text.count > 120 ? "…" : "")
    }
}
