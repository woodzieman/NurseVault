import Foundation
import Observation

/// One drug in the watch-sized reference index.
///
/// This is the watch's drug reference. The **full** prescribing information
/// (352 MB of Merck Manual text) ships only in the iPhone/Mac app, which is
/// far too large for the watch. Instead the watch bundles a compact pipe
/// index (`Resources/WatchDrugIndex.txt`, ~0.4 MB) generated from the same
/// dataset. Each line is `<generic>|<brand1>|<brand2>|<summary>`: the
/// generic name, at most the two most-used brand names, and the nursing
/// drug-class line — the genuinely useful at-a-glance content that fits a
/// watch. (Combination drugs stay whole; each has its own brands and dosing.)
public struct WatchDrugEntry: Identifiable, Hashable, Sendable {
    public let name: String
    public let brands: [String]
    public let summary: String
    /// Folded (case/diacritic-insensitive) name + brands + summary,
    /// precomputed at load time for cheap per-keystroke searches.
    public let search: String

    public var id: String { name }
}

/// Loads and searches the bundled watch-sized drug index.
///
/// Available on every platform the core supports (the index is a plain
/// resource in the package) but only surfaced in the watch app's UI.
@MainActor
@Observable
public final class WatchDrugLibrary {

    /// Every drug, sorted by name.
    public private(set) var entries: [WatchDrugEntry] = []
    /// True while the first background load is running.
    public private(set) var isLoading = false
    /// True when the index resource is missing from this build.
    public private(set) var isMissing = false

    /// Decodes the raw on-disk index (kept private; the public `entries`
    /// add the folded search string).
    private struct RawDrug {
        let name: String
        let brands: [String]
        let summary: String
    }

    public init() {}

    /// Reads the bundled index in the background. Safe to call from `onAppear`
    /// or `.task`; a no-op once loaded.
    public func loadIfNeeded() {
        guard !isLoading, entries.isEmpty, !isMissing else { return }
        isLoading = true
        Task {
            let built = await Self.build()
            isLoading = false
            if built.isEmpty {
                isMissing = true
                #if DEBUG
                NSLog("NurseVault (watch drug): index loaded 0 entries — resource unavailable; search will return nothing.")
                #endif
            } else {
                entries = built
                #if DEBUG
                NSLog("NurseVault (watch drug): index loaded \(built.count) drugs.")
                #endif
            }
        }
    }

    /// Builds the entry list off the main actor. `Bundle.module` is only
    /// valid from the owning module, so the file read is nonisolated but the
    /// text parsing and folding are plain value work.
    ///
    /// Line format (see `scripts/build_drug_guide_watch.py`):
    ///   `<generic>|<brand1>|<brand2>|<summary>`
    /// No brand, generic, or summary contains a pipe, so `maxSplits: 3` yields
    /// exactly four fields; `brand2` is empty for single-brand drugs and we
    /// keep `omittingEmptySubsequences: false` so that empty slot survives.
    nonisolated private static func build() async -> [WatchDrugEntry] {
        guard
            let url = WatchIndexBundle.indexURL(base: "WatchDrugIndex", ext: "txt"),
            let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            #if DEBUG
            NSLog("NurseVault (watch drug): could not locate WatchDrugIndex.txt in any bundle.")
            #endif
            return []
        }

        var entries: [WatchDrugEntry] = []
        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "|", maxSplits: 3, omittingEmptySubsequences: false)
            guard parts.count == 4 else { continue }
            let name = String(parts[0])
            let brand1 = String(parts[1])
            let brand2 = String(parts[2])
            let summary = String(parts[3])
            let brands = [brand1, brand2].filter { !$0.isEmpty }
            let entry = WatchDrugEntry(
                name: name,
                brands: brands,
                summary: summary,
                search: VaultSearch.normalize(
                    ([name] + brands + [summary]).joined(separator: "\n")
                )
            )
            entries.append(entry)
        }
        return entries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Drugs whose name, brand, or quick-reference summary contains `query`
    /// (case/diacritic-insensitive). Entries whose *name* matches are ranked
    /// first, then by name — the result a nurse is usually after floats to the
    /// top even when the match is in the summary text.
    public func search(_ query: String) -> [WatchDrugEntry] {
        let needle = VaultSearch.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        return entries
            .filter { $0.search.contains(needle) }
            .sorted { a, b in
                let aName = VaultSearch.normalize(a.name).contains(needle)
                let bName = VaultSearch.normalize(b.name).contains(needle)
                if aName != bName { return aName }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
    }
}
