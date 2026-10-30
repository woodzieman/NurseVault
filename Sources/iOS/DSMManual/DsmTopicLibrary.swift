import Foundation
import Observation
import NurseVaultCore

/// One DSM-5-TR nursing topic in the bundled reference.
struct DsmTopicEntry: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let code: String
    let specialty: String
    let subspecialty: String
    let section: String
    let relativePath: String
    let file_size: Int
    let searchName: String

    var displayName: String { title }
}

/// One row of DSM-5-TR topic search results.
struct DsmTopicSearchHit: Identifiable, Hashable, Sendable {
    let entry: DsmTopicEntry
    var snippet: String?

    var id: String { entry.id }
}

/// Loads and searches the bundled DSM-5-TR nursing reference.
@MainActor
@Observable
final class DsmTopicLibrary {

    /// Every DSM-5-TR topic, sorted by specialty then title.
    private(set) var entries: [DsmTopicEntry] = []
    /// True while the first background load is running.
    private(set) var isLoading = false
    /// True when the DSM5TR folder is missing from this build.
    private(set) var isMissing = false

    @ObservationIgnored private let directoryURL: URL?
    @ObservationIgnored private var contentCache: [String: String] = [:]
    @ObservationIgnored private var cacheOrder: [String] = []
    private static let contentCacheLimit = AppLimits.contentCacheLimit

    init(bundle: Bundle = .main) {
        directoryURL = bundle.resourceURL?.appendingPathComponent("DSM5TR")
    }

    // MARK: - Loading

    func loadIfNeeded() {
        guard !isLoading, entries.isEmpty, !isMissing else { return }
        isLoading = true
        let directory = directoryURL
        Task {
            let built = await Self.buildIndex(directory: directory)
            isLoading = false
            if built.isEmpty {
                isMissing = true
                #if DEBUG
                NSLog("NurseVault (dsm): index loaded 0 entries — resource unavailable; search will return nothing.")
                #endif
            } else {
                entries = built
                #if DEBUG
                NSLog("NurseVault (dsm): loaded \(built.count) DSM-5-TR entries.")
                #endif
            }
        }
    }

    nonisolated private static func buildIndex(directory: URL?) async -> [DsmTopicEntry] {
        guard let directory else { return [] }
        let indexPath = directory.appendingPathComponent("dsm5tr_index.json")
        if let indexData = try? Data(contentsOf: indexPath),
           let indexObj = try? JSONSerialization.jsonObject(with: indexData) as? [String: Any],
           let entriesArray = indexObj["entries"] as? [[String: Any]] {

            var entries: [DsmTopicEntry] = []
            for item in entriesArray {
                guard let id = item["id"] as? String,
                      let title = item["title"] as? String,
                      let code = item["code"] as? String else { continue }
                let specialty = item["specialty"] as? String ?? ""
                let subspecialty = item["subspecialty"] as? String ?? ""
                let section = item["section"] as? String ?? ""
                let relativePath = item["relative_path"] as? String ?? "\(id).txt"
                let file_size = item["file_size"] as? Int ?? 0
                let searchName = item["searchName"] as? String ?? "\(title) \(specialty) \(subspecialty)"

                entries.append(DsmTopicEntry(
                    id: id,
                    title: title,
                    code: code,
                    specialty: specialty,
                    subspecialty: subspecialty,
                    section: section,
                    relativePath: relativePath,
                    file_size: file_size,
                    searchName: searchName
                ))
            }

            entries.sort { a, b in
                if a.specialty == b.specialty {
                    return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
                }
                return a.specialty.localizedCaseInsensitiveCompare(b.specialty) == .orderedAscending
            }
            return entries
        }

        // Fallback: scan the DSM5TR directory for flat *.txt files.
        return await Self.directoryScan(in: directory)
    }

    /// Fallback directory scan — flat layout: one .txt per DSM-5-TR disorder.
    nonisolated private static func directoryScan(in directory: URL) async -> [DsmTopicEntry] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var entries: [DsmTopicEntry] = []
        for file in files where file.pathExtension.lowercased() == "txt" {
            let title = file.deletingPathExtension().lastPathComponent
            let idData = title.data(using: .utf8) ?? Data()
            entries.append(DsmTopicEntry(
                id: String(idData.sha1_12()),
                title: title,
                code: "",
                specialty: "DSM-5-TR",
                subspecialty: "",
                section: "",
                relativePath: file.lastPathComponent,
                file_size: 0,
                searchName: VaultSearch.normalize("\(title) DSM-5-TR")
            ))
        }
        entries.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        return entries
    }

    // MARK: - Search

    func nameHits(for query: String) -> [DsmTopicSearchHit] {
        let needle = VaultSearch.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        return entries
            .filter { $0.searchName.contains(needle) }
            .map { DsmTopicSearchHit(entry: $0) }
    }

    func contentHits(for query: String) async -> [DsmTopicSearchHit] {
        await Self.contentScan(query: query, entries: entries, directory: directoryURL)
    }

    nonisolated private static func contentScan(
        query: String,
        entries: [DsmTopicEntry],
        directory: URL?
    ) async -> [DsmTopicSearchHit] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard needle.count >= 2, let directory else { return [] }
        let foldedNeedle = VaultSearch.normalize(needle)
        guard !foldedNeedle.isEmpty else { return [] }
        guard !entries.isEmpty else { return [] }

        let chunkSize = max(1, (entries.count + AppLimits.scanWorkers - 1) / AppLimits.scanWorkers)
        var hits: [DsmTopicSearchHit] = []
        await withTaskGroup(of: [DsmTopicSearchHit].self) { group in
            for start in stride(from: 0, to: entries.count, by: chunkSize) {
                let chunk = entries[start ..< min(start + chunkSize, entries.count)]
                group.addTask {
                    var workerHits: [DsmTopicSearchHit] = []
                    for entry in chunk {
                        if Task.isCancelled { break }
                        let fileURL = directory.appendingPathComponent(entry.relativePath)
                        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
                        let folded = VaultSearch.normalize(text)
                        guard let range = folded.range(of: foldedNeedle) else { continue }
                        let matchStart = folded.distance(from: folded.startIndex, to: range.lowerBound)
                        let matchEnd = folded.distance(from: folded.startIndex, to: range.upperBound)
                        workerHits.append(DsmTopicSearchHit(
                            entry: entry,
                            snippet: Self.snippet(in: folded, matchStart: matchStart, matchEnd: matchEnd)
                        ))
                    }
                    return workerHits
                }
            }
            for await workerHits in group { hits.append(contentsOf: workerHits) }
        }
        return hits
    }

    nonisolated private static func snippet(in text: String, matchStart: Int, matchEnd: Int, context: Int = 120) -> String {
        let startOffset = max(0, matchStart - context)
        let endOffset = min(text.count, matchEnd + context)
        let startIndex = text.index(text.startIndex, offsetBy: startOffset)
        let endIndex = text.index(text.startIndex, offsetBy: endOffset)
        var snippet = String(text[startIndex..<endIndex]).replacingOccurrences(of: "\n", with: " ")
        snippet = snippet.replacingOccurrences(of: "\t", with: " ")
        while snippet.contains("  ") { snippet = snippet.replacingOccurrences(of: "  ", with: " ") }
        if startIndex != text.startIndex { snippet = "…" + snippet }
        if endIndex != text.endIndex { snippet += "…" }
        return snippet
    }

    // MARK: - Full text

    func fullText(for entry: DsmTopicEntry) async -> String? {
        if let cached = contentCache[entry.id] { return cached }
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

    // MARK: - Grouping

    func entriesBySpecialty() -> [String: [DsmTopicEntry]] {
        var groups: [String: [DsmTopicEntry]] = [:]
        for entry in entries {
            groups[entry.specialty, default: []].append(entry)
        }
        return Dictionary(uniqueKeysWithValues: groups.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending })
    }
}

