import Foundation
import CoreData

/// A named reference section (e.g. "Code Blue", "Lab Values", "Drugs", "Other").
/// New sections can be created at any time from the app.
public final class VaultSection: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var icon: String?
    @NSManaged public var sortOrder: NSNumber?
    @NSManaged public var syncToWatch: Bool
    @NSManaged public var folders: Set<VaultFolder>?
    @NSManaged public var docs: Set<VaultDoc>?
}

/// A folder for grouping documents or other folders.
public final class VaultFolder: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var section: VaultSection?
    @NSManaged public var parent: VaultFolder?
    @NSManaged public var folders: Set<VaultFolder>?
    @NSManaged public var docs: Set<VaultDoc>?
}

/// A stored reference document (a file) or a free-text note.
public final class VaultDoc: NSManagedObject {
    @NSManaged public var title: String?
    @NSManaged public var noteText: String?
    @NSManaged public var fileName: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var fileData: Data?
    @NSManaged public var addedDate: Date?
    @NSManaged public var section: VaultSection?
    @NSManaged public var folder: VaultFolder?
}

// MARK: - Watch Display Types

/// A simple value type for displaying section info on the watch (from summary).
public struct WatchSection: Identifiable, Hashable {
    public let id: String
    public var name: String?
    public var icon: String?

    public init(id: String, name: String?, icon: String?) {
        self.id = id
        self.name = name
        self.icon = icon
    }
}

/// A simple value type for displaying document info on the watch (from summary).
/// Does NOT contain fileData (too large for watch), only metadata.
public struct WatchDoc: Identifiable, Hashable {
    public let id: String
    public var title: String?
    public var fileName: String?
    public var mimeType: String?
    public var noteText: String?
    public var addedDateISO: String?
    public var sectionName: String?
    public var sectionIcon: String?

    /// The resolved section name from the document, for display.
    public var sectionNameForDisplay: String {
        sectionName ?? "Uncategorized"
    }

    public init(
        id: String,
        title: String?,
        fileName: String?,
        mimeType: String?,
        noteText: String?,
        addedDateISO: String?,
        sectionName: String?,
        sectionIcon: String?
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.mimeType = mimeType
        self.noteText = noteText
        self.addedDateISO = addedDateISO
        self.sectionName = sectionName
        self.sectionIcon = sectionIcon
    }
}

extension VaultFolder {
    /// True when this folder is `other`, or sits somewhere on `other`'s
    /// parent chain (i.e. this folder is an ancestor of `other`).
    public func isAncestor(of other: VaultFolder) -> Bool {
        var current: VaultFolder? = other
        while let folder = current {
            if folder === self { return true }
            current = folder.parent
        }
        return false
    }

    /// True when this folder is `other`, or lives inside `other`'s subtree
    /// (i.e. this folder is a descendant of `other`).
    public func isDescendant(of other: VaultFolder) -> Bool {
        other.isAncestor(of: self)
    }

    /// The folder's full path from its top-level section, e.g.
    /// "Drugs / Antibiotics / Red labels". Folders at the top level show
    /// just their own name.
    public var pathComponents: [String] {
        var names = [name ?? "Untitled"]
        var current: VaultFolder? = parent
        while let folder = current {
            names.append(folder.name ?? "Untitled")
            current = folder.parent
        }
        return names.reversed()
    }

    /// A displayable path such as "Drugs / Antibiotics", including the
    /// containing section when known.
    public var pathLabel: String {
        var parts = pathComponents
        if let sectionName = section?.name, !sectionName.isEmpty {
            parts.insert(sectionName, at: 0)
        }
        return parts.joined(separator: " / ")
    }
}

/// Builds the Core Data model in code.
public enum VaultModel {

    public static func makeModel() -> NSManagedObjectModel {
        func attribute(
            _ name: String,
            _ type: NSAttributeType,
            configure: (NSAttributeDescription) -> Void = { _ in }
        ) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = true
            configure(attribute)
            return attribute
        }

        // --- Section Entity ---
        let sectionEntity = NSEntityDescription()
        sectionEntity.name = "Section"
        sectionEntity.managedObjectClassName = NSStringFromClass(VaultSection.self)
        sectionEntity.properties = [
            attribute("name", .stringAttributeType),
            attribute("icon", .stringAttributeType),
            attribute("sortOrder", .integer64AttributeType),
            {
                let attr = NSAttributeDescription()
                attr.name = "syncToWatch"
                attr.attributeType = .booleanAttributeType
                attr.isOptional = false
                attr.defaultValue = true
                return attr
            }()
        ]

        // --- Folder Entity ---
        let folderEntity = NSEntityDescription()
        folderEntity.name = "Folder"
        folderEntity.managedObjectClassName = NSStringFromClass(VaultFolder.self)
        folderEntity.properties = [
            attribute("name", .stringAttributeType)
        ]

        // --- Doc Entity ---
        let docEntity = NSEntityDescription()
        docEntity.name = "Doc"
        docEntity.managedObjectClassName = NSStringFromClass(VaultDoc.self)
        docEntity.properties = [
            attribute("title", .stringAttributeType),
            attribute("noteText", .stringAttributeType),
            attribute("fileName", .stringAttributeType),
            attribute("mimeType", .stringAttributeType),
            attribute("addedDate", .dateAttributeType),
            attribute("fileData", .binaryDataAttributeType) { $0.allowsExternalBinaryDataStorage = true }
        ]

        // --- Relationships ---
        //
        // Every relationship must be explicitly added to its destination
        // entity's properties below. Core Data <= 26 silently adopted a
        // relationship that only appeared as another relationship's inverse;
        // Core Data 27 does not, and an orphaned inverse (e.g. the missing
        // `parent`) crashes the app at store load (EXC_BAD_ACCESS in
        // NSSQLEntity _generateProperties) on first launch.

        // Section <-> Folder
        let sectionFoldersRel = NSRelationshipDescription()
        sectionFoldersRel.name = "folders"
        sectionFoldersRel.destinationEntity = folderEntity
        sectionFoldersRel.maxCount = 0
        sectionFoldersRel.isOptional = true
        sectionFoldersRel.deleteRule = .cascadeDeleteRule

        let folderSectionRel = NSRelationshipDescription()
        folderSectionRel.name = "section"
        folderSectionRel.destinationEntity = sectionEntity
        folderSectionRel.maxCount = 1
        folderSectionRel.isOptional = true
        folderSectionRel.deleteRule = .nullifyDeleteRule

        folderSectionRel.inverseRelationship = sectionFoldersRel
        sectionFoldersRel.inverseRelationship = folderSectionRel

        // Folder <-> Folder (Nested)
        let folderFoldersRel = NSRelationshipDescription()
        folderFoldersRel.name = "folders"
        folderFoldersRel.destinationEntity = folderEntity
        folderFoldersRel.maxCount = 0
        folderFoldersRel.isOptional = true
        folderFoldersRel.deleteRule = .cascadeDeleteRule

        let folderParentRel = NSRelationshipDescription()
        folderParentRel.name = "parent"
        folderParentRel.destinationEntity = folderEntity
        folderParentRel.maxCount = 1
        folderParentRel.isOptional = true
        folderParentRel.deleteRule = .nullifyDeleteRule

        folderParentRel.inverseRelationship = folderFoldersRel
        folderFoldersRel.inverseRelationship = folderParentRel

        // Section <-> Doc
        let sectionDocsRel = NSRelationshipDescription()
        sectionDocsRel.name = "docs"
        sectionDocsRel.destinationEntity = docEntity
        sectionDocsRel.maxCount = 0
        sectionDocsRel.isOptional = true
        sectionDocsRel.deleteRule = .cascadeDeleteRule

        let docSectionRel = NSRelationshipDescription()
        docSectionRel.name = "section"
        docSectionRel.destinationEntity = sectionEntity
        docSectionRel.maxCount = 1
        docSectionRel.isOptional = true
        docSectionRel.deleteRule = .nullifyDeleteRule

        docSectionRel.inverseRelationship = sectionDocsRel
        sectionDocsRel.inverseRelationship = docSectionRel

        // Folder <-> Doc
        let folderDocsRel = NSRelationshipDescription()
        folderDocsRel.name = "docs"
        folderDocsRel.destinationEntity = docEntity
        folderDocsRel.maxCount = 0
        folderDocsRel.isOptional = true
        folderDocsRel.deleteRule = .cascadeDeleteRule

        let docFolderRel = NSRelationshipDescription()
        docFolderRel.name = "folder"
        docFolderRel.destinationEntity = folderEntity
        docFolderRel.maxCount = 1
        docFolderRel.isOptional = true
        docFolderRel.deleteRule = .nullifyDeleteRule

        docFolderRel.inverseRelationship = folderDocsRel
        folderDocsRel.inverseRelationship = docFolderRel

        sectionEntity.properties.append(sectionFoldersRel)
        sectionEntity.properties.append(sectionDocsRel)
        folderEntity.properties.append(folderSectionRel)
        folderEntity.properties.append(folderParentRel)
        folderEntity.properties.append(folderFoldersRel)
        folderEntity.properties.append(folderDocsRel)
        docEntity.properties.append(docSectionRel)
        docEntity.properties.append(docFolderRel)

        let model = NSManagedObjectModel()
        model.entities = [sectionEntity, folderEntity, docEntity]
        return model
    }
}
