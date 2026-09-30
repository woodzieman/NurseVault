import Foundation
#if canImport(PDFKit)
import PDFKit
#endif

/// One document's cached searchable file content, keyed by document ID.
internal struct SearchEntry {
    var fingerprint: String
    var content: String
}

extension VaultDoc {
    /// A lightweight, stable identity used to key the search cache.
    ///
    /// Uses the object ID's URI representation (the persistent-ID
    /// lightweight value was removed from the Core Data API in recent
    /// SDKs). `nil` for unsaved, temporary IDs.
    var cacheID: URL? {
        guard !objectID.isTemporaryID else { return nil }
        return objectID.uriRepresentation()
    }
}

/// Cross-document search.
///
/// Matches on a document's title, file name, and notes — and, for PDFs
/// and text files, on the *content* of the file itself. PDF text is
/// extracted with PDFKit in the background and cached in memory, so
/// searches stay responsive even as the vault grows.
public enum VaultSearch {

    /// The largest PDF we'll extract searchable text from. Bigger files
    /// (usually scans) rarely have a useful text layer anyway.
    public static let maxPDFSearchBytes = 16 * 1024 * 1024

    /// Folds a string so comparisons ignore case and accents.
    public static func normalize(_ string: String) -> String {
        string.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// A cheap identifier of everything that can change in a document.
    /// Used to tell when cached content needs rebuilding.
    public static func fingerprint(for doc: VaultDoc) -> String {
        [
            doc.title ?? "",
            doc.noteText ?? "",
            doc.fileName ?? "",
            doc.addedDate.map { String($0.timeIntervalSince1970) } ?? ""
        ]
        .joined(separator: "\u{1F}")
    }

    /// Decodes a text file's contents for searching.
    nonisolated public static func text(from data: Data?) -> String {
        FileSupport.text(from: data) ?? ""
    }

    /// Extracts all the text in a PDF, page by page.
    nonisolated public static func pdfText(from data: Data) -> String {
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: data) else { return "" }
        let pageLimit = min(document.pageCount, 500)
        var pages: [String] = []
        for index in 0..<pageLimit {
            if let page = document.page(at: index), let text = page.string {
                pages.append(text)
            }
        }
        return pages.joined(separator: "\n")
        #else
        return ""
        #endif
    }
}

extension Library {

    /// Keeps the in-memory search cache in sync with `docs`.
    internal func maintainSearchIndex() {
        let liveIDs = Set(docs.compactMap(\.cacheID))
        for key in searchCache.keys where !liveIDs.contains(key) {
            searchCache[key] = nil
        }
        searchInflight.formIntersection(liveIDs)

        for doc in docs {
            guard let id = doc.cacheID else { continue }
            let fingerprint = VaultSearch.fingerprint(for: doc)
            if let entry = searchCache[id], entry.fingerprint == fingerprint {
                continue
            }

            let kind = DocKind.kind(
                mimeType: doc.mimeType,
                fileName: doc.fileName,
                hasFile: doc.fileData != nil
            )
            switch kind {
            case .text:
                // Text decoding is cheap enough to do inline.
                let content = VaultSearch.normalize(VaultSearch.text(from: doc.fileData))
                searchCache[id] = SearchEntry(fingerprint: fingerprint, content: content)
            case .pdf:
                // Start with an empty entry so metadata search works
                // immediately; fill in the PDF text in the background.
                searchCache[id] = SearchEntry(fingerprint: fingerprint, content: "")
                schedulePDFExtraction(for: doc, id: id, fingerprint: fingerprint)
            case .image, .other, .note:
                searchCache[id] = SearchEntry(fingerprint: fingerprint, content: "")
            }
        }
    }

    /// Documents whose title, file name, notes, or file content match `query`.
    public func docs(matching query: String) -> [VaultDoc] {
        let needle = VaultSearch.normalize(
            query.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard !needle.isEmpty else { return docs(in: nil as VaultSection?) }

        var matches: [VaultDoc] = []
        for doc in docs {
            var haystack = [doc.title ?? "", doc.fileName ?? "", doc.noteText ?? ""]
            if let id = doc.cacheID,
               let content = searchCache[id]?.content {
                haystack.append(content)
            }
            let folded = VaultSearch.normalize(haystack.joined(separator: "\n"))
            if folded.range(of: needle) != nil {
                matches.append(doc)
            }
        }
        return matches.sorted {
            ($0.title ?? "").localizedCompare($1.title ?? "") == .orderedAscending
        }
    }

    private func schedulePDFExtraction(
        for doc: VaultDoc,
        id: URL,
        fingerprint: String
    ) {
        guard
            let data = doc.fileData,
            data.count <= VaultSearch.maxPDFSearchBytes,
            !searchInflight.contains(id)
        else { return }

        searchInflight.insert(id)
        Task {
            let extracted = await Task.detached(priority: .utility) {
                VaultSearch.pdfText(from: data)
            }.value
            self.searchInflight.remove(id)
            guard self.searchCache[id]?.fingerprint == fingerprint else { return }
            self.searchCache[id]?.content = VaultSearch.normalize(extracted)
        }
    }
}
