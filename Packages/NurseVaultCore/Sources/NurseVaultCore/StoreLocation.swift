import Foundation

/// Where the vault's on-disk data lives, shared by every process that
/// reads or writes it (the app, the watch app, the watch widget).
public enum VaultStoreLocation {

    /// The App Group that the watch app and the watch widget share.
    ///
    /// Widget extensions run in their **own** sandbox container — Apple
    /// only guarantees file sharing between an app and an extension when
    /// both are members of the same App Group (see "Developing a
    /// WidgetKit strategy: Store shared data in a group container"). The
    /// watch app writes the summary file into this group container and
    /// the widget reads it from there.
    public static let appGroupID = "group.com.josephwoods.nursevault"

    /// `Application Support/NurseVault`, created on demand.
    nonisolated public static var directory: URL {
        guard let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first else {
            // Fallback to documents directory if Application Support is unavailable
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("NurseVault", isDirectory: true) ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("NurseVault")
        }
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

    /// The directory the summary file lives in.
    ///
    /// On Apple Watch this is the **shared App Group container**, because
    /// the watch app and the widget extension have separate containers of
    /// their own — the only place both are guaranteed to reach. Unsigned
    /// development builds lack the entitlement, so it falls back to the
    /// process's own Application Support directory; in that case the file
    /// is at least consistently located for the writing process, and the
    /// reading process (without the entitlement) gets the same fallback.
    nonisolated public static var directory: URL {
        #if os(watchOS)
        if let group = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: VaultStoreLocation.appGroupID) {
            let directory = group.appendingPathComponent("NurseVault", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
        #endif
        return VaultStoreLocation.directory
    }

    nonisolated public static var fileURL: URL {
        directory.appendingPathComponent("vault-summary.json")
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

/// A structured summary of the vault intended for the watch app.
///
/// The main app writes this once after any change so the watch can display
/// section names, document titles, and MIME types without opening the full
/// Core Data store (which would be empty on the watch since it has its own
/// separate store URL).
public enum WatchVaultSummary {

    /// One document record the watch needs to display the document list.
    public struct DocEntry: Codable, Sendable {
        public var title: String?
        public var fileName: String?
        public var mimeType: String?
        public var noteText: String?
        public var addedDateISO: String?
        public var sectionName: String?
        public var sectionIcon: String?

        public init(
            title: String? = nil,
            fileName: String? = nil,
            mimeType: String? = nil,
            noteText: String? = nil,
            addedDateISO: String? = nil,
            sectionName: String? = nil,
            sectionIcon: String? = nil
        ) {
            self.title = title
            self.fileName = fileName
            self.mimeType = mimeType
            self.noteText = noteText
            self.addedDateISO = addedDateISO
            self.sectionName = sectionName
            self.sectionIcon = sectionIcon
        }
    }

    /// One section record the watch needs.
    public struct SectionEntry: Codable, Sendable {
        public var name: String?
        public var icon: String?

        public init(name: String? = nil, icon: String? = nil) {
            self.name = name
            self.icon = icon
        }
    }

    /// The full watch-friendly summary.
    public struct Snapshot: Codable, Sendable {
        public var sections: [SectionEntry]
        public var documents: [DocEntry]
        public var updatedAt: Date

        public init(sections: [SectionEntry], documents: [DocEntry], updatedAt: Date) {
            self.sections = sections
            self.documents = documents
            self.updatedAt = updatedAt
        }
    }

    /// Directory inside the App Group for watch-specific summaries.
    nonisolated public static var directory: URL {
        #if os(watchOS)
        if let group = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: VaultStoreLocation.appGroupID) {
            let directory = group.appendingPathComponent("NurseVault", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
        #endif
        return VaultStoreLocation.directory
    }

    nonisolated public static var fileURL: URL {
        directory.appendingPathComponent("watch-vault-summary.json")
    }

    nonisolated public static func write(_ snapshot: Snapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    nonisolated public static func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }
}
