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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingBookImport = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
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
    private func importBook(from url: URL) {
        // Start security scope (no-op for Mac unscoped URLs).
        let neededScope = url.startAccessingSecurityScopedResource()
        defer {
            if neededScope { url.stopAccessingSecurityScopedResource() }
        }
        
        Task {
            // Run the ingestion engine to extract searchable text immediately.
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
                library.addDocument(
                    imported: imported,
                    noteText: extractedText,
                    to: nil,
                    in: nil
                )
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
