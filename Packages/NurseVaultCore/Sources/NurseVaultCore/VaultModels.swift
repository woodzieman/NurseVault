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
        // Helper: create an optional attribute with a default configuration.
        func attr(_ name: String, _ type: NSAttributeType, configure: (NSAttributeDescription) -> Void = { _ in }) -> NSAttributeDescription {
            let d = NSAttributeDescription()
            d.name = name
            d.attributeType = type
            d.isOptional = true
            configure(d)
            return d
        }

        // Helper: create a required attribute with a default value.
        func requiredAttr(_ name: String, _ type: NSAttributeType, defaultValue: Any) -> NSAttributeDescription {
            let d = NSAttributeDescription()
            d.name = name
            d.attributeType = type
            d.isOptional = false
            d.defaultValue = defaultValue
            return d
        }

        // Helper: create a to-many relationship (cascade delete).
        func toMany(_ name: String, _ destination: NSEntityDescription) -> NSRelationshipDescription {
            let r = NSRelationshipDescription()
            r.name = name
            r.destinationEntity = destination
            r.maxCount = 0
            r.isOptional = true
            r.deleteRule = .cascadeDeleteRule
            return r
        }

        // Helper: create a to-one relationship (nullify delete).
        func toOne(_ name: String, _ destination: NSEntityDescription) -> NSRelationshipDescription {
            let r = NSRelationshipDescription()
            r.name = name
            r.destinationEntity = destination
            r.maxCount = 1
            r.isOptional = true
            r.deleteRule = .nullifyDeleteRule
            return r
        }

        // Helper: wire up an inverse relationship pair and add both to their entities.
        func link(_ parent: NSRelationshipDescription, _ child: NSRelationshipDescription,
                  toParentEntity parentEntity: NSEntityDescription, toChildEntity childEntity: NSEntityDescription) {
            parent.inverseRelationship = child
            child.inverseRelationship = parent
            parentEntity.properties.append(parent)
            childEntity.properties.append(child)
        }

        // --- Entities ---
        let section = entity("Section", VaultSection.self, [
            attr("name", .stringAttributeType),
            attr("icon", .stringAttributeType),
            attr("sortOrder", .integer64AttributeType),
            requiredAttr("syncToWatch", .booleanAttributeType, defaultValue: true)
        ])

        let folder = entity("Folder", VaultFolder.self, [
            attr("name", .stringAttributeType)
        ])

        let doc = entity("Doc", VaultDoc.self, [
            attr("title", .stringAttributeType),
            attr("noteText", .stringAttributeType),
            attr("fileName", .stringAttributeType),
            attr("mimeType", .stringAttributeType),
            attr("addedDate", .dateAttributeType),
            attr("fileData", .binaryDataAttributeType) { $0.allowsExternalBinaryDataStorage = true }
        ])

        // --- Relationships ---
        // Every relationship must be explicitly added to its destination entity's
        // properties. Core Data 27 crashes on first launch if an inverse is orphaned.

        link(toMany("folders", folder), toOne("section", section),
             toParentEntity: section, toChildEntity: folder)

        link(toMany("folders", folder), toOne("parent", folder),
             toParentEntity: folder, toChildEntity: folder)

        link(toMany("docs", doc), toOne("section", section),
             toParentEntity: section, toChildEntity: doc)

        link(toMany("docs", doc), toOne("folder", folder),
             toParentEntity: folder, toChildEntity: doc)

        let model = NSManagedObjectModel()
        model.entities = [section, folder, doc]
        return model
    }

    private static func entity(_ name: String, _ type: AnyClass, _ properties: [NSPropertyDescription]) -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = name
        e.managedObjectClassName = NSStringFromClass(type)
        e.properties = properties
        return e
    }
}
