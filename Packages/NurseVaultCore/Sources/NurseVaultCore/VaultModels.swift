import Foundation
import CoreData

/// A named reference section (e.g. "Code Blue", "Lab Values", "Drugs", "Other").
/// New sections can be created at any time from the app.
public final class VaultSection: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var icon: String?
    @NSManaged public var sortOrder: NSNumber?
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
}

/// Builds the Core Data model in code, so the package needs no model file.
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

        let sectionEntity = NSEntityDescription()
        sectionEntity.name = "Section"
        sectionEntity.managedObjectClassName = NSStringFromClass(VaultSection.self)
        sectionEntity.properties = [
            attribute("name", .stringAttributeType),
            attribute("icon", .stringAttributeType),
            attribute("sortOrder", .integer64AttributeType)
        ]

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

        let docsRelationship = NSRelationshipDescription()
        docsRelationship.name = "docs"
        docsRelationship.destinationEntity = docEntity
        docsRelationship.maxCount = 0
        docsRelationship.isOptional = true
        docsRelationship.deleteRule = .cascadeDeleteRule

        let sectionRelationship = NSRelationshipDescription()
        sectionRelationship.name = "section"
        sectionRelationship.destinationEntity = sectionEntity
        sectionRelationship.maxCount = 1
        sectionRelationship.isOptional = true
        sectionRelationship.deleteRule = .nullifyDeleteRule

        docsRelationship.inverseRelationship = sectionRelationship
        sectionRelationship.inverseRelationship = docsRelationship

        sectionEntity.properties.append(docsRelationship)
        docEntity.properties.append(sectionRelationship)

        let model = NSManagedObjectModel()
        model.entities = [sectionEntity, docEntity]
        return model
    }
}
