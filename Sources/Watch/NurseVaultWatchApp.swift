import SwiftUI
import NurseVaultCore

@main
struct NurseVaultWatchApp: App {
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(library)
                .onAppear {
                    // On watchOS, Core Data store is separate and always empty.
                    // We rely on the JSON summary written by the main app.
                    // Try loading it immediately; if not available yet, show
                    // a helpful message rather than an empty list.
                    library.reload()
                }
        }
    }
}

// MARK: - Home: the sections

/// A non-document destination for the watch home screen.
enum WatchHomeDestination: Hashable {
    case search
    case drugReference
    case merckReference
}

struct WatchHomeView: View {
    @Environment(Library.self) private var library
    
    /// Whether the watch has synced data from the main app.
    private var hasSyncedData: Bool {
        !library.watchSections.isEmpty || !library.watchDocs.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                // Sync status indicator
                Section {
                    HStack {
                        Image(systemName: library.syncState == .synced ? "icloud.checkmark" : 
                              library.syncState == .offline ? "icloud.slash" : 
                              "icloud")
                            .foregroundStyle(library.syncState == .synced ? .green : 
                                           library.syncState == .offline ? .orange : .blue)
                        Text(syncStatusText)
                    }
                }

                Button(action: {
                    library.reload()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                NavigationLink(value: WatchHomeDestination.search) {
                    Label("Search", systemImage: "magnifyingglass")
                }

                NavigationLink(value: WatchHomeDestination.drugReference) {
                    Label("Drug Reference", systemImage: "pills")
                }

                NavigationLink(value: WatchHomeDestination.merckReference) {
                    Label("Merck Manual", systemImage: "book")
                }

                if !library.watchSections.isEmpty {
                    ForEach(library.watchSections) { watchSection in
                        NavigationLink(value: watchSection) {
                            Label(watchSection.name ?? "Untitled", systemImage: watchSection.icon ?? "folder")
                        }
                    }
                } else {
                    Section {
                        Text("No sections yet. Add documents on your iPhone or Mac.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Nurse Vault")
            .navigationDestination(for: WatchSection.self) { watchSection in
                WatchDocListView(watchSection: watchSection)
            }
            .navigationDestination(for: WatchHomeDestination.self) { destination in
                switch destination {
                case .search:
                    WatchSearchView()
                case .drugReference:
                    WatchDrugReferenceView()
                case .merckReference:
                    WatchMerckReferenceView()
                }
            }
        }
    }
    
    private var syncStatusText: String {
        switch library.syncState {
        case .synced:
            return "Synced"
        case .offline:
            return "Offline - using cached data"
        case .notSignedIn:
            return "Not signed in to iCloud"
        case .syncing:
            return "Syncing..."
        }
    }
}

// MARK: - Documents in a section

struct WatchDocListView: View {
    @Environment(Library.self) private var library
    let watchSection: WatchSection

    @State private var searchText = ""

    private var visibleDocs: [WatchDoc] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return library.watchDocs(in: watchSection)
        }
        return library.watchDocs(matching: trimmed).filter { $0.sectionName == watchSection.name }
    }

    var body: some View {
        List {
            Section {
                TextField("Search \(watchSection.name ?? "this section")", text: $searchText)
                    .autocorrectionDisabled()
            }
            Section {
                ForEach(visibleDocs) { doc in
                    NavigationLink(value: doc) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.title ?? doc.fileName ?? "Untitled")
                            if let dateStr = doc.addedDateISO {
                                Text(dateStr)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(watchSection.name ?? "Documents")
        .navigationDestination(for: WatchDoc.self) { doc in
            WatchDocDetailView(doc: doc)
        }
        .overlay {
            if visibleDocs.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Documents" : "No Matches",
                    systemImage: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass",
                    description: Text(
                        searchText.isEmpty
                            ? "Add documents to \(watchSection.name ?? "this section") on your iPhone or Mac."
                            : "Nothing matches “\(searchText)” in this section."
                    )
                )
            }
        }
    }
}

// MARK: - Search across all sections

struct WatchSearchView: View {
    @Environment(Library.self) private var library

    @State private var searchText = ""

    private var visibleDocs: [WatchDoc] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return library.watchDocs(matching: trimmed)
    }

    var body: some View {
        List {
            Section {
                TextField("Search all documents", text: $searchText)
                    .autocorrectionDisabled()
            }
            ForEach(visibleDocs) { doc in
                NavigationLink(value: doc) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.title ?? doc.fileName ?? "Untitled")
                        Text(doc.sectionNameForDisplay)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationDestination(for: WatchDoc.self) { doc in
            WatchDocDetailView(doc: doc)
        }
        .overlay {
            if visibleDocs.isEmpty && !searchText.isEmpty {
                let noneSynced = library.watchDocs.isEmpty
                ContentUnavailableView(
                    noneSynced ? "No Documents Yet" : "No Matches",
                    systemImage: noneSynced ? "icloud.slash" : "magnifyingglass",
                    description: Text(
                        noneSynced
                            ? "Nothing is synced to this watch yet. Add documents on your iPhone, then let it sync."
                            : "Nothing matches “\(searchText)”. Try different keywords."
                    )
                )
            }
        }
    }
}

// MARK: - Document detail (from summary metadata)

struct WatchDocDetailView: View {
    let doc: WatchDoc

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Show notes if present (watch summary includes note text)
                if let note = doc.noteText, !note.isEmpty {
                    Text(note)
                        .font(.body)
                } else if let mimeType = doc.mimeType, mimeType.hasPrefix("text/") {
                    // For text files, we can't show content without the actual file data
                    VStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Text File")
                            .font(.headline)
                        Text(doc.fileName ?? "unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("View on your iPhone or Mac to see the full content.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if let mimeType = doc.mimeType, mimeType.hasPrefix("image/") {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Image File")
                            .font(.headline)
                        Text(doc.fileName ?? "unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("View on your iPhone or Mac to see the image.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if let mimeType = doc.mimeType, mimeType == "application/pdf" {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.richtext")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("PDF File")
                            .font(.headline)
                        Text(doc.fileName ?? "unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("View on your iPhone or Mac to read the PDF.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // For other file types
                    VStack(spacing: 4) {
                        Image(systemName: "doc")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Document")
                            .font(.headline)
                        Text(doc.fileName ?? "unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("View on your iPhone or Mac to open this file.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    if let title = doc.title, !title.isEmpty {
                        Text("Title: \(title)")
                            .font(.caption)
                    }
                    if let fileName = doc.fileName, !fileName.isEmpty {
                        Text("File: \(fileName)")
                            .font(.caption)
                    }
                    if let sectionName = doc.sectionName,
                       !sectionName.isEmpty,
                       sectionName != "Uncategorized" {
                        Text("Section: \(sectionName)")
                            .font(.caption)
                    }
                    if let dateStr = doc.addedDateISO, !dateStr.isEmpty {
                        Text("Added: \(dateStr)")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(doc.title ?? doc.fileName ?? "Untitled")
    }
}

/// Specialized image view for the Apple Watch that supports zooming with the Digital Crown
/// and panning via drag gestures.
struct WatchZoomableImageView: View {
    let data: Data
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                if scale <= 1.0 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                    )
                    .focusable()
                    // Map crown rotation to scale (1x to 4x)
                    .digitalCrownRotation($scale, from: 1.0, through: 4.0, by: 0.1)
            } else {
                Text("No image preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        // Keep a reasonable aspect ratio to avoid filling the whole screen vertically in the ScrollView
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Specialized PDF view for the Apple Watch that supports zooming with the Digital Crown
/// and panning via drag gestures.
struct WatchZoomablePDFView: View {
    let data: Data
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            VaultPDFView(data: data)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                            if scale <= 1.0 {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                )
                .focusable()
                // Map crown rotation to scale (1x to 4x)
                .digitalCrownRotation($scale, from: 1.0, through: 4.0, by: 0.1)
        }
        // Set a fixed height to allow the ScrollView to work normally and avoid layout loops
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
