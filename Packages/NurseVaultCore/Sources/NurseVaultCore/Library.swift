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

    @ObservationIgnored private let container: NSPersistentCloudKitContainer
    @ObservationIgnored private let context: NSManagedObjectContext
    @ObservationIgnored private var pathMonitor: NWPathMonitor?
    @ObservationIgnored private var syncObserver: NSObjectProtocol?
    @ObservationIgnored private var cloudAvailable = false
    @ObservationIgnored private var isOnline = false
    @ObservationIgnored private var isStoreLoaded = false
    @ObservationIgnored var searchCache: [URL: SearchEntry] = [:]
    @ObservationIgnored var searchInflight = Set<URL>()

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
        #endif
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
        let entitlements = Bundle.main.infoDictionary?["Entitlements"] as? [String: Any]
        let services = entitlements?["com.apple.developer.icloud-services"] as? [String] ?? []
        return services.contains("CloudKit")
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

    private func save() {
        guard isStoreLoaded, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            NSLog("NurseVault: save failed: \(error.localizedDescription)")
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
