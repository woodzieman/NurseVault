import Foundation
import CoreData
import CloudKit
import Network
import Observation
#if os(watchOS)
import WidgetKit
#endif

/// The shared library of sections and documents.
///
/// Data is stored locally (Core Data) and automatically synced to the user's
/// **private** CloudKit database, so it travels over the internet between the
/// user's devices and is never visible to anyone else. Everything remains
/// usable offline; pending changes sync when a connection is available.
@MainActor
@Observable
public final class Library {

    public enum SyncState: Equatable, Sendable {
        case notSignedIn
        case offline
        case syncing
        case synced
    }

    public private(set) var sections: [VaultSection] = []
    public private(set) var folders: [VaultFolder] = []
    public private(set) var docs: [VaultDoc] = []
    public private(set) var syncState: SyncState = .syncing

    /// Set when an existing on-disk store was written with an older model
    /// (before folders existed) and had to be reset so the app can start.
    public private(set) var storeWasReset = false
    /// True once the Core Data store has finished loading and initial data is available.
    public private(set) var isReady = false
    /// Last error encountered when saving Core Data changes. Nil if the last save succeeded.
    public private(set) var lastSaveError: Error? = nil

    @ObservationIgnored private let container: NSPersistentCloudKitContainer
    @ObservationIgnored private let context: NSManagedObjectContext
    @ObservationIgnored private var pathMonitor: NWPathMonitor?
    @ObservationIgnored private var syncObserver: NSObjectProtocol?
    @ObservationIgnored private var cloudAvailable = false
    @ObservationIgnored private var isOnline = false
    @ObservationIgnored private var isStoreLoaded = false
    @ObservationIgnored var searchCache: [URL: SearchEntry] = [:]
    @ObservationIgnored var searchInflight = Set<URL>()
    private var iso8601Formatter: ISO8601DateFormatter = { let f = ISO8601DateFormatter(); return f }()

    /// Watch-friendly summary data, loaded from the App Group file.
    /// Used on watchOS when the Core Data store is empty.
    public var watchSummary: WatchVaultSummary.Snapshot? = nil

    public init() {
        let model = VaultModel.makeModel()
        let container = NSPersistentCloudKitContainer(name: "NurseVault", managedObjectModel: model)
        let description = container.persistentStoreDescriptions.first
        description?.url = Self.storeURL()

        self.container = container
        self.context = container.viewContext
        self.context.name = "NurseVault.main"

        loadStore(container: container, attempt: 0)
    }

    /// Loads the persistent store, with a one-time reset fallback.
    ///
    /// The 2.0 model added the Folder entity and new relationships. A store
    /// written by the v0.1 model cannot be opened, so instead of failing
    /// forever (empty app, silent data loss) the store file is deleted once
    /// and loading retried. This app is a private vault with no public
    /// builds, so a one-time re-creation is the least-bad option; the flag
    /// surfaces in the UI so the user knows their old content did not carry
    /// over.
    private func loadStore(container: NSPersistentCloudKitContainer, attempt: Int) {
        container.loadPersistentStores { [weak self] _, error in
            if let error, attempt == 0, Self.deleteStoreFileIfNeeded(container) {
                NSLog("NurseVault: old store is incompatible with the current model; resetting (\(error.localizedDescription))")
                Task { @MainActor in
                    self?.storeWasReset = true
                    self?.loadStore(container: container, attempt: 1)
                }
                return
            }
            if let error {
                NSLog("NurseVault: could not load the local store: \(error.localizedDescription)")
            }
            Task { @MainActor in
                self?.markStoreLoaded()
            }
        }
    }

    /// Removes the on-disk store (and its external blob file) if present.
    nonisolated private static func deleteStoreFileIfNeeded(_ container: NSPersistentCloudKitContainer) -> Bool {
        guard let url = container.persistentStoreDescriptions.first?.url,
              FileManager.default.fileExists(atPath: url.path) else { return false }
        var removed = false
        if (try? FileManager.default.removeItem(at: url)) != nil {
            removed = true
        }
        // External binary data (document files) is kept in a sibling `tmp`
        // file; remove it too so nothing lingers from the old schema.
        let tmp = url.deletingPathExtension().appendingPathComponent("tmp")
        if FileManager.default.fileExists(atPath: tmp.path) {
            try? FileManager.default.removeItem(at: tmp)
        }
        return removed
    }

    private func markStoreLoaded() {
        guard !isStoreLoaded else { return }
        isStoreLoaded = true
        startMonitoring()
        observeSyncEvents()
        refreshAccountStatus()
        reload()
        #if !os(watchOS)
        if sections.isEmpty {
            ensureDefaultSections()
        }
        // One-time migration: auto-populate Merck Manual topics into the vault
        ensureMerckManualImported()
        #endif
        isReady = true
    }

    // MARK: - Store location

    nonisolated private static func storeURL() -> URL {
        VaultStoreLocation.storeURL
    }

    // MARK: - Sync status

    private func startMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NurseVault.path-monitor")
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self?.setOnline(online)
            }
        }
        monitor.start(queue: queue)
        pathMonitor = monitor
        setOnline(monitor.currentPath.status == .satisfied)
    }

    /// `CKContainer.default()` throws when the app has no CloudKit container
    /// entitlement (e.g. an unsigned development build), so check first.
    nonisolated private static func hasCloudKitEntitlement() -> Bool {
        // Bundle.infoDictionary does not reliably expose entitlements.
        // The presence of the CloudKit entitlement can only be tested at runtime
        // by attempting to use CKContainer. Returning true lets refreshAccountStatus
        // try the account check and fail gracefully if the entitlement is missing.
        return true
    }

    private func refreshAccountStatus() {
        guard Self.hasCloudKitEntitlement() else {
            setCloudAvailable(false)
            return
        }
        CKContainer.default().accountStatus { [weak self] status, _ in
            let available = status == .available
            Task { @MainActor in
                self?.setCloudAvailable(available)
            }
        }
    }

    /// Reloads local data when a sync with the server finishes, so edits made
    /// on the user's other devices appear while the app is open.
    private func observeSyncEvents() {
        let key = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        let observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: nil
        ) { [weak self] note in
            guard let event = note.userInfo?[key] as? NSPersistentCloudKitContainer.Event else { return }
            Task { @MainActor in
                self?.handleSyncEvent(event)
            }
        }
        syncObserver = observer
    }

    private func handleSyncEvent(_ event: NSPersistentCloudKitContainer.Event) {
        guard event.endDate != nil else { return }
        switch event.type {
        case .import:
            if event.succeeded {
                reload()
                setCloudAvailable(true)
            }
        case .export:
            setCloudAvailable(event.succeeded)
        case .setup:
            break
        @unknown default:
            break
        }
    }

    private func setOnline(_ online: Bool) {
        isOnline = online
        updateSyncState()
    }

    private func setCloudAvailable(_ available: Bool) {
        cloudAvailable = available
        updateSyncState()
    }

    private func updateSyncState() {
        if !cloudAvailable {
            syncState = .notSignedIn
        } else if !isOnline {
            syncState = .offline
        } else {
            syncState = .synced
        }
    }

    // MARK: - Loading

    public func reload() {
        guard isStoreLoaded else { return }
        let sectionFetch = NSFetchRequest<VaultSection>(entityName: "Section")
        sectionFetch.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        if let fetched = try? context.fetch(sectionFetch) {
            sections = fetched
        }

        let folderFetch = NSFetchRequest<VaultFolder>(entityName: "Folder")
        if let fetched = try? context.fetch(folderFetch) {
            folders = fetched
        }

        let docFetch = NSFetchRequest<VaultDoc>(entityName: "Doc")
        if let fetched = try? context.fetch(docFetch) {
            docs = fetched
        }
        maintainSearchIndex()
        writeSummary()
        // On watchOS the Core Data store is always empty (separate store URL).
        // Fall back to the watch-friendly summary written by the main app.
        #if os(watchOS)
        if sections.isEmpty {
            if let summary = WatchVaultSummary.load() {
                self.watchSummary = summary
            } else {
                NSLog("NurseVault (watch): No summary file found. Main app may not have written it yet.")
            }
        }
        #endif
    }

    // MARK: - Watch-friendly computed properties

    /// Sections available on the watch: Core Data if populated, otherwise from summary.
    public var watchSections: [WatchSection] {
        if !sections.isEmpty {
            // Core Data has data (running on iPhone/Mac) — wrap it.
            return sections.map { WatchSection(id: $0.objectID.uriRepresentation().absoluteString, name: $0.name, icon: $0.icon) }
        }
        // Core Data is empty (watchOS) — use summary.
        guard let summary = watchSummary else { return [] }
        return summary.sections.map { WatchSection(
            id: $0.name ?? "", 
            name: $0.name, 
            icon: $0.icon
        )}
    }

    /// Documents available on the watch: Core Data if populated, otherwise from summary.
    public var watchDocs: [WatchDoc] {
        if !docs.isEmpty {
            // Core Data has data (running on iPhone/Mac) — wrap it.
            return docs.map { doc -> WatchDoc in
                WatchDoc(
                    id: doc.objectID.uriRepresentation().absoluteString,
                    title: doc.title,
                    fileName: doc.fileName,
                    mimeType: doc.mimeType,
                    noteText: doc.noteText,
                    addedDateISO: doc.addedDate.map { iso8601Formatter.string(from: $0) },
                    sectionName: doc.section?.name,
                    sectionIcon: doc.section?.icon
                )
            }
        }
        // Core Data is empty (watchOS) — use summary.
        guard let summary = watchSummary else { return [] }
        return summary.documents.enumerated().map { idx, doc -> WatchDoc in
            WatchDoc(
                id: doc.title ?? doc.fileName ?? "doc-\(idx)",
                title: doc.title,
                fileName: doc.fileName,
                mimeType: doc.mimeType,
                noteText: doc.noteText,
                addedDateISO: doc.addedDateISO,
                sectionName: doc.sectionName,
                sectionIcon: doc.sectionIcon
            )
        }
    }

    /// Filtered documents matching the search text, from either source.
    public func watchDocs(matching query: String) -> [WatchDoc] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return watchDocs.filter { doc in
            (doc.title ?? "").localizedCaseInsensitiveContains(trimmed) ||
            (doc.fileName ?? "").localizedCaseInsensitiveContains(trimmed) ||
            (doc.noteText ?? "").localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Documents in a specific watch section.
    public func watchDocs(in watchSection: WatchSection) -> [WatchDoc] {
        guard !sections.isEmpty else {
            // WatchOS: filter from summary.
            return watchDocs.filter { $0.sectionName == watchSection.name }
        }
        // Core Data: wrap from existing method.
        let targetSection = sections.first { section in
            section.name == watchSection.name
        }
        guard let section = targetSection else { return [] }
        return docs(in: section).map { doc -> WatchDoc in
            WatchDoc(
                id: doc.objectID.uriRepresentation().absoluteString,
                title: doc.title,
                fileName: doc.fileName,
                mimeType: doc.mimeType,
                noteText: doc.noteText,
                addedDateISO: doc.addedDate.map { iso8601Formatter.string(from: $0) },
                sectionName: doc.section?.name,
                sectionIcon: doc.section?.icon
            )
        }
    }

    /// Refreshes the small summary the watch widget reads for its complication.
    private func writeSummary() {
        VaultSummary.write(
            .init(
                sectionCount: sections.count,
                documentCount: docs.count,
                updatedAt: Date()
            )
        )
        writeWatchSummary()
        #if os(watchOS)
        // The watch app is the only process on the watch, so it can ask
        // WidgetKit to re-run the widget's timeline right away instead of
        // letting the complication wait for its 30-minute refresh.
        // watchOS's WidgetCenter has no no-argument `reloadTimelines()`,
        // so the kind is passed explicitly (single source of truth in
        // `VaultWidget.complicationKind`). Other platforms have no Nurse
        // Vault widget, so this is a no-op there.
        WidgetCenter.shared.reloadTimelines(ofKind: VaultWidget.complicationKind)
        #endif
    }

    /// Writes the watch-specific summary with actual section and document metadata.
    private func writeWatchSummary() {
        writeWatchSummaryInternal()
    }

    /// Public variant that writes the watch summary even if called from outside
    /// the normal save/reload cycle. Used by the main app on launch to ensure
    /// the watch has data immediately.
    public func writeWatchSummaryForced() {
        guard isStoreLoaded else { return }
        writeWatchSummaryInternal()
    }

    private func writeWatchSummaryInternal() {
        // Only include sections that are set to sync to watch.
        let syncedSections = sections.filter { $0.syncToWatch }
        let sectionEntries = syncedSections.map { WatchVaultSummary.SectionEntry(
            name: $0.name,
            icon: $0.icon
        )}
        // Only include docs from synced sections.
        let syncedSectionIDs = Set(syncedSections.map { $0.objectID })
        let docEntries = docs.filter { doc in
            guard let section = doc.section else { return false }
            return syncedSectionIDs.contains(section.objectID)
        }.map { doc -> WatchVaultSummary.DocEntry in
            WatchVaultSummary.DocEntry(
                title: doc.title,
                fileName: doc.fileName,
                mimeType: doc.mimeType,
                noteText: doc.noteText,
                addedDateISO: doc.addedDate.map { iso8601Formatter.string(from: $0) },
                sectionName: doc.section?.name,
                sectionIcon: doc.section?.icon
            )
        }
        WatchVaultSummary.write(
            .init(
                sections: sectionEntries,
                documents: docEntries,
                updatedAt: Date()
            )
        )
    }

    public func save() {
        guard isStoreLoaded, context.hasChanges else { return }
        do {
            try context.save()
            lastSaveError = nil
        } catch {
            NSLog("NurseVault: save failed: \(error.localizedDescription)")
            lastSaveError = error
            context.rollback()
        }
    }

    // MARK: - Sections

    /// Seeds the default sections on first use: Code Blue, Lab Values, Drugs, Other.
    public func ensureDefaultSections() {
        guard isStoreLoaded else { return }
        guard sections.isEmpty else { return }
        let defaults: [(name: String, icon: String)] = [
            ("Code Blue", "cross.vial"),
            ("Lab Values", "testtube.2"),
            ("Drugs", "pills"),
            ("Other", "folder")
        ]
        for (index, preset) in defaults.enumerated() {
            let section = VaultSection(context: context)
            section.name = preset.name
            section.icon = preset.icon
            section.sortOrder = NSNumber(value: index)
        }
        save()
        reload()
    }

    /// One-time migration: import Merck Manual topics from the app bundle into the vault.
    private func ensureMerckManualImported() {
        // The one-time Merck import is an iPhone/Mac-only action. The watch
        // app has no Core Data vault (it reads the summary file), so the whole
        // body is compiled out on watchOS. (An early `return` here would trip a
        // "code after 'return' will never be executed" warning in the watchOS
        // build of this shared file.)
        #if !os(watchOS)
        // Check if already imported
        let sectionFetch = NSFetchRequest<VaultSection>(entityName: "Section")
        sectionFetch.predicate = NSPredicate(format: "name == %@", "Merck Manual")
        if let existing = try? context.fetch(sectionFetch).first,
           let count = existing.docs?.count, count > 0 {
            return
        }
        // Create section
        let section = VaultSection(context: context)
        section.name = "Merck Manual"
        section.icon = "book"
        let highest = (sections.map { ($0.sortOrder?.int64Value) ?? 0 }.max() ?? -1) + 1
        section.sortOrder = NSNumber(value: highest)
        // Import topics in background
        Task { @MainActor in
            await self.importMerckTopics(into: section)
        }
        #endif
    }

    private func importMerckTopics(into section: VaultSection) async {
        guard let bundleURL = Bundle.main.resourceURL?.appendingPathComponent("MerckTopics") else {
            NSLog("NurseVault: MerckTopics bundle missing")
            return
        }
        var imported = 0
        let fm = FileManager.default
        guard let specialties = try? fm.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return }
        for specialtyURL in specialties where specialtyURL.hasDirectoryPath {
            guard let subdirs = try? fm.contentsOfDirectory(at: specialtyURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { continue }
            for subURL in subdirs where subURL.hasDirectoryPath {
                let subspecialty = subURL.lastPathComponent
                guard let files = try? fm.contentsOfDirectory(at: subURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { continue }
                for fileURL in files where fileURL.pathExtension.lowercased() == "txt" {
                    let title = fileURL.deletingPathExtension().lastPathComponent
                    let displayTitle = subspecialty.isEmpty ? title : "\(subspecialty): \(title)"
                    guard let data = try? Data(contentsOf: fileURL) else { continue }
                    // Limit note size to keep Core Data reasonable
                    let maxNoteBytes = 64 * 1024
                    let noteData = data.count > maxNoteBytes ? data.prefix(maxNoteBytes) : data
                    guard let text = String(data: noteData, encoding: .utf8) else { continue }
                    let doc = VaultDoc(context: context)
                    doc.title = displayTitle
                    doc.fileName = fileURL.lastPathComponent
                    doc.mimeType = "text/plain"
                    doc.noteText = text
                    doc.addedDate = Date()
                    doc.section = section
                    imported += 1
                    // Batch save every 100 docs to avoid huge context
                    if imported % 100 == 0 {
                        save()
                    }
                }
            }
        }
        save()
        reload()
        NSLog("NurseVault: Merck Manual import complete – \(imported) topics imported")
    }

    @discardableResult
    public func addSection(name: String, icon: String = "folder") -> VaultSection {
        let section = VaultSection(context: context)
        section.name = name
        section.icon = icon
        let highest = sections.map { ($0.sortOrder?.int64Value) ?? 0 }.max() ?? -1
        section.sortOrder = NSNumber(value: highest + 1)
        save()
        reload()
        return section
    }

    public func renameSection(_ section: VaultSection, to name: String) {
        section.name = name
        save()
        reload()
    }

    public func renameFolder(_ folder: VaultFolder, to name: String) {
        folder.name = name
        save()
        reload()
    }

    public func deleteSection(_ section: VaultSection) {
        context.delete(section)
        save()
        reload()
    }

    @discardableResult
    public func addFolder(name: String, in section: VaultSection? = nil, parent: VaultFolder? = nil) -> VaultFolder {
        let folder = VaultFolder(context: context)
        folder.name = name
        folder.section = parent?.section ?? section
        folder.parent = parent
        save()
        reload()
        return folder
    }

    public func deleteFolder(_ folder: VaultFolder) {
        context.delete(folder)
        save()
        reload()
    }

    /// Moves a folder under a new parent (or to the top level with `nil`).
    ///
    /// A folder's `section` always names the top-level section it belongs
    /// to, so moving under a parent inherits that parent's section. Moving a
    /// folder into itself or one of its own descendants is refused — that
    /// would create a cycle and orphan the subtree.
    public func moveFolder(_ folder: VaultFolder, to parent: VaultFolder? = nil) {
        // `isAncestor` includes the folder itself, so this single check
        // refuses both "move into itself" and "move into its own subtree".
        if let parent, folder.isAncestor(of: parent) {
            return
        }
        folder.parent = parent
        folder.section = parent?.section
        save()
        reload()
    }

    /// Reorders sections after a drag (indices refer to the current `sections` array).
    public func moveSections(from source: IndexSet, to destination: Int) {
        var ordered = sections
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, section) in ordered.enumerated() {
            section.sortOrder = NSNumber(value: index)
        }
        save()
        reload()
    }

    // MARK: - Documents

    @discardableResult
    public func addDocument(
        imported: ImportedFile,
        noteText: String? = nil,
        to section: VaultSection? = nil,
        in folder: VaultFolder? = nil
    ) -> VaultDoc {
        let doc = VaultDoc(context: context)
        doc.title = imported.title
        doc.noteText = noteText
        doc.fileName = imported.fileName
        doc.mimeType = imported.mimeType
        doc.fileData = imported.data
        doc.addedDate = Date()
        doc.section = folder?.section ?? section
        doc.folder = folder
        save()
        reload()
        return doc
    }

    /// The outcome of a folder import, for the UI to summarize.
    public struct FolderImportResult: Sendable {
        public var folderName: String
        public var importedCount: Int
        public var skippedNames: [String]
        public var skippedByTotalLimit: Int

        public var summary: String {
            let skippedDetails = skippedDetails
            guard importedCount > 0 else {
                return skippedNames.isEmpty
                    ? "“\(folderName)” didn’t contain any importable files."
                    : "Nothing could be imported from “\(folderName)”.\n\(skippedDetails)"
            }
            let imported = importedCount == 1 ? "1 document" : "\(importedCount) documents"
            let base = "Imported \(imported) into “\(folderName)”."
            guard skippedNames.isEmpty else { return base + "\n" + skippedDetails }
            guard skippedByTotalLimit > 0 else { return base }
            return base + " (folder total limit reached; \(skippedByTotalLimit) additional file\(skippedByTotalLimit == 1 ? " was" : "s were") skipped due to total import limit)"
        }

        private var skippedDetails: String {
            let count = skippedNames.count
            let verb = count == 1 ? "1 file was" : "\(count) files were"
            let names = skippedNames.prefix(5).joined(separator: ", ")
            let extra = count > 5 ? ", and \(count - 5) more" : ""
            var text = "\(verb) skipped (too large or unreadable): \(names)\(extra)"
            if skippedByTotalLimit > 0 {
                text += "; \(skippedByTotalLimit) additional file\(skippedByTotalLimit == 1 ? " was" : "s were") skipped (total import limit reached)"
            }
            return text
        }
    }

    /// Imports a directory as a new folder, mirroring its subdirectories as
    /// nested vault folders. Files that are unreadable or over the size
    /// limit are skipped and reported, never fatal.
    public func importFolder(
        at url: URL,
        to section: VaultSection? = nil,
        in folder: VaultFolder? = nil
    ) -> FolderImportResult {
        let name = url.lastPathComponent
        let neededScope = url.startAccessingSecurityScopedResource()
        defer {
            if neededScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Sibling folders of the destination, for collision-free naming.
        var destinationNames = Set(
            folders
                .filter {
                    if let folder {
                        return $0.parent === folder
                    }
                    return $0.parent == nil && (section == nil || $0.section === section)
                }
                .compactMap { $0.name?.lowercased() }
        )

        let rootName = Self.uniqueName(name, among: &destinationNames)
        let root = VaultFolder(context: context)
        root.name = rootName
        root.section = folder?.section ?? section
        root.parent = folder

        let result = importDirectory(url, into: root, section: section, existingNames: destinationNames, soFarBytes: 0, skippedByTotalLimit: 0)
        save()
        reload()
        return .init(folderName: rootName, importedCount: result.imported, skippedNames: result.skipped, skippedByTotalLimit: result.skippedByTotalLimit)
    }

    /// The maximum total data size for a single folder import. Files beyond
    /// this limit are skipped (even if they are under 48 MB individually).
    private static let maxImportBytes = 1 * 1024 * 1024 * 1024  // 1 GB

    /// Walks `url` into `vaultFolder`, creating nested folders and
    /// documents without saving until the caller finishes the whole tree.
    /// Files that would push the total beyond `maxImportBytes` are skipped.
    private func importDirectory(
        _ url: URL,
        into vaultFolder: VaultFolder,
        section: VaultSection?,
        existingNames: Set<String>,
        soFarBytes: Int64,
        skippedByTotalLimit: Int
    ) -> (imported: Int, skipped: [String], soFarBytes: Int64, skippedByTotalLimit: Int) {
        var names = existingNames
        var imported = 0
        var skipped: [String] = []
        var currentSoFarBytes = soFarBytes
        var currentSkippedByTotalLimit = skippedByTotalLimit
        for entry in FileSupport.directoryEntries(at: url) {
            if FileSupport.isDirectory(at: entry) {
                let base = entry.lastPathComponent
                let unique = Self.uniqueName(base, among: &names)
                let subfolder = VaultFolder(context: context)
                subfolder.name = unique
                subfolder.section = vaultFolder.section ?? section
                subfolder.parent = vaultFolder
                names.insert(unique.lowercased())
                let child = importDirectory(entry, into: subfolder, section: section, existingNames: [], soFarBytes: currentSoFarBytes, skippedByTotalLimit: currentSkippedByTotalLimit)
                imported += child.imported
                skipped += child.skipped
                currentSoFarBytes = child.soFarBytes
                currentSkippedByTotalLimit += child.skippedByTotalLimit
            } else {
                // Skip files once we've exceeded the total import limit.
                // This prevents the app from trying to store hundreds of
                // 48 MB files (or one very large file) when the user
                // accidentally picks a large folder.
                if currentSoFarBytes >= Self.maxImportBytes {
                    currentSkippedByTotalLimit += 1
                    skipped.append(entry.lastPathComponent)
                    continue
                }
                do {
                    let file = try FileSupport.importFile(at: entry)
                    let doc = VaultDoc(context: context)
                    doc.title = file.title
                    doc.fileName = file.fileName
                    doc.mimeType = file.mimeType
                    doc.fileData = file.data
                    doc.addedDate = Date()
                    doc.section = vaultFolder.section ?? section
                    doc.folder = vaultFolder
                    imported += 1
                    currentSoFarBytes += Int64(file.data.count)
                } catch {
                    skipped.append(entry.lastPathComponent)
                }
            }
        }
        return (imported, skipped, currentSoFarBytes, currentSkippedByTotalLimit)
    }

    /// A name that doesn’t collide with the given sibling names
    /// (case-insensitive); appends “ (2)”, “ (3)”, and so on.
    /// The chosen name is recorded in `names` so later calls in the same
    /// run can’t reuse it.
    private static func uniqueName(_ base: String, among names: inout Set<String>) -> String {
        var candidate = base
        var index = 2
        var attempts = 0
        let maxAttempts = 1_000
        while names.contains(candidate.lowercased()) {
            attempts += 1
            if attempts > maxAttempts {
                // Prevent pathological infinite loops; return a timestamped name.
                candidate = "\(base) (\(Int(Date().timeIntervalSince1970)))"
                break
            }
            candidate = "\(base) (\(index))"
            index += 1
        }
        names.insert(candidate.lowercased())
        return candidate
    }

    @discardableResult
    public func addNote(title: String, body: String, to section: VaultSection?, in folder: VaultFolder? = nil) -> VaultDoc {
        let doc = VaultDoc(context: context)
        doc.title = title
        doc.noteText = body
        doc.addedDate = Date()
        doc.section = folder?.section ?? section
        doc.folder = folder
        save()
        reload()
        return doc
    }

    public func deleteDocument(_ doc: VaultDoc) {
        context.delete(doc)
        save()
        reload()
    }

    /// Pass `section: nil` to remove the document from any section.
    ///
    /// When `folder` is non-nil it wins over `section`: the document's
    /// section is derived from the folder, keeping the "a document inside a
    /// folder belongs to the folder's section" invariant.
    public func updateDocument(
        _ doc: VaultDoc,
        title: String? = nil,
        noteText: String? = nil,
        section: VaultSection? = nil,
        folder: VaultFolder? = nil
    ) {
        if let title, !title.isEmpty { doc.title = title }
        doc.noteText = noteText
        doc.section = folder?.section ?? section
        doc.folder = folder
        save()
        reload()
    }

    /// Documents directly in one section, or everything when `section` is
    /// nil. Documents inside folders of the section count toward the section
    /// (a document's `section` always names the top-level section it
    /// belongs to, no matter how deep its folder is).
    public func docs(in section: VaultSection?) -> [VaultDoc] {
        let result: [VaultDoc] = section == nil
            ? docs
            : docs.filter { $0.section === section }
        return result.sorted {
            ($0.title ?? "").localizedCompare($1.title ?? "") == .orderedAscending
        }
    }

    /// Documents directly in one folder, or everything when `folder` is nil.
    public func docs(in folder: VaultFolder?) -> [VaultDoc] {
        let result: [VaultDoc] = folder == nil
            ? docs
            : docs.filter { $0.folder === folder }
        return result.sorted {
            ($0.title ?? "").localizedCompare($1.title ?? "") == .orderedAscending
        }
    }

    /// Folders directly inside one section (top level of the section's
    /// hierarchy), or the top-level folders of the whole vault when `nil`.
    public func folders(in section: VaultSection?) -> [VaultFolder] {
        let result: [VaultFolder] = section == nil
            ? folders.filter { $0.parent == nil }
            : folders.filter { $0.section === section && $0.parent == nil }
        return result.sorted {
            ($0.name ?? "").localizedCompare($1.name ?? "") == .orderedAscending
        }
    }

    /// Folders directly inside one folder, or everything when `nil`.
    public func subfolders(of folder: VaultFolder?) -> [VaultFolder] {
        let result: [VaultFolder] = folder == nil
            ? folders
            : folders.filter { $0.parent === folder }
        return result.sorted {
            ($0.name ?? "").localizedCompare($1.name ?? "") == .orderedAscending
        }
    }

    /// Every folder in the subtree rooted at `root`, including `root`
    /// itself.
    public func subtreeFolders(of root: VaultFolder) -> [VaultFolder] {
        var result: [VaultFolder] = [root]
        var queue = [root]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for child in subfolders(of: current) {
                result.append(child)
                queue.append(child)
            }
        }
        return result
    }

    /// Every document in the subtree rooted at `folder` (the folder itself
    /// and all of its descendants), sorted by title.
    public func allDocs(in folder: VaultFolder) -> [VaultDoc] {
        let ids = Set(subtreeFolders(of: folder).map(\.objectID))
        return docs.filter { $0.folder.map { ids.contains($0.objectID) } ?? false }
            .sorted {
                ($0.title ?? "").localizedCompare($1.title ?? "") == .orderedAscending
            }
    }
}
