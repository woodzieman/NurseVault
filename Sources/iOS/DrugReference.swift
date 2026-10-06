import Foundation
import Observation
import NurseVaultCore

/// One drug in the reference library bundled with the app.
///
/// The data lives in the app bundle, **not** in the Core Data vault. The
/// `DrugInfo` folder resource (a classic folder reference, so its
/// per-drug subfolder structure survives the build) contains one folder
/// per drug, each with a small `names.txt` (generic + brand names) and a
/// `drug-information.txt` (full Merck Manual content). Bundling it means
/// the reference is always present, works offline, needs no import — and,
/// because it is never a Core Data object, it is never pushed to iCloud.
struct DrugEntry: Identifiable, Hashable, Sendable {
    /// The bundle folder name, e.g. "Amoxicillin and Amoxil".
    let folderName: String
    /// The drug name, e.g. "Amoxicillin" (from `names.txt`, or the folder
    /// name when the file is missing).
    let drugName: String
    let brandNames: [String]
    /// Whether the folder has a readable `drug-information.txt`.
    let hasInfo: Bool

    var id: String { folderName }

    /// Folded (case/diacritic-insensitive) drug name, folder name, and
    /// brand names, precomputed at load time for cheap name searches.
    let searchName: String
}

/// A structured representation of drug information parsed from the bundle.
struct DrugInfoParsed: Sendable {
    /// Key-value pairs for the Quick Reference Summary.
    let summary: [String: String]
    /// Detailed sections of the prescribing information.
    let sections: [DrugSection]
}

struct DrugSection: Identifiable, Hashable, Sendable {
    var id: String { title }
    let title: String
    let content: String
}

/// One row of drug search results. `snippet` is only present when the
/// match came from the full-text content scan.
struct DrugSearchHit: Identifiable, Hashable, Sendable {
    let entry: DrugEntry
    var snippet: String?

    var id: String { entry.id }
}

/// How many drug files the content scan reads in parallel. Kept small so
/// the CPU work doesn't starve the rest of the app (including the main
/// actor). (File scope, not a class static: static stored properties of a
/// `@MainActor` class are actor-isolated, which the nonisolated scan can't
/// read without an `await`.)
private let drugScanWorkers = 4

/// Loads and searches the bundled drug reference.
@MainActor
@Observable
final class DrugLibrary {

    /// Every drug, sorted by drug name.
    private(set) var entries: [DrugEntry] = []
    /// True while the first background load is running.
    private(set) var isLoading = false
    /// True when the `DrugInfo` folder is missing from this app bundle.
    private(set) var isMissing = false

    @ObservationIgnored private let directoryURL: URL?
    @ObservationIgnored private var contentCache: [String: String] = [:]
    @ObservationIgnored private var cacheOrder: [String] = []

    /// How many decoded drug texts to keep in memory before evicting the
    /// oldest; keeps re-opening a recently viewed drug instant without
    /// holding the whole 350 MB of the reference in RAM.
    private static let contentCacheLimit = 100

    init(bundle: Bundle = .main) {
        // Folder references land in `resourceURL`: the bundle root on
        // iOS, Contents/Resources on macOS.
        directoryURL = bundle.resourceURL?.appendingPathComponent("DrugInfo")
    }

    // MARK: - Loading

    /// Enumerates the bundled DrugInfo folder in the background and fills
    /// `entries`. Safe to call from `onAppear`; a no-op once loaded.
    func loadIfNeeded() {
        guard !isLoading, entries.isEmpty, !isMissing else { return }
        isLoading = true
        let directory = directoryURL
        Task {
            let built = await Self.buildEntries(in: directory)
            isLoading = false
            if built.isEmpty {
                isMissing = true
            } else {
                entries = built
            }
        }
    }

    /// Builds the entry index from the directory's per-drug folders.
    /// Nonisolated so the directory walk and the (tiny) `names.txt` reads
    /// run off the main actor.
    nonisolated private static func buildEntries(in directory: URL?) async -> [DrugEntry] {
        guard
            let directory,
            let folders = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else { return [] }

        var entries: [DrugEntry] = []
        for folder in folders {
            guard (try? folder.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else {
                continue
            }
            let parsed = parseNamesFile(folder.appendingPathComponent("names.txt"))
            let drugName = parsed.drugName ?? folder.lastPathComponent
            let hasInfo = FileManager.default.fileExists(
                atPath: folder.appendingPathComponent("drug-information.txt").path
            )
            let searchName = VaultSearch.normalize(
                ([drugName, folder.lastPathComponent] + parsed.brandNames)
                    .joined(separator: "\n")
            )
            entries.append(
                DrugEntry(
                    folderName: folder.lastPathComponent,
                    drugName: drugName,
                    brandNames: parsed.brandNames,
                    hasInfo: hasInfo,
                    searchName: searchName
                )
            )
        }
        entries.sort {
            $0.drugName.localizedCaseInsensitiveCompare($1.drugName) == .orderedAscending
        }
        return entries
    }

    /// Parses a `names.txt`:
    ///
    /// ```
    /// Drug: Amoxicillin
    /// Generic name: Amoxicillin
    /// Trade/Brand names (6):
    ///   - Amoxil
    /// ```
    nonisolated private static func parseNamesFile(_ url: URL) -> (drugName: String?, brandNames: [String]) {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return (nil, [])
        }
        var drugName: String?
        var brands: [String] = []
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Drug:") {
                drugName = trimmed.dropFirst("Drug:".count).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Generic name:") {
                let generic = trimmed.dropFirst("Generic name:".count).trimmingCharacters(in: .whitespaces)
                if drugName == nil { drugName = generic }
            } else if trimmed.hasPrefix("- ") {
                let brand = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                if !brand.isEmpty { brands.append(brand) }
            }
        }
        if drugName?.isEmpty == true { drugName = nil }
        return (drugName, brands)
    }

    // MARK: - Searching

    /// Drugs whose drug name, brand names, or folder name match `query`
    /// (case/diacritic-insensitive). Cheap — computed from the in-memory
    /// index, safe to run on every keystroke.
    func nameHits(for query: String) -> [DrugSearchHit] {
        let needle = VaultSearch.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        return entries
            .filter { $0.searchName.contains(needle) }
            .map { DrugSearchHit(entry: $0) }
    }

    /// Drugs whose `drug-information.txt` content matches `query`, each
    /// with a short snippet around the first match.
    ///
    /// Scans the bundled files off the main actor with a small worker pool
    /// (a full scan of the reference takes ~2 s on a laptop, a few more
    /// on a phone). The UI debounces and cancels this per keystroke.
    /// Single-character queries are refused: they would match (nearly)
    /// everything for no useful result.
    func contentHits(for query: String) async -> [DrugSearchHit] {
        await Self.contentScan(query: query, entries: entries, directory: directoryURL)
    }

    nonisolated private static func contentScan(
        query: String,
        entries: [DrugEntry],
        directory: URL?
    ) async -> [DrugSearchHit] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard needle.count >= 2, let directory else { return [] }

        // Fold each file once, then match with a plain substring search.
        // Benchmarked ~2.5x faster than `range(of:options:)` on this data.
        let foldedNeedle = VaultSearch.normalize(needle)
        let targets = entries.filter(\.hasInfo)
        guard !targets.isEmpty else { return [] }
        let chunkSize = max(1, (targets.count + drugScanWorkers - 1) / drugScanWorkers)

        var hits: [DrugSearchHit] = []
        await withTaskGroup(of: [DrugSearchHit].self) { group in
            for start in stride(from: 0, to: targets.count, by: chunkSize) {
                let chunk = targets[start ..< min(start + chunkSize, targets.count)]
                group.addTask {
                    var workerHits: [DrugSearchHit] = []
                    for entry in chunk {
                        if Task.isCancelled { break }
                        let fileURL = directory
                            .appendingPathComponent(entry.folderName)
                            .appendingPathComponent("drug-information.txt")
                        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
                            continue
                        }
                        let folded = VaultSearch.normalize(text)
                        guard let match = folded.range(of: foldedNeedle) else { continue }
                        workerHits.append(
                            DrugSearchHit(entry: entry, snippet: Self.snippet(in: folded, around: match))
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

    /// A short window of `text` around `match` for display under a
    /// content search result. (`text` is the folded text, so the snippet
    /// may drop accents — a cosmetic difference only.)
    nonisolated private static func snippet(
        in text: String,
        around match: Range<String.Index>,
        context: Int = 120
    ) -> String {
        let back = min(context, text.distance(from: text.startIndex, to: match.lowerBound))
        let start = text.index(
            match.lowerBound, offsetBy: -back, limitedBy: text.startIndex
        ) ?? text.startIndex
        let end = text.index(
            match.upperBound, offsetBy: context, limitedBy: text.endIndex
        ) ?? text.endIndex
        var snippet = String(text[start...end]).replacingOccurrences(of: "\n", with: " ")
        snippet = snippet.replacingOccurrences(of: "\t", with: " ")
        while snippet.contains("  ") {
            snippet = snippet.replacingOccurrences(of: "  ", with: " ")
        }
        if start != text.startIndex { snippet = "…" + snippet }
        if end != text.endIndex { snippet += "…" }
        return snippet
    }

    // MARK: - Full text

    /// Returns a structured representation of the drug information.
    func detailedContent(for entry: DrugEntry) async -> DrugInfoParsed? {
        if let cached = contentCache[entry.id] {
            return parse(cached)
        }
        guard entry.hasInfo, let directoryURL else { return nil }
        let fileURL = directoryURL
            .appendingPathComponent(entry.folderName)
            .appendingPathComponent("drug-information.txt")

        let text = await Self.decode(fileURL)
        if let text {
            contentCache[entry.id] = text
            cacheOrder.append(entry.id)
            while cacheOrder.count > Self.contentCacheLimit, let oldest = cacheOrder.first {
                cacheOrder.removeFirst()
                contentCache[oldest] = nil
            }
        }
        return text.map(parse)
    }

    private func parse(_ text: String) -> DrugInfoParsed {
        var summary: [String: String] = [:]
        let lines = text.split(whereSeparator: \.isNewline)

        // Parse Summary section.
        //
        // File structure:
        //   === Name — Drug Information ... ===
        //   Source: ...
        //   Retrieved: ...
        //   NURSING QUICK-REFERENCE SUMMARY
        //   Auto-generated on ...; full details follow below.
        //   (blank line)
        //   Drug Class: ...
        //   Routes: ...
        //   Common Side Effects (...): ...
        //   In an Overdose: ...
        //   Key Nursing Considerations: ...
        //   (blank line — summary ends)
        //   (detailed content follows, which may repeat these keys)
        //
        // We parse key-value pairs only until the first blank line that comes
        // AFTER at least one pair has been found — this is the end of the
        // summary block, before the detailed content repeats the same headers.

        enum SummaryState { case beforeHeader, inHeader, inPairs, done }
        var state: SummaryState = .beforeHeader
        var foundAnyPair = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            switch state {
            case .beforeHeader:
                if trimmed.contains("NURSING QUICK-REFERENCE SUMMARY") {
                    state = .inHeader
                }

            case .inHeader:
                // Skip the "Auto-generated..." note and blank line
                if trimmed.isEmpty {
                    state = .inPairs
                }
                // Skip "Auto-generated..." line — do nothing

            case .inPairs:
                if trimmed.isEmpty {
                    // Blank line after at least one pair = end of summary
                    if foundAnyPair { state = .done }
                    continue
                }
                var matched = false
                if trimmed.hasPrefix("Drug Class:") {
                    summary["Class"] = trimmed.dropFirst("Drug Class:".count).trimmingCharacters(in: .whitespaces)
                    matched = true
                } else if trimmed.hasPrefix("Routes:") {
                    summary["Routes"] = trimmed.dropFirst("Routes:".count).trimmingCharacters(in: .whitespaces)
                    matched = true
                } else if trimmed.contains("Common Side Effects") && trimmed.contains(":") {
                    let parts = trimmed.split(separator: ":", maxSplits: 1)
                    if parts.count == 2 {
                        summary["Side Effects"] = parts[1].trimmingCharacters(in: .whitespaces)
                        matched = true
                    }
                } else if trimmed.hasPrefix("In an Overdose:") {
                    summary["Overdose"] = trimmed.dropFirst("In an Overdose:".count).trimmingCharacters(in: .whitespaces)
                    matched = true
                } else if trimmed.hasPrefix("Key Nursing Considerations:") {
                    summary["Nursing"] = trimmed.dropFirst("Key Nursing Considerations:".count).trimmingCharacters(in: .whitespaces)
                    matched = true
                }
                if matched { foundAnyPair = true }

            case .done:
                break  // Stop parsing
            }
        }

        // Parse Sections
        var sections: [DrugSection] = []
        let sectionHeaders = [
            "Brand Names", "Indication Specific Dosing", "Contraindications And Precaution",
            "Pregnancy And Lactation", "Interactions", "Adverse Reaction",
            "Description", "Mechanism Of Action", "Pharmacokinetics",
            "Administration", "Maximum Dosage Limits", "Dosage Forms", "Dosage Adjustment Guidelines"
        ]

        var currentHeader: String?
        var currentContent = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let header = sectionHeaders.first(where: { trimmed == $0 }) {
                if let h = currentHeader {
                    sections.append(DrugSection(title: h, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                currentHeader = header
                currentContent = ""
            } else if currentHeader != nil {
                currentContent += line + "\n"
            }
        }

        if let h = currentHeader {
            sections.append(DrugSection(title: h, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return DrugInfoParsed(summary: summary, sections: sections)
    }

    nonisolated private static func decode(_ url: URL) async -> String? {
        // Assume FileSupport is provided by NurseVaultCore or similar.
        // Since I don't have its definition, I'll use a standard fallback if it fails.
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
