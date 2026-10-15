import Foundation

/// Category icons and display helpers shared by the app, widgets, and watch.
enum MedCalcCategoryIcons {
    static func icon(for category: String) -> String {
        switch category {
        case "Cardiovascular": return "heart.fill"
        case "Critical Care Scores": return "firstaid.fill"
        case "EBM & Statistics": return "chart.bar.fill"
        case "Electrolytes & Acid-Base": return "drop.fill"
        case "Endocrinology": return "leaf.circle.fill"
        case "Gastroenterology": return "stethoscope"
        case "Growth & Anthropometrics": return "person.circle.fill"
        case "Hematology": return "bloodtest"
        case "Hepatic": return "liver"
        case "Infectious Disease": return "cross.vial"
        case "Mental Health & Screening": return "face.smiling.fill"
        case "Neonatology": return "sparkles"
        case "Neurology": return "brain.head.profile"
        case "Oncology & Risk": return "star.circle.fill"
        case "Other": return "ellipsis.circle.fill"
        case "Pediatrics": return "figure.child"
        case "Pharmacology & Toxicology": return "pill.fill"
        case "Pulmonary": return "lungs.fill"
        case "Renal": return "kidney"
        case "Respiratory & Gas Exchange": return "wind"
        case "Rheumatology": return "hand.raised.fill"
        case "Sleep Medicine": return "moon.stars.fill"
        case "Substance Use": return "wineglass.fill"
        case "Unit Conversions": return "arrow.left.right.circle.fill"
        case "Urology": return "bell.fill"
        default: return "plus.rectangle.on.rectangle"
        }
    }

    /// Strips trailing parentheticals and long title tails so results stay glanceable in widgets.
    static func shortTitle(_ title: String) -> String {
        var shortened = title
        if let openParen = shortened.range(of: " (") {
            shortened = String(shortened[..<openParen.lowerBound])
        }
        if shortened.count > 28 {
            let prefix = shortened.prefix(28)
            if let lastSpace = prefix.lastIndex(of: " ") {
                shortened = String(prefix[...lastSpace])
            } else {
                shortened = String(prefix)
            }
            shortened += "…"
        }
        return shortened
    }
}
