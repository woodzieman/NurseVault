import SwiftUI
import NurseVaultCore

struct RootView: View {
    @Environment(Library.self) private var library
    @Environment(DrugLibrary.self) private var drugLibrary
    @Environment(MerckTopicLibrary.self) private var merckLibrary
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: SidebarItem?
    @State private var showingNewSection = false
    @State private var renameTarget: SectionEditTarget?
    @State private var deleteTarget: VaultSection?
    @State private var showingDeleteDialog = false
    @State private var showingResetAlert = false
    @State private var showingSettings = false

    enum SidebarItem: Hashable {
        case all
        case section(VaultSection)
        /// The read-only drug reference bundled with the app.
        case drugReference
        /// The read-only Merck Manual medical topics bundled with the app.
        case merckManual
        /// 174 clinical calculators (MedCalc library).
        case mediCalc
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

    /// Handles deep links like `nursevault://calculator/<id>` by navigating to Clinical
    /// Calculators and opening the specified calculator.
    private func handleDeeplink(_ url: URL) {
        guard let id = MedCalcDeepLink.calculatorID(from: url),
              MedCalcCatalog.calculator(withID: id) != nil else { return }
        selection = .mediCalc
    }

    private var readyContent: some View {
        NavigationSplitView {
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
            .toolbar {
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
        } content: {
            switch selection {
            case .drugReference:
                DrugReferenceView()
            case .mediCalc:
                NavigationStack {
                    CategoryListView()
                }
            case .merckManual:
                MerckManualView()
            case .all, .section(_), .none:
                NavigationStack {
                    VaultListView(container: currentContainer)
                }
            }
        } detail: {
            ContentUnavailableView {
                Label("Select a Document", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text("Choose a reference from the list.")
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
        .navigationSplitViewColumnWidth(min: 280, ideal: 360, max: 500)
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
        .onOpenURL { url in
            handleDeeplink(url)
        }
    }

    private var currentSection: VaultSection? {
        switch selection {
        case .all, .none, .drugReference, .merckManual:
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
        case .all, .none, .drugReference, .merckManual, .mediCalc:
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
