import Foundation
import Observation

/// One Merck Manual topic in the watch-sized index.
public struct WatchMerckEntry: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let specialty: String
    public let subspecialty: String
    public let summary: String
    public let search: String

    public var displayName: String {
        if !subspecialty.isEmpty {
            return "\(subspecialty): \(title)"
        }
        return title
    }
}

/// Loads and searches the bundled watch-sized Merck index.
@MainActor
@Observable
public final class WatchMerckLibrary {

    public private(set) var entries: [WatchMerckEntry] = []
    public private(set) var isLoading = false
    public private(set) var isMissing = false

    private struct RawEntry {
        let id: String
        let title: String
        let specialty: String
        let subspecialty: String
        let summary: String
    }

    public init() {}

    public func loadIfNeeded() {
        guard !isLoading, entries.isEmpty, !isMissing else { return }
        isLoading = true
        Task {
            let built = await Self.build()
            isLoading = false
            if built.isEmpty {
                isMissing = true
                #if DEBUG
                NSLog("NurseVault (watch merck): index loaded 0 entries — resource unavailable; search will return nothing.")
                #endif
            } else {
                entries = built
                #if DEBUG
                NSLog("NurseVault (watch merck): index loaded \(built.count) topics.")
                #endif
            }
        }
    }

    nonisolated private static func build() async -> [WatchMerckEntry] {
        // Load compressed pipe-delimited index: id|title|specialty|subspecialty|summary
        guard
            let url = WatchIndexBundle.indexURL(base: "WatchMerckIndex", ext: "txt.zlib"),
            let compressed = try? Data(contentsOf: url)
        else {
            #if DEBUG
            NSLog("NurseVault (watch merck): could not locate WatchMerckIndex.txt.zlib in any bundle.")
            #endif
            return []
        }
        guard let decompressed = try? (compressed as NSData).decompressed(using: .zlib) as Data?, 
              let content = String(data: decompressed, encoding: .utf8)
        else {
            #if DEBUG
            NSLog("NurseVault (watch merck): zlib decompression of the Merck index failed.")
            #endif
            return []
        }

        var entries: [WatchMerckEntry] = []
        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "|", maxSplits: 4, omittingEmptySubsequences: false)
            guard parts.count == 5 else { continue }
            let id = String(parts[0])
            let title = String(parts[1])
            let specialty = String(parts[2])
            let subspecialty = String(parts[3])
            let summary = String(parts[4])
            let entry = WatchMerckEntry(
                id: id,
                title: title,
                specialty: specialty,
                subspecialty: subspecialty,
                summary: summary,
                search: VaultSearch.normalize(
                    ([title, specialty, subspecialty, summary]).joined(separator: "\n")
                )
            )
            entries.append(entry)
        }
        return entries.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func search(_ query: String) -> [WatchMerckEntry] {
        let needle = VaultSearch.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        return entries
            .filter { $0.search.contains(needle) }
            .sorted { a, b in
                let aName = VaultSearch.normalize(a.title).contains(needle)
                let bName = VaultSearch.normalize(b.title).contains(needle)
                if aName != bName { return aName }
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
    }
}
