import SwiftUI
import NurseVaultCore

struct RootView: View {
    @Environment(Library.self) private var library
    @Environment(DrugLibrary.self) private var drugLibrary
    @Environment(MerckTopicLibrary.self) private var merckLibrary
    @Environment(DsmTopicLibrary.self) private var dsmLibrary
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: SidebarItem?
    @State private var searchManager: UniversalSearchManager? = nil
    /// Local storage for search text to handle the case when searchManager is not yet initialized.
    @State private var localSearchText = ""
    @State private var showingNewSection = false
    @State private var renameTarget: SectionEditTarget?
    @State private var deleteTarget: VaultSection?
    @State private var showingDeleteDialog = false
    @State private var showingResetAlert = false
    @State private var showingSettings = false
    /// Safari-style sidebar toggle: `.all` shows the menu column, `.detailOnly`
    /// hides it so the reference/documents get the full width (landscape
    /// iPhone and iPad).
    @State private var splitVisibility: NavigationSplitViewVisibility = .all
    /// Which column the collapsed (iPhone) split view shows. Driven by the
    /// search query so results appear without touching `selection`.
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    /// The specific item chosen from universal search, opened by its target
    /// detail view (which clears it via `onEntryOpened`). Documents are
    /// resolved and pushed here, since the vault stack lives in RootView.
    @State private var pendingItem: PendingItem?
    /// The vault document stack. Value-based so a document chosen from
    /// universal search can be pushed programmatically.
    @State private var vaultPath: [VaultDocRef] = []
    /// The last document chosen from universal search. Fallback resolution
    /// for OS versions whose SDK can't map a URI back to a managed object.
    @State private var pendingDoc: VaultDoc?
    /// The calculator stack. Value-based so a calculator chosen from
    /// universal search (or a deep link) can be pushed programmatically.
    @State private var calculatorPath: [CalculatorInfo] = []

    /// A specific item chosen from universal search, to be opened by its
    /// reference view when that view appears.
    enum PendingItem: Hashable {
        case drug(DrugEntry)
        case merck(MerckTopicEntry)
        case dsm(DsmTopicEntry)
        case calculator(CalculatorInfo)
        /// Persistent-ID URI of a vault document.
        case document(String)
    }

    enum SidebarItem: Hashable {
        case all
        case section(VaultSection)
        /// The read-only drug reference bundled with the app.
        case drugReference
        /// The read-only Merck Manual medical topics bundled with the app.
        case merckManual
        /// The read-only DSM-5-TR nursing reference bundled with the app.
        case dsmManual
        /// 174 clinical calculators (MedCalc library).
        case mediCalc
        /// Bundled laboratory reference ranges (tables).
        case labs
        /// User-imported books (PDFs, text, RTF).
        case books
        /// Results of the universal search.
        case searchResults
    }

    /// Wrapper so a section can drive a sheet (`item:` requires Identifiable).
    struct SectionEditTarget: Identifiable {
        let id = UUID()
        let section: VaultSection
    }

    var body: some View {
        Group {
            if library.isReady {
                readyContent
            } else {
                loadingView
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Loading Nurse Vault…")
            .scaleEffect(1.2)
            .padding()
    }

    #if DEBUG
    /// DEBUG deep-selection: launch with
    /// `-debugSelect <all|drugs|calculators|merck|dsm|labs>` to jump straight
    /// into a reference, `-debugSearch <text>` to fill the search field,
    /// `-debugSelectResult <text>` to also tap the first result, and
    /// `-hideSidebar` to pre-collapse the menu column —
    /// for headless layout verification on the simulator (no UI scripting).
    /// Inert in Release builds.
    private func maybeApplyDebugSelection() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-hideSidebar") {
            // Assign after the split view has appeared: a synchronous change in
            // onAppear gets overridden by the system's default visibility.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                splitVisibility = .detailOnly
            }
        }
        if let j = args.firstIndex(of: "-debugSearch"), j + 1 < args.count {
            // Delayed: the search manager is created in onAppear, and the
            // text must arrive after it exists to be picked up.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                localSearchText = args[j + 1]
            }
        }
        if let k = args.firstIndex(of: "-debugSelectResult"), k + 1 < args.count {
            // Search, then simulate tapping the first result once the
            // libraries have produced any — verifies the "open the specific
            // item" flow headlessly.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                localSearchText = args[k + 1]
                for _ in 0..<60 {
                    if let first = searchManager?.results.first {
                        handleSearchResultSelection(first)
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
        }
        guard let i = args.firstIndex(of: "-debugSelect"), i + 1 < args.count else { return }
        switch args[i + 1] {
        case "all": selection = .all
        case "drugs": selection = .drugReference
        case "calculators": selection = .mediCalc
        case "merck": selection = .merckManual
        case "dsm": selection = .dsmManual
        case "labs": selection = .labs
        default: break
        }
    }
    #endif

    /// Handles deep links like `nursevault://calculator/<id>` by navigating to
    /// Clinical Calculators and opening the specified calculator.
    private func handleDeeplink(_ url: URL) {
        guard let id = MedCalcDeepLink.calculatorID(from: url),
              let calc = MedCalcCatalog.calculator(withID: id) else { return }
        selection = .mediCalc
        pendingItem = .calculator(calc)
    }

    private var readyContent: some View {
        NavigationSplitView(
            columnVisibility: $splitVisibility,
            preferredCompactColumn: $compactColumn
        ) {
            #if os(iOS)
            // The search field is pinned above the sidebar list. The system
            // `.searchable` field, in the new design, floats in a Liquid
            // Glass container at the *bottom* of the sidebar, where it covers
            // the rows (list text shows through the glass). A pinned field
            // also pairs with the results screen's own field, so typing
            // continues where the keyboard is once results take over.
            VStack(spacing: 10) {
                VaultSearchField(text: $localSearchText)
                sidebarList
            }
            #else
            sidebarList
                .searchable(text: $localSearchText)
            #endif
        } detail: {
            // Two-column split (Safari-style): the reference and vault views
            // own their navigation, so they fill the whole detail column.
            // The old third column was a dead "Select a Document" placeholder
            // that wasted half the screen in landscape.
            if let sm = searchManager, localSearchText.count >= 2 {
            NavigationStack {
                UniversalSearchResultsView(
                    searchText: $localSearchText,
                    results: sm.results,
                    isLoadingLibraries: sm.isLoadingLibraries
                ) { result in
                    handleSearchResultSelection(result)
                }
            }
            } else {
                switch selection {
                case .drugReference:
                    DrugReferenceView(
                        initialEntry: pendingDrug,
                        onEntryOpened: { pendingItem = nil }
                    )
                case .mediCalc:
                    NavigationStack(path: $calculatorPath) {
                        CategoryListView(initialCalculator: pendingCalculator)
                    }
                    .navigationDestination(for: CalculatorInfo.self) { calc in
                        CalculatorDetailView(calculator: calc)
                    }
                case .merckManual:
                    MerckManualView(
                        initialEntry: pendingTopic,
                        onEntryOpened: { pendingItem = nil }
                    )
                case .dsmManual:
                    DsmManualView(
                        initialEntry: pendingDsmTopic,
                        onEntryOpened: { pendingItem = nil }
                    )
                case .labs:
                    LabsView()
                case .books:
                    NavigationStack {
                        BooksView(library: library)
                    }
                case .all, .section(_), .none, .searchResults:
                    NavigationStack(path: $vaultPath) {
                        VaultListView(container: currentContainer)
                    }
                    .navigationDestination(for: VaultDocRef.self) { ref in
                        let doc = library.doc(withPersistentURI: ref.uri)
                            ?? (pendingDoc?.objectID.uriRepresentation().absoluteString == ref.uri
                                ? pendingDoc : nil)
                        if let doc {
                            DocDetailView(doc: doc)
                        } else {
                            ContentUnavailableView(
                                "Document Not Found",
                                systemImage: "doc.questionmark",
                                description: Text("This document may have been deleted.")
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            WatchSyncSettingsView()
        }
        .sheet(isPresented: $showingNewSection) {
            NewSectionView()
        }
        .sheet(item: $renameTarget) { target in
            RenameSectionView(section: target.section)
        }
        .confirmationDialog(
            "Delete “\(deleteTarget?.name ?? "")”?",
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Section and Documents", role: .destructive) {
                if let target = deleteTarget {
                    // Drop the selection first: it holds the section object
                    // about to be deleted, and touching a deleted managed
                    // object (e.g. for the list title) would fault.
                    if selection == .section(target) {
                        selection = .all
                    }
                    library.deleteSection(target)
                }
                deleteTarget = nil
                showingDeleteDialog = false
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
                showingDeleteDialog = false
            }
        } message: {
            Text("This also deletes everything stored in the section.")
        }
        .navigationSplitViewStyle(.balanced)
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        #endif
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await library.reload() }
            }
        }
        .onChange(of: library.storeWasReset) { _, reset in
            if reset {
                showingResetAlert = true
            }
        }
        .alert("Vault Storage Was Reset", isPresented: $showingResetAlert) {
            Button("OK") { }
        } message: {
            Text(
                "The 2.0 version added folders, and its new storage format can't open the previous vault. "
                + "Your vault was re-created, so documents from the earlier alpha build didn't carry over."
            )
        }
        .onAppear {
            #if DEBUG
            maybeApplyDebugSelection()
            #endif
            // Initialize search manager with environment values
            if searchManager == nil {
                searchManager = UniversalSearchManager(
                    library: library,
                    drugLibrary: drugLibrary,
                    merckLibrary: merckLibrary,
                    dsmLibrary: dsmLibrary
                )
            }
        }
        .onChange(of: drugLibrary.isLoading) { _, isLoading in
            // Re-search when drug library finishes loading if user has typed something
            guard !isLoading, searchManager != nil, !localSearchText.isEmpty else { return }
            // Trigger re-search by temporarily clearing and restoring the text
            let query = localSearchText
            localSearchText = ""
            localSearchText = query
        }
        .onChange(of: merckLibrary.isLoading) { _, isLoading in
            // Re-search when Merck library finishes loading if user has typed something
            guard !isLoading, searchManager != nil, !localSearchText.isEmpty else { return }
            // Trigger re-search by temporarily clearing and restoring the text
            let query = localSearchText
            localSearchText = ""
            localSearchText = query
        }
        .onChange(of: dsmLibrary.isLoading) { _, isLoading in
            // Re-search when the DSM library finishes loading if user has typed something
            guard !isLoading, searchManager != nil, !localSearchText.isEmpty else { return }
            let query = localSearchText
            localSearchText = ""
            localSearchText = query
        }
        .onChange(of: localSearchText) { _, newText in
            // Sync local search text with search manager when available
            if let sm = searchManager {
                sm.searchText = newText
            }
            // From 2 characters on, prefer the detail column on iPhone so the
            // results render. `selection` is deliberately left alone: flipping
            // it to .searchResults used to yank the user to the results screen
            // after just two keystrokes, cutting off their typing.
            if newText.count >= 2 {
                compactColumn = .detail
            } else {
                compactColumn = selection == nil ? .sidebar : .detail
            }
        }
        .onChange(of: selection) { _, _ in
            // Choosing a section (or a search result) supersedes the query.
            localSearchText = ""
        }
        .onChange(of: pendingItem) { _, item in
            // Items whose navigation stack lives in RootView are pushed here.
            // (Documents are Core Data objects, so only a URI reference
            // travels; the destination resolves it.)
            guard let item else { return }
            switch item {
            case .document(let uri):
                pendingItem = nil
                vaultPath.append(VaultDocRef(uri: uri))
            case .calculator(let calc):
                pendingItem = nil
                calculatorPath.append(calc)
            default:
                break
            }
        }
        .onChange(of: searchManager?.searchText) { _, newText in
            // Sync back from search manager to local state (for clearing)
            guard let newText else { return }
            if localSearchText != newText {
                localSearchText = newText
            }
        }
        .onOpenURL { url in
            handleDeeplink(url)
        }
    }

    /// The sidebar list of vault sections and bundled references.
    private var sidebarList: some View {
        List(selection: $selection) {
            Label("All Documents", systemImage: "books.vertical")
                .tag(SidebarItem.all)

            Label("Drug Reference", systemImage: "cross.case")
                .badge(drugLibrary.entries.count)
                .tag(SidebarItem.drugReference)

            Label("Clinical Calculators", systemImage: "calculator.fill")
                .badge(MedCalcCatalog.all.count)
                .tag(SidebarItem.mediCalc)

            Label("Merck Manual", systemImage: "book")
                .badge(merckLibrary.entries.count)
                .tag(SidebarItem.merckManual)

            Label("DSM-5-TR", systemImage: "book.fill")
                .badge(dsmLibrary.entries.count)
                .tag(SidebarItem.dsmManual)

            Label("Labs", systemImage: "testtube.2")
                .tag(SidebarItem.labs)

            Label("Books", systemImage: "book.closed.fill")
                .tag(SidebarItem.books)

            ForEach(library.sections, id: \.self) { section in
                Label(section.name ?? "Untitled", systemImage: section.icon ?? "folder")
                    .badge(library.docs(in: section).count)
                    .tag(SidebarItem.section(section))
                    .contextMenu {
                        Button("Rename…") {
                            renameTarget = SectionEditTarget(section: section)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteTarget = section
                            showingDeleteDialog = true
                        }
                    }
            }
            .onMove { library.moveSections(from: $0, to: $1) }
        }
        .navigationTitle("Nurse Vault")
        #if os(iOS)
        // Keep the menu a bounded slice of landscape width so the reference
        // column (and the Safari-style toggle) behave like Safari's.
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        #endif
        .toolbar {
            // Safari-style sidebar toggle: hide the menu for full-width content.
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    splitVisibility = splitVisibility == .detailOnly ? .all : .detailOnly
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .accessibilityLabel("Toggle menu")
            }
            #endif
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            #endif
            #if os(macOS)
            ToolbarItem(placement: .navigation) {
                Button {
                    splitVisibility = splitVisibility == .detailOnly ? .all : .detailOnly
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            #endif
            #if os(macOS)
            ToolbarItem(placement: .navigation) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewSection = true
                } label: {
                    Label("New Section", systemImage: "folder.badge.plus")
                }
                #if os(macOS)
                .keyboardShortcut("N", modifiers: .command)
                #endif
            }
        }
    }

    private func handleSearchResultSelection(_ result: SearchResult) {
        // Open the *specific* item chosen, not just its category root.
        switch result {
        case .drug(let entry):
            selection = .drugReference
            pendingItem = .drug(entry)
        case .topic(let entry):
            selection = .merckManual
            pendingItem = .merck(entry)
        case .dsmTopic(let entry):
            selection = .dsmManual
            pendingItem = .dsm(entry)
        case .calculator(let calc):
            selection = .mediCalc
            pendingItem = .calculator(calc)
        case .document(let doc):
            if let section = doc.section {
                selection = .section(section)
            } else {
                selection = .all
            }
            // Keep the object itself: on OS versions whose SDK can't map a
            // URI back to a managed-object ID, it's the only way to resolve.
            pendingDoc = doc
            pendingItem = .document(doc.objectID.uriRepresentation().absoluteString)
        }
        // Dismiss search UI so the detail view switches to the selected content
        localSearchText = ""
    }

    private var pendingDrug: DrugEntry? {
        guard case .drug(let entry) = pendingItem else { return nil }
        return entry
    }

    private var pendingTopic: MerckTopicEntry? {
        guard case .merck(let entry) = pendingItem else { return nil }
        return entry
    }

    private var pendingDsmTopic: DsmTopicEntry? {
        guard case .dsm(let entry) = pendingItem else { return nil }
        return entry
    }

    private var pendingCalculator: CalculatorInfo? {
        guard case .calculator(let calc) = pendingItem else { return nil }
        return calc
    }

    private var currentSection: VaultSection? {
        switch selection {
        case .all, .none, .drugReference, .merckManual, .dsmManual, .labs, .books, .searchResults:
            return nil
        case .section(let section):
            return section
        case .some(.mediCalc):
            // MediCalc is not a VaultSection, so return nil
            return nil
        }
    }

    private var currentContainer: VaultContainer? {
        // MediCalc selection is handled separately — no VaultContainer needed.
        switch selection {
        case .mediCalc:
            return nil
        default:
            return containerFromSelection()
        }
    }

    private func containerFromSelection() -> VaultContainer? {
        switch selection {
        case .all, .none, .drugReference, .merckManual, .dsmManual, .mediCalc, .labs, .books, .searchResults:
            return nil
        case .section(let section):
            return .section(section)
        }
    }
}

// MARK: - Section management

struct NewSectionView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "folder"

    private let iconChoices = [
        "folder", "cross.vial", "testtube.2", "pills", "syringe",
        "stethoscope", "heart.text.square", "bandage", "book",
        "clock", "bolt", "questionmark.circle"
    ]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Section name", text: $name)
                Picker("Icon", selection: $icon) {
                    ForEach(iconChoices, id: \.self) { symbol in
                        Image(systemName: symbol).tag(symbol)
                    }
                }
                Button("Create Section") {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    library.addSection(name: trimmed, icon: icon)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("New Section")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(width: 400, height: 260)
            #endif
        }
    }
}

// MARK: - Watch Sync Settings

struct WatchSyncSettingsView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Watch Sync") {
                    Text("Choose which sections appear on your Apple Watch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Sections") {
                    ForEach(library.sections, id: \.self) { section in
                        Toggle(isOn: Binding(
                            get: { section.syncToWatch },
                            set: { newValue in
                                section.syncToWatch = newValue
                                _ = library.save()
                                library.writeWatchSummaryForced()
                            }
                        )) {
                            Label(section.name ?? "Untitled", systemImage: section.icon ?? "folder")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct RenameSectionView: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    let section: VaultSection
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Section name", text: $name)
            }
            .navigationTitle("Rename Section")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        library.renameSection(section, to: trimmed)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = section.name ?? ""
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(width: 400, height: 180)
            #endif
        }
    }
}
