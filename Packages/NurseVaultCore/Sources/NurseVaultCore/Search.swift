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
    internal func maintainSearchIndex() async {
        let liveIDs = Set(docs.compactMap(\.cacheID))

        // Evict stale entries and prune inflight set.
        pruneSearchIndex(liveIDs: liveIDs)

        // Process each document. CPU-heavy decode/normalization work is handed
        // to a nonisolated async helper so it runs off the main actor; the
        // `searchLock` is held only inside the synchronous cache helpers.
        for doc in docs {
            guard let id = doc.cacheID else { continue }
            let fingerprint = VaultSearch.fingerprint(for: doc)

            if searchCacheIsCurrent(id: id, fingerprint: fingerprint) {
                continue
            }

            let kind = DocKind.kind(
                mimeType: doc.mimeType,
                fileName: doc.fileName,
                hasFile: doc.fileData != nil
            )
            switch kind {
            case .text:
                // When the text was already extracted in a previous run, reuse
                // the persisted copy and skip the decode entirely.
                let persisted = doc.extractedText ?? ""
                let content: String
                if !persisted.isEmpty {
                    content = persisted
                } else {
                    let fileData = doc.fileData
                    let decoded = await Self.decodeTextOffMain(fileData)
                    // The document may have been deleted while the decode was
                    // running off the main actor; don't persist or index it.
                    if !decoded.isEmpty, documentStillExists(id) {
                        persistExtractedText(decoded, for: doc)
                    }
                    content = decoded
                }
                if documentStillExists(id) {
                    let normalized = await Self.normalizeSearchContent(content)
                    setSearchCacheEntry(SearchEntry(fingerprint: fingerprint, content: normalized), for: id)
                }
            case .pdf:
                let persisted = doc.extractedText ?? ""
                if !persisted.isEmpty {
                    // Already extracted in a previous run — seed the cache
                    // from it instead of re-running PDFKit on every launch.
                    let normalized = await Self.normalizeSearchContent(persisted)
                    if documentStillExists(id) {
                        setSearchCacheEntry(SearchEntry(fingerprint: fingerprint, content: normalized), for: id)
                    }
                } else {
                    // Start with an empty entry so metadata search works
                    // immediately; fill in the PDF text in the background.
                    if documentStillExists(id) {
                        setSearchCacheEntry(SearchEntry(fingerprint: fingerprint, content: ""), for: id)
                        schedulePDFExtraction(for: doc, id: id, fingerprint: fingerprint)
                    }
                }
            case .image, .other, .note:
                if documentStillExists(id) {
                    setSearchCacheEntry(SearchEntry(fingerprint: fingerprint, content: ""), for: id)
                }
            }
        }
    }

    /// Runs pure string normalization off the main actor. Called with `await`
    /// from `@MainActor` code so the CPU work happens on the cooperative pool.
    nonisolated private static func normalizeSearchContent(_ content: String) async -> String {
        VaultSearch.normalize(content)
    }

    /// Runs text decoding off the main actor.
    nonisolated private static func decodeTextOffMain(_ data: Data?) async -> String {
        VaultSearch.text(from: data)
    }

    /// Guards against a document being deleted while background work is in flight.
    private func documentStillExists(_ id: URL) -> Bool {
        docs.contains { $0.cacheID == id }
    }

    /// Removes stale cache entries and cancels in-flight extractions.
    private func pruneSearchIndex(liveIDs: Set<URL>) {
        searchLock.lock()
        for key in searchCache.keys where !liveIDs.contains(key) {
            searchCache[key] = nil
        }
        searchInflight.formIntersection(liveIDs)
        // Cancel any extraction still running for a document that's been removed,
        // so its task can't outlive the document and write stale content.
        for (key, task) in inFlightExtractions where !liveIDs.contains(key) {
            task.cancel()
            inFlightExtractions[key] = nil
        }
        searchLock.unlock()
    }

    /// Returns `true` when the cache already has a fresh entry for `id`.
    /// Evicts stale entries when the cache exceeds its limits.
    private func searchCacheIsCurrent(id: URL, fingerprint: String) -> Bool {
        searchLock.lock()
        defer { searchLock.unlock() }
        if let entry = searchCache[id], entry.fingerprint == fingerprint {
            return true
        }
        evictOldestSearchEntries()
        return false
    }

    /// Inserts or replaces a cache entry.
    private func setSearchCacheEntry(_ entry: SearchEntry, for id: URL) {
        searchLock.lock()
        searchCache[id] = entry
        searchLock.unlock()
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

        // Check-and-insert without holding the lock across the whole closure.
        searchLock.lock()
        guard !searchInflight.contains(id) else {
            searchLock.unlock()
            return
        }
        searchInflight.insert(id)
        let dataCopy = data
        searchLock.unlock()

        // Track the task so it can be cancelled if its document is removed
        // before extraction finishes (see maintainSearchIndex).
        let extraction = Task { @MainActor in
            let extracted = await Task.detached(priority: .utility) {
                VaultSearch.pdfText(from: dataCopy)
            }.value
            let normalized = await Task.detached(priority: .utility) {
                VaultSearch.normalize(extracted)
            }.value

            updateSearchCacheAfterPDFExtraction(id: id, fingerprint: fingerprint, content: normalized)

            if !extracted.isEmpty {
                persistExtractedText(extracted, for: doc)
            }
        }

        searchLock.lock()
        inFlightExtractions[id] = extraction
        searchLock.unlock()
    }

    /// Applies a finished PDF extraction to the cache under the search lock.
    private func updateSearchCacheAfterPDFExtraction(id: URL, fingerprint: String, content: String) {
        searchLock.lock()
        searchInflight.remove(id)
        inFlightExtractions[id] = nil
        if let entry = searchCache[id], entry.fingerprint == fingerprint {
            evictOldestSearchEntries()
            searchCache[id]?.content = content
        }
        searchLock.unlock()
    }
}
