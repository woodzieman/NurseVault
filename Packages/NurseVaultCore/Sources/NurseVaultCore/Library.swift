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
    public private(set) var docs: [VaultDoc] = []
    public private(set) var syncState: SyncState = .syncing

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

        container.loadPersistentStores { [weak self] _, error in
            if let error {
                NSLog("NurseVault: could not load the local store: \(error.localizedDescription)")
            }
            Task { @MainActor in
                self?.markStoreLoaded()
            }
        }
    }

    private func markStoreLoaded() {
        guard !isStoreLoaded else { return }
        isStoreLoaded = true
        startMonitoring()
        observeSyncEvents()
        refreshAccountStatus()
        reload()
        #if !os(watch)
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

    public func deleteSection(_ section: VaultSection) {
        context.delete(section)
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
        to section: VaultSection?
    ) -> VaultDoc {
        let doc = VaultDoc(context: context)
        doc.title = imported.title
        doc.noteText = noteText
        doc.fileName = imported.fileName
        doc.mimeType = imported.mimeType
        doc.fileData = imported.data
        doc.addedDate = Date()
        doc.section = section
        save()
        reload()
        return doc
    }

    @discardableResult
    public func addNote(title: String, body: String, to section: VaultSection?) -> VaultDoc {
        let doc = VaultDoc(context: context)
        doc.title = title
        doc.noteText = body
        doc.addedDate = Date()
        doc.section = section
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
    public func updateDocument(
        _ doc: VaultDoc,
        title: String? = nil,
        noteText: String? = nil,
        section: VaultSection? = nil
    ) {
        if let title, !title.isEmpty { doc.title = title }
        doc.noteText = noteText
        doc.section = section
        save()
        reload()
    }

    /// Documents in one section, or everything when `section` is nil.
    public func docs(in section: VaultSection?) -> [VaultDoc] {
        let result: [VaultDoc] = section == nil
            ? docs
            : docs.filter { $0.section === section }
        return result.sorted {
            ($0.title ?? "").localizedCompare($1.title ?? "") == .orderedAscending
        }
    }
}
