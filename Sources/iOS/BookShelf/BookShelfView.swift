import SwiftUI
import NurseVaultCore
import PDFKit

/// Grid of book covers (first-page thumbnails) with reading progress.
/// Replaces the old BooksView which filtered all vault documents by extension.
///
/// - Note: Books with `totalPages > 0` (flagged via `addBook`) appear here.
///   Regular documents (notes, images, PDF documents) stay in the vault list.
struct BookShelfView: View {
    let library: Library
    let onBookTapped: (VaultDoc) -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if library.books.isEmpty {
                    ContentUnavailableView(
                        "No Books Yet",
                        systemImage: "book.closed",
                        description: Text(
                            "Tap + to import a PDF, text file, or RTF as a book."
                        )
                    )
                } else {
                    bookGrid
                }
            }
            .navigationTitle("Books")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { showingImport = true } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImport,
                allowedContentTypes: [.pdf, .plainText, .rtf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importBook(from: url)
                case .failure: break
                }
            }
            .alert("Import Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Could not import book.")
            }
        }
    }
    
    // MARK: - Book grid
    
    private var bookGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)
            ], spacing: 16) {
                ForEach(library.books) { doc in
                    BookCoverCard(library: library, doc: doc) {
                        onBookTapped(doc)
                    }
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Import
    
    @State private var showingImport = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private func importBook(from url: URL) {
        let neededScope = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        Task { @MainActor in
            do {
                // Minimal text extraction: for text files read directly,
                // for PDFs/RTFs rely on the library's background extraction.
                var extractedText: String?
                let ext = url.pathExtension.lowercased()
                if ext == "txt" {
                    if let fileData = try? Data(contentsOf: url) {
                        extractedText = FileSupport.text(from: fileData)
                    }
                }
                // For PDFs and RTFs the Library.addBook() will trigger background
                // text extraction via the search pipeline.
                
                let imported = try await FileSupport.importFileAsync(at: url)
                _ = library.addBook(
                    imported: imported,
                    extractedText: extractedText
                )
                // The book won't appear in the grid until reload completes.
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

/// A book cover card showing the first-page thumbnail, title, and progress bar.
private struct BookCoverCard: View {
    let library: Library
    let doc: VaultDoc
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                bookThumbnail
                
                Text(doc.title ?? doc.fileName ?? "Untitled")
                    .font(.caption)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                ProgressView(value: doc.readingProgress)
                    .tint(doc.isBook ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(8)
            .frame(height: 180)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                library.deleteDocument(doc)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var bookThumbnail: some View {
        Group {
            if let data = doc.fileData, mimeTypeIsPDF {
                firstPageThumbnail(data: data)
                    .frame(height: 120)
                    .clipped()
            } else if let text = doc.noteText ?? doc.extractedText, !text.isEmpty {
                Text(text.prefix(200))
                    .font(.caption2)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "doc.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
            }
        }
    }
    
    private var mimeTypeIsPDF: Bool {
        let mime = (doc.mimeType ?? "").lowercased()
        let name = (doc.fileName ?? "").lowercased()
        return mime == "application/pdf" || name.hasSuffix(".pdf")
    }
    
    @ViewBuilder
    private func firstPageThumbnail(data: Data) -> some View {
        #if canImport(PDFKit)
        if let pdf = PDFDocument(data: data), pdf.pageCount > 0, let page = pdf.page(at: 0) {
            let renderer = UIGraphicsImageRenderer(size: page.bounds(for: .mediaBox).size)
            let image = renderer.image { ctx in
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "doc.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .frame(height: 120)
        }
        #else
        Image(systemName: "doc.fill")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(height: 120)
        #endif
    }
}
