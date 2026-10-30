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
/// extracted with PDFKit in the background, cached in memory, and persisted
/// on the document (`extractedText`) so it is not re-extracted on every
/// launch. Searches stay responsive even as the vault grows.
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
        
        // Evict stale entries and prune inflight set
        searchLock.lock()
        defer { searchLock.unlock() }
        for key in searchCache.keys where !liveIDs.contains(key) {
            searchCache[key] = nil
        }
        searchInflight.formIntersection(liveIDs)

        // Process each document with lock held to prevent concurrent modification
        for doc in docs {
            guard let id = doc.cacheID else { continue }
            let fingerprint = VaultSearch.fingerprint(for: doc)
            if let entry = searchCache[id], entry.fingerprint == fingerprint {
                continue
            }

            // Evict oldest entries if cache is full
            evictOldestSearchEntries()

            let kind = DocKind.kind(
                mimeType: doc.mimeType,
                fileName: doc.fileName,
                hasFile: doc.fileData != nil
            )
            switch kind {
            case .text:
                // Text decoding is cheap enough to do inline. When the
                // text was already extracted in a previous run, reuse the
                // persisted copy and skip the decode entirely.
                let content: String
                if let persisted = doc.extractedText, !persisted.isEmpty {
                    content = persisted
                } else {
                    let decoded = VaultSearch.text(from: doc.fileData)
                    if !decoded.isEmpty {
                        persistExtractedText(decoded, for: doc)
                    }
                    content = decoded
                }
                searchCache[id] = SearchEntry(
                    fingerprint: fingerprint,
                    content: VaultSearch.normalize(content)
                )
            case .pdf:
                if let persisted = doc.extractedText, !persisted.isEmpty {
                    // Already extracted in a previous run — seed the cache
                    // from it instead of re-running PDFKit on every launch.
                    searchCache[id] = SearchEntry(
                        fingerprint: fingerprint,
                        content: VaultSearch.normalize(persisted)
                    )
                } else {
                    // Start with an empty entry so metadata search works
                    // immediately; fill in the PDF text in the background.
                    searchCache[id] = SearchEntry(fingerprint: fingerprint, content: "")
                    schedulePDFExtraction(for: doc, id: id, fingerprint: fingerprint)
                }
            case .image, .other, .note:
                searchCache[id] = SearchEntry(fingerprint: fingerprint, content: "")
            }
        }
    }

    /// Evicts oldest entries from the search cache when it exceeds limits.
    /// Must be called with `searchLock` held.
    /// Persists extracted text on the document so a future launch can seed
    /// the search cache without re-extracting (PDFs) or re-decoding.
    /// Saves only when the stored value actually changes, so repeated index
    /// maintenance never triggers sync churn.
    private func persistExtractedText(_ text: String, for doc: VaultDoc) {
        guard (doc.extractedText ?? "") != text else { return }
        doc.extractedText = text
        _ = save()
    }

    /// Evicts oldest entries from the search cache when it exceeds limits.
    /// Must be called with `searchLock` held.
    private func evictOldestSearchEntries() {
        guard searchCache.count > AppLimits.maxSearchCacheEntries else { return }
        
        // Calculate total size
        var totalSize = 0
        for entry in searchCache.values {
            totalSize += entry.content.utf8.count + entry.fingerprint.utf8.count
        }
        
        guard totalSize > AppLimits.maxSearchCacheBytes else { return }
        
        // Evict oldest entries (first inserted) - remove 25% of cache
        let evictionCount = max(searchCache.count / 4, 10)
        let keysToRemove = Array(searchCache.keys.prefix(evictionCount))
        for key in keysToRemove {
            searchCache[key] = nil
        }
    }

    /// Documents whose title, file name, notes, or file content match `query`.
    public func docs(matching query: String) -> [VaultDoc] {
        let needle = VaultSearch.normalize(
            query.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard !needle.isEmpty else { return docs(in: nil as VaultSection?) }

        // Snapshot cache under lock to prevent concurrent modification during search
        var snapshot: [URL: String]
        searchLock.lock()
        snapshot = searchCache.mapValues { $0.content }
        searchLock.unlock()

        var matches: [VaultDoc] = []
        
        // Optimize by checking title/filename first (most likely matches)
        for doc in docs {
            let title = doc.title ?? ""
            let fileName = doc.fileName ?? ""
            
            // Quick check on title and filename without normalization
            if title.localizedCaseInsensitiveContains(query) ||
               fileName.localizedCaseInsensitiveContains(query) {
                matches.append(doc)
                continue
            }
            
            // Fall back to normalized search for content
            var haystack = [title, fileName, doc.noteText ?? ""]
            if let id = doc.cacheID,
               let content = snapshot[id] {
                haystack.append(content)
            }
            let folded = VaultSearch.normalize(haystack.joined(separator: "\n"))
            if folded.range(of: needle) != nil {
                matches.append(doc)
            }
        }
        
        // Sort with priority to title/filename matches
        return matches.sorted { a, b in
            let aTitleMatch = (a.title ?? "").localizedCaseInsensitiveContains(query)
            let bTitleMatch = (b.title ?? "").localizedCaseInsensitiveContains(query)
            if aTitleMatch != bTitleMatch { return aTitleMatch }
            
            let aNameMatch = (a.fileName ?? "").localizedCaseInsensitiveContains(query)
            let bNameMatch = (b.fileName ?? "").localizedCaseInsensitiveContains(query)
            if aNameMatch != bNameMatch { return aNameMatch }
            
            // Fall back to title comparison
            return (a.title ?? "").localizedCompare(b.title ?? "") == .orderedAscending
        }
    }

    private func schedulePDFExtraction(
        for doc: VaultDoc,
        id: URL,
        fingerprint: String
    ) {
        guard
            let data = doc.fileData,
            data.count <= VaultSearch.maxPDFSearchBytes
        else { return }

        // Atomic check-and-insert to prevent duplicate extraction tasks
        searchLock.lock()
        defer { searchLock.unlock() }
        
        guard !searchInflight.contains(id) else { return }
        searchInflight.insert(id)
        
        let dataCopy = data  // Copy data while lock is held
        let fingerprintCopy = fingerprint
        
        Task {
            let extracted = await Task.detached(priority: .utility) {
                VaultSearch.pdfText(from: dataCopy)
            }.value
            
            await MainActor.run {
                self.searchLock.lock()
                self.searchInflight.remove(id)
                guard self.searchCache[id]?.fingerprint == fingerprintCopy else {
                    self.searchLock.unlock()
                    return
                }
                
                // Evict before updating to prevent cache from growing too large
                self.evictOldestSearchEntries()
                self.searchLock.unlock()
                
                self.searchCache[id]?.content = VaultSearch.normalize(extracted)
                if !extracted.isEmpty {
                    self.persistExtractedText(extracted, for: doc)
                }
            }
        }
    }
}
