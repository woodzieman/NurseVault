import SwiftUI
import NurseVaultCore

enum SearchResult: Identifiable {
    var id: String {
        switch self {
        case .drug(let entry): return "drug-\(entry.id)"
        case .topic(let topic): return "topic-\(topic.id)"
        case .dsmTopic(let entry): return "dsm-\(entry.id)"
        case .calculator(let calc): return "calc-\(calc.id)"
        case .document(let doc): return "doc-\(doc.objectID.uriRepresentation().absoluteString)"
        }
    }

    case drug(DrugEntry)
    case topic(MerckTopicEntry)
    case dsmTopic(DsmTopicEntry)
    case calculator(CalculatorInfo)
    case document(VaultDoc)
}
