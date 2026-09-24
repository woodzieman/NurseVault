import Foundation

/// Where the vault's on-disk data lives, shared by every process that
/// reads or writes it (the app, the watch app, the watch widget).
public enum VaultStoreLocation {

    /// `Application Support/NurseVault`, created on demand.
    nonisolated public static var directory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let directory = base.appendingPathComponent("NurseVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// The Core Data store file.
    nonisolated public static var storeURL: URL {
        directory.appendingPathComponent("NurseVault.store")
    }
}

/// The single source of truth for the watch widget's kind string, so the
/// app (which triggers timeline reloads) and the widget itself always agree.
public enum VaultWidget {
    public static let complicationKind = "NurseVaultComplication"
}

/// A tiny JSON summary of the vault that the app writes on every change
/// and the watch widget reads to render its complication.
///
/// A small JSON file is far easier and safer for the widget to consume
/// than opening the full Core Data store from its own process.
public enum VaultSummary {

    public struct Snapshot: Codable, Sendable {
        public var sectionCount: Int
        public var documentCount: Int
        public var updatedAt: Date

        public init(sectionCount: Int, documentCount: Int, updatedAt: Date) {
            self.sectionCount = sectionCount
            self.documentCount = documentCount
            self.updatedAt = updatedAt
        }
    }

    nonisolated public static var fileURL: URL {
        VaultStoreLocation.directory.appendingPathComponent("vault-summary.json")
    }

    nonisolated public static func write(_ snapshot: Snapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Reads the summary, or returns nil when it isn't available yet.
    nonisolated public static func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }
}
