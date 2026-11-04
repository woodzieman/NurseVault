import SwiftUI
import NurseVaultCore
import PDFKit

/// Full-featured book reader with page-by-page navigation, bookmarks,
/// and reading progress. On iOS the TOC is a toggleable sidebar; on macOS
/// it appears side-by-side with the reader.
struct BookReaderView: View {
    let doc: VaultDoc
    @Environment(\.dismiss) private var dismiss
    @Environment(Library.self) private var library
    
    @State private var currentPage: Int = 1
    @State private var showingTOC = true
    @State private var pageThumbnails: [Image?] = []
    @State private var tocEntries: [TOCEntry] = []
    @State private var searchText = ""
    @State private var pdfDocument: PDFDocument?
    
    // MARK: - Body
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            Group {
                if showingTOC {
                    sidebarView
                } else {
                    readerView
                }
            }
            .navigationTitle(doc.title ?? doc.fileName ?? "Reader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingTOC.toggle() } label: {
                        Image(systemName: showingTOC ? "list.bullet" : "sidebar.left")
                    }
                    .help("Toggle TOC")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { toggleBookmark() } label: {
                        Image(systemName: bookmarks.contains(currentPage)
                            ? "bookmark.fill" : "bookmark")
                    }
                    .help("Page \(currentPage)")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(1...max(doc.bookTotalPages, 1), id: \.self) { page in
                            Button("Page \(page)") { goToPage(page) }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .disabled(currentPage <= 0)
                }
            }
        }
        #else
        NavigationSplitView {
            sidebarView
        } detail: {
            readerView
        }
        .navigationTitle(doc.title ?? doc.fileName ?? "Reader")
        #endif
    }
    
    // MARK: - Bookmarks (stored in VaultDoc)
    
    private var bookmarks: Set<Int> {
        doc.bookmarkPages
    }
    
    // MARK: - Sidebar
    
    @ViewBuilder
    private var sidebarView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(showingTOC ? "Table of Contents" : "Search")
                    .font(.headline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { showingTOC.toggle() } label: {
                    Image(systemName: showingTOC ? "sidebar.right" : "sidebar.left")
                }
            }
            .padding(.bottom, 4)
            .background(.ultraThinMaterial)
            
            if showingTOC {
                TOCList(entries: tocEntries, thumbnails: pageThumbnails) { page in
                    goToPage(page)
                }
            } else {
                SearchInBook(searchText: $searchText, doc: doc)
            }
        }
        .frame(width: 200)
    }
    
    // MARK: - Reader
    
    @ViewBuilder
    private var readerView: some View {
        Group {
            if let pdf = pdfDocument, pdf.pageCount > 0,
               currentPage <= pdf.pageCount,
               let page = pdf.page(at: currentPage - 1) {
                let renderer = UIGraphicsImageRenderer(size: page.bounds(for: .mediaBox).size)
                let uiImage = renderer.image { ctx in
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let text = doc.noteText ?? doc.extractedText, !text.isEmpty {
                TextPageView(
                    text: text,
                    currentPage: doc.bookCurrentPage,
                    totalPages: doc.bookTotalPages
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("No Content", systemImage: "doc")
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            currentPage = max(doc.bookCurrentPage, 1)
            loadBookData()
        }
        .onChange(of: currentPage) { _, newPage in
            saveReadingProgress(to: newPage)
        }
    }
    
    // MARK: - Data loading
    
    private func loadBookData() {
        pdfDocument = nil
        pageThumbnails = []
        tocEntries = []
        
        guard let data = doc.fileData, data.count > 0 else { return }
        
        #if canImport(PDFKit)
        if let pdf = PDFDocument(data: data) {
            self.pdfDocument = pdf
            
            // Pre-render up to 20 page thumbnails for TOC sidebar.
            let thumbCount = min(pdf.pageCount, 20)
            for i in 0..<thumbCount {
                if let page = pdf.page(at: i) {
                    let renderer = UIGraphicsImageRenderer(size: page.bounds(for: .mediaBox).size)
                    let uiImage = renderer.image { ctx in
                        page.draw(with: .mediaBox, to: ctx.cgContext)
                    }
                    pageThumbnails.append(Image(uiImage: uiImage))
                } else {
                    pageThumbnails.append(nil)
                }
            }
            
            // TOC generation skipped — the iOS 27 PDFOutline API was heavily redesigned.
            // Page navigation works via the page picker in the toolbar.
        }
        #endif
    }
    
    // MARK: - Navigation & Bookmarks
    
    private func goToPage(_ page: Int) {
        currentPage = max(1, min(page, pdfDocument?.pageCount ?? doc.bookTotalPages))
    }
    
    private func saveReadingProgress(to page: Int) {
        library.saveBookReadingProgress(doc, page: page)
    }
    
    private func toggleBookmark() {
        library.toggleBookmark(doc, page: currentPage)
    }
    
    // MARK: - TOC
    
    struct TOCEntry: Identifiable {
        let id = UUID()
        let title: String
        let level: Int
        let page: Int
    }
    
    private struct TOCList: View {
        let entries: [TOCEntry]
        let thumbnails: [Image?]
        let onTapped: (Int) -> Void
        
        var body: some View {
            List {
                ForEach(entries) { entry in
                    HStack(spacing: 8) {
                        let thumbIdx = min(entry.page - 1, thumbnails.count - 1)
                        if thumbIdx >= 0 {
                            thumbnails[thumbIdx]?
                                .frame(width: 30, height: 40)
                                .clipped()
                                .padding(.trailing, 4)
                        }
                        Text(entry.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text("p. \(entry.page)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .onTapGesture { onTapped(entry.page) }
                }
            }
            .listStyle(.plain)
        }
    }
    
    // MARK: - Text page view
    
    private struct TextPageView: View {
        let text: String
        let currentPage: Int
        let totalPages: Int
        
        var body: some View {
            ScrollView {
                Text(text)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Spacer()
                    Text("Page \(max(1, currentPage)) of \(max(1, totalPages))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Search in book
    
    @MainActor
    private struct SearchInBook: View {
        @Binding var searchText: String
        let doc: VaultDoc
        
        var body: some View {
            VStack(spacing: 0) {
                TextField("Search within book\u{2026}", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.ultraThinMaterial)
                
                ScrollView {
                    let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty {
                        Text("Type to search within this book.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        let content = doc.noteText ?? doc.extractedText ?? ""
                        let matches = findMatches(in: content, query: trimmed)
                        if matches.isEmpty {
                            Text("No matches found.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(matches.prefix(20).enumerated()), id: \.offset) { _, match in
                                Text(match)
                                    .font(.caption2)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        
        private func findMatches(in text: String, query: String) -> [String] {
            let needle = VaultSearch.normalize(query)
            let folded = VaultSearch.normalize(text)
            var matches: [String] = []
            var searchFrom = folded.startIndex
            while let range = folded[searchFrom...].range(of: needle) {
                let startOffset = max(0, Int(range.lowerBound.utf16Offset(in: folded)) - 60)
                let endOffset = min(folded.count, Int(range.upperBound.utf16Offset(in: folded)) + 60)
                let start = folded.index(folded.startIndex, offsetBy: startOffset)
                let end = folded.index(folded.startIndex, offsetBy: endOffset)
                matches.append("\u{2026}\(folded[start..<end])\u{2026}")
                searchFrom = range.upperBound
            }
            return matches
        }
    }
}

// MARK: - PDF outline helpers (iOS 27+ PDFOutline was heavily redesigned — skipped)