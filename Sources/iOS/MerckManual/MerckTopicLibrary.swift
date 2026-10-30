import Foundation
import Observation
import NurseVaultCore
#if canImport(CommonCrypto)
import CommonCrypto
#endif

/// One medical topic in the bundled Merck Manual reference.
///
/// The data lives in the app bundle, **not** in the Core Data vault. The
/// `MerckTopics` folder resource (a classic folder reference) contains
/// specialty-named subfolders with .txt files. A pre-generated index
/// (`merck_topics_index.json`) provides instant lookup without scanning
/// directories at runtime.
struct MerckTopicEntry: Identifiable, Hashable, Sendable {
    let id: String            // SHA-12 hash of content
    let title: String         // Topic title (file stem)
    let specialty: String     // Top-level specialty
    let subspecialty: String  // Sub-specialty (may be empty)
    let section: String       // "Section: ..." line from file (or "Specialty: X")
    let relativePath: String  // Path within MerckTopics/ bundle
    let file_size: Int
    /// Folded (case/diacritic-insensitive) searchable text: title +
    /// subspecialty + specialty, precomputed at load time.
    let searchName: String

    var displayName: String {
        if !subspecialty.isEmpty {
            return "\(subspecialty): \(title)"
        }
        return title
    }

    var specialtyDisplayName: String {
        specialty
    }
}

/// One row of Merck Manual topic search results.
struct MerckTopicSearchHit: Identifiable, Hashable, Sendable {
    let entry: MerckTopicEntry
    var snippet: String?

    var id: String { entry.id }
}

/// How many topic files the content scan reads in parallel.
private let merckScanWorkers = AppLimits.scanWorkers

/// Loads and searches the bundled Merck Manual medical topics.
@MainActor
@Observable
final class MerckTopicLibrary {

    /// Every topic, sorted by specialty then title.
    private(set) var entries: [MerckTopicEntry] = []
    /// True while the first background load is running.
    private(set) var isLoading = false
    /// True when the MerckTopics folder is missing from this app bundle.
    private(set) var isMissing = false
    /// True when the index file is missing (entries will be built from
    /// directory scan instead).
    private(set) var indexMissing = false

    @ObservationIgnored private let directoryURL: URL?
    @ObservationIgnored private var contentCache: [String: String] = [:]
    @ObservationIgnored private var cacheOrder: [String] = []
    private static let contentCacheLimit = AppLimits.contentCacheLimit

    init(bundle: Bundle = .main) {
        directoryURL = bundle.resourceURL?.appendingPathComponent("MerckTopics")
    }

    // MARK: - Loading

    func loadIfNeeded() {
        guard !isLoading, entries.isEmpty, !isMissing else { return }
        isLoading = true
        let directory = directoryURL
        Task {
            let built = await Self.loadFromIndex(in: directory)
            isLoading = false
            if built.isEmpty {
                isMissing = true
            } else {
                entries = built
            }
        }
    }

    /// Load entries from the pre-generated JSON index.
    nonisolated private static func loadFromIndex(in directory: URL?) async -> [MerckTopicEntry] {
        guard let directory else { return [] }

        let indexPath = directory.appendingPathComponent("merck_topics_index.json")
        if let indexData = try? Data(contentsOf: indexPath),
           let indexObj = try? JSONSerialization.jsonObject(with: indexData) as? [String: Any],
           let entriesArray = indexObj["entries"] as? [[String: Any]] {

            var entries: [MerckTopicEntry] = []
            for item in entriesArray {
                guard let id = item["id"] as? String,
                      let title = item["title"] as? String,
                      let specialty = item["specialty"] as? String,
                      let relativePath = item["relative_path"] as? String,
                      let searchName = item["searchName"] as? String else {
                    continue
                }
                let subspecialty = item["subspecialty"] as? String ?? ""
                let section = item["section"] as? String ?? ""
                let file_size = item["file_size"] as? Int ?? 0

                entries.append(MerckTopicEntry(
                    id: id,
                    title: title,
                    specialty: specialty,
                    subspecialty: subspecialty,
                    section: section,
                    relativePath: relativePath,
                    file_size: file_size,
                    searchName: searchName
                ))
            }

            // Sort by specialty, then title
            entries.sort { a, b in
                if a.specialty == b.specialty {
                    return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
                }
                return a.specialty.localizedCaseInsensitiveCompare(b.specialty) == .orderedAscending
            }
            return entries
        }

        // Fallback: scan the directory (slow but works if index is missing)
        return await directoryScan(in: directory)
    }

    /// Fallback: scan the MerckTopics directory for .txt files.
    nonisolated private static func directoryScan(in directory: URL) async -> [MerckTopicEntry] {
        guard let folders = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var entries: [MerckTopicEntry] = []
        for folder in folders {
            guard (try? folder.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else {
                continue
            }
            let specialty = folder.lastPathComponent

            guard let subFolders = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for subFolder in subFolders {
                guard (try? subFolder.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else {
                    continue
                }
                let subspecialty = subFolder.lastPathComponent

                guard let txtFiles = try? FileManager.default.contentsOfDirectory(
                    at: subFolder,
                    includingPropertiesForKeys: [],
                    options: [.skipsHiddenFiles]
                ) else { continue }

                for txtFile in txtFiles {
                    if txtFile.pathExtension.lowercased() == "txt" {
                        let title = txtFile.deletingPathExtension().lastPathComponent
                        let searchName = VaultSearch.normalize(
                            "\(title) \(subspecialty) \(specialty)"
                        )
                        let pathString = "\(specialty)/\(subspecialty)/\(title).txt"
                        let pathData = pathString.data(using: .utf8) ?? Data()
                        let hashId = pathData.sha1_12()

                        entries.append(MerckTopicEntry(
                            id: hashId,
                            title: title,
                            specialty: specialty,
                            subspecialty: subspecialty,
                            section: "Specialty: \(specialty)",
                            relativePath: pathString,
                            file_size: 0,
                            searchName: searchName
                        ))
                    }
                }
            }
        }

        entries.sort { a, b in
            if a.specialty == b.specialty {
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
            return a.specialty.localizedCaseInsensitiveCompare(b.specialty) == .orderedAscending
        }
        return entries
    }

    // MARK: - Searching

    /// Topics whose title or specialty/subspecialty match `query`
    /// (case/diacritic-insensitive).
    func nameHits(for query: String) -> [MerckTopicSearchHit] {
        let needle = VaultSearch.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        return entries
            .filter { $0.searchName.contains(needle) }
            .map { MerckTopicSearchHit(entry: $0) }
    }

    /// Topics whose .txt content matches `query`, each with a short
    /// snippet around the first match.
    func contentHits(for query: String) async -> [MerckTopicSearchHit] {
        await Self.contentScan(query: query, entries: entries, directory: directoryURL)
    }

    nonisolated private static func contentScan(
        query: String,
        entries: [MerckTopicEntry],
        directory: URL?
    ) async -> [MerckTopicSearchHit] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard needle.count >= 2, let directory else { return [] }

        let foldedNeedle = VaultSearch.normalize(needle)
        let targets = entries
        guard !targets.isEmpty else { return [] }
        let chunkSize = max(1, (targets.count + merckScanWorkers - 1) / merckScanWorkers)

        var hits: [MerckTopicSearchHit] = []
        await withTaskGroup(of: [MerckTopicSearchHit].self) { group in
            for start in stride(from: 0, to: targets.count, by: chunkSize) {
                let chunk = targets[start ..< min(start + chunkSize, targets.count)]
                group.addTask {
                    var workerHits: [MerckTopicSearchHit] = []
                    for entry in chunk {
                        if Task.isCancelled { break }
                        let fileURL = directory
                            .appendingPathComponent(entry.relativePath)
                        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
                            continue
                        }
                        let folded = VaultSearch.normalize(text)
                        guard let match = folded.range(of: foldedNeedle) else { continue }
                        // Convert the match range to integer offsets before passing
                        // across function boundaries. String.Index values are only
                        // valid for the exact string instance they were created on;
                        // under concurrent load (COW buffer aliasing, compiler
                        // specialization), passing them into another function can
                        // trigger a validateCharacterIndex assertion failure.
                        let matchStart = folded.distance(from: folded.startIndex, to: match.lowerBound)
                        let matchEnd = folded.distance(from: folded.startIndex, to: match.upperBound)
                        workerHits.append(
                            MerckTopicSearchHit(
                                entry: entry,
                                snippet: Self.snippet(in: folded, matchStart: matchStart, matchEnd: matchEnd)
                            )
                        )
                    }
                    return workerHits
                }
            }
            for await workerHits in group {
                hits.append(contentsOf: workerHits)
            }
        }
        return hits
    }

    /// A short window of `text` around the matched term for display under a
    /// content search result. Takes integer character offsets (not String.Index)
    /// so it can't trap on cross-boundary index validation failures.
    nonisolated private static func snippet(
        in text: String,
        matchStart: Int,
        matchEnd: Int,
        context: Int = 120
    ) -> String {
        // Derive all indices from this local string instance using integer offsets.
        let startOffset = max(0, matchStart - context)
        let endOffset = min(text.count, matchEnd + context)
        let startIndex = text.index(text.startIndex, offsetBy: startOffset)
        let endIndex = text.index(text.startIndex, offsetBy: endOffset)
        var snippet = String(text[startIndex..<endIndex]).replacingOccurrences(of: "\n", with: " ")
        snippet = snippet.replacingOccurrences(of: "\t", with: " ")
        while snippet.contains("  ") {
            snippet = snippet.replacingOccurrences(of: "  ", with: " ")
        }
        if startIndex != text.startIndex { snippet = "…" + snippet }
        if endIndex != text.endIndex { snippet += "…" }
        return snippet
    }

    // MARK: - Full text

    /// Returns the full text of a topic file, with caching.
    func fullText(for entry: MerckTopicEntry) async -> String? {
        if let cached = contentCache[entry.id] {
            return cached
        }
        guard let directoryURL else { return nil }
        let fileURL = directoryURL.appendingPathComponent(entry.relativePath)

        let text = try? String(contentsOf: fileURL, encoding: .utf8)
        if let text {
            contentCache[entry.id] = text
            cacheOrder.append(entry.id)
            while cacheOrder.count > Self.contentCacheLimit, let oldest = cacheOrder.first {
                cacheOrder.removeFirst()
                contentCache[oldest] = nil
            }
        }
        return text
    }

    /// Returns the topic title extracted from the file header.
    func topicTitle(from text: String) -> String {
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("===") {
                return trimmed
                    .replacingOccurrences(of: "=== ", with: "")
                    .replacingOccurrences(of: " ===", with: "")
            }
        }
        return ""
    }

    /// Returns the specialty path from the file header.
    func topicSection(from text: String) -> String {
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Section:") {
                return trimmed.replacingOccurrences(of: "Section:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        return ""
    }

    /// Group entries by specialty for hierarchical browsing.
    func entriesBySpecialty() -> [String: [MerckTopicEntry]] {
        var groups: [String: [MerckTopicEntry]] = [:]
        for entry in entries {
            groups[entry.specialty, default: []].append(entry)
        }
        // Sort specialty names
        return Dictionary(uniqueKeysWithValues: groups.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending })
    }
}

// MARK: - SHA-1 hash helper (first 12 hex chars)
extension Data {
    /// Returns the first 12 hex characters of a SHA-1 hash.
    func sha1_12() -> String {
        #if canImport(CommonCrypto)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        let cBytes = [UInt8](self)
        cBytes.withUnsafeBytes { ptr in
            _ = CC_SHA1(ptr.baseAddress, CC_LONG(self.count), &hash)
        }
        return String(hash.map { String(format: "%02x", $0) }.joined().prefix(12))
        #else
        return String(format: "%040x", self.hashValue)
        #endif
    }
}
