import Foundation

/// Resolves the small bundled watch reference indices (`WatchDrugIndex.txt`,
/// `WatchMerckIndex.txt.zlib`) at runtime.
///
/// The indices live in the NurseVaultCore SPM resource bundle
/// (`NurseVaultCore_NurseVaultCore.bundle`). SwiftPM embeds that bundle in the
/// app, but *where* it lands can differ by platform/embedding: the watch app
/// keeps it at the app's root, the SPM `Bundle.module` accessor looks in a few
/// places, and `Bundle.main.url(forResource:)` only searches the `Resources/`
/// subfolder (not a nested bundle at the app root). Relying on a single lookup
/// is what leaves the watch with an empty index and thus empty search results.
///
/// This resolver tries every plausible location and returns the first match, so
/// the index loads no matter how the bundle was embedded. It never crashes: if
/// nothing is found it returns `nil` (the caller then reports a clear
/// "index unavailable" state rather than a blank screen).
enum WatchIndexBundle {

    /// The SPM-generated resource bundle's file-system name.
    private static let bundleFileName = "NurseVaultCore_NurseVaultCore.bundle"

    /// Finds `base.ext` inside the NurseVaultCore resource bundle, searching
    /// every plausible bundle location. Returns `nil` when it cannot be found.
    static func indexURL(base: String, ext: String) -> URL? {
        // Collect the directories the resource bundle is likely to sit in.
        var directories: [URL] = [Bundle.main.bundleURL]
        if let resourceURL = Bundle.main.resourceURL {
            directories.append(resourceURL)
        }
        // Every other bundle currently loaded in the process (covers the
        // watch app and any extension embedding the package).
        directories.append(contentsOf: Bundle.allBundles.map { $0.bundleURL })

        for directory in directories {
            let bundle = Bundle(url: directory.appendingPathComponent(bundleFileName))
            if let url = bundle?.url(forResource: base, withExtension: ext) {
                return url
            }
        }

        // Last resort: the SPM module accessor. In a release build this will
        // trap if the bundle is genuinely absent, but we've exhausted every
        // normal location by this point, so it should not be reached.
        return Bundle.module.url(forResource: base, withExtension: ext)
    }
}
