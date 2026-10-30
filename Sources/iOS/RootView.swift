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
    /// into a reference, and `-hideSidebar` to pre-collapse the menu column —
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

    /// Handles deep links like `nursevault://calculator/<id>` by navigating to Clinical
    /// Calculators and opening the specified calculator.
    private func handleDeeplink(_ url: URL) {
        guard let id = MedCalcDeepLink.calculatorID(from: url),
              MedCalcCatalog.calculator(withID: id) != nil else { return }
        selection = .mediCalc
    }

    private var readyContent: some View {
        NavigationSplitView(columnVisibility: $splitVisibility) {
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
            .searchable(text: $localSearchText)
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
        } detail: {
            // Two-column split (Safari-style): the reference and vault views
            // own their navigation, so they fill the whole detail column.
            // The old third column was a dead "Select a Document" placeholder
            // that wasted half the screen in landscape.
            if let sm = searchManager, !localSearchText.isEmpty {
            NavigationStack {
                UniversalSearchResultsView(
                    results: sm.results,
                    isLoadingLibraries: sm.isLoadingLibraries
                ) { result in
                    handleSearchResultSelection(result)
                }
            }
            } else {
                switch selection {
                case .drugReference:
                    DrugReferenceView()
                case .mediCalc:
                    NavigationStack {
                        CategoryListView()
                    }
                case .merckManual:
                    MerckManualView()
                case .dsmManual:
                    DsmManualView()
                case .labs:
                    LabsView()
                case .books:
                    NavigationStack {
                        BooksView(library: library)
                    }
                case .all, .section(_), .none, .searchResults:
                    NavigationStack {
                        VaultListView(container: currentContainer)
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
                library.reload()
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
            // While searching, point the split-view selection at the
            // `.searchResults` bucket (a non-nil value) so iPhone's compact
            // layout renders the search results in the detail column instead of
            // hiding them until a category is tapped.
            selection = newText.isEmpty ? selection : .searchResults
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

    private func handleSearchResultSelection(_ result: SearchResult) {
        switch result {
        case .drug:
            selection = .drugReference
        case .topic:
            selection = .merckManual
        case .dsmTopic:
            selection = .dsmManual
        case .calculator(let calc):
            selection = .mediCalc
            if let url = URL(string: "nursevault://calculator/\(calc.id)") {
                handleDeeplink(url)
            }
        case .document(let doc):
            if let section = doc.section {
                selection = .section(section)
            } else {
                selection = .all
            }
        }
        // Dismiss search UI so the detail view switches to the selected content
        localSearchText = ""
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
