import SwiftUI
import NurseVaultCore

struct RootView: View {
    @Environment(Library.self) private var library
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: SidebarItem? = .all
    @State private var showingNewSection = false
    @State private var renameTarget: SectionEditTarget?
    @State private var deleteTarget: VaultSection?
    @State private var showingDeleteDialog = false

    enum SidebarItem: Hashable {
        case all
        case section(VaultSection)
    }

    /// Wrapper so a section can drive a sheet (`item:` requires Identifiable).
    struct SectionEditTarget: Identifiable {
        let id = UUID()
        let section: VaultSection
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("All Documents", systemImage: "books.vertical")
                    .tag(SidebarItem.all)

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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewSection = true
                    } label: {
                        Label("New Section", systemImage: "folder.badge.plus")
                    }
                }
            }
        } content: {
            NavigationStack {
                DocListView(section: currentSection)
            }
        } detail: {
            ContentUnavailableView {
                Label("Select a Document", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text("Choose a reference from the list.")
            }
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                library.reload()
            }
        }
    }

    private var currentSection: VaultSection? {
        switch selection {
        case .all, .none:
            return nil
        case .section(let section):
            return section
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
