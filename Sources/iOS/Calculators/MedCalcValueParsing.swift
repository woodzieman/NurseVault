import Foundation

/// A compact numeric value + unit parsed from a result string, for use in complications and small surfaces.
struct MedCalcDisplayValue: Hashable, Sendable {
    let value: String
    let unit: String?

    var fullText: String {
        unit.map { "\(value) \($0)" } ?? value
    }
}

enum MedCalcValueParser {
    /// Extracts the first numeric value from a result string plus a best-effort unit.
    ///
    /// "A-a Gradient: 15.2 mmHg (Elevated)" -> value "15.2", unit "mmHg"
    /// "AUDIT: 8/40 (Hazardous)"             -> value "8", unit nil ("8/40" is a ratio, not a value+unit)
    static func parse(_ text: String) -> MedCalcDisplayValue? {
        let line = (text.components(separatedBy: .newlines).first ?? text)
        guard let range = line.range(of: #"[-+]?\d+(?:\.\d+)?"#, options: .regularExpression) else {
            return nil
        }
        guard let number = Double(line[range]) else { return nil }

        let decimals: Int
        switch abs(number) {
        case 100...: decimals = 0
        case 10..<100: decimals = 1
        default: decimals = 2
        }
        let value = String(format: "%.\(decimals)f", number)

        var rest = String(line[range.upperBound...])
        rest = rest.trimmingCharacters(in: CharacterSet(charactersIn: " :"))

        var unit: String? = nil
        var taken = 0
        for rawWord in rest.split(separator: " ") {
            let word = String(rawWord)
            guard !word.hasPrefix("(") else { break }
            let isUnitLike = word.contains(where: { $0 == "/" || $0 == "²" || $0 == "³" || $0 == "°" || $0 == "µ" || $0 == "%" })
            let isShortAlphabetic = word.count <= 10 && word.allSatisfy { $0.isLetter }
            guard isUnitLike || isShortAlphabetic else { break }
            if taken > 0 && !isUnitLike { break } // a second plain word ("Elevated") is prose, not a unit
            unit = (unit.map { $0 + " " } ?? "") + word
            taken += 1
            if unit!.count > 14 { break }
            if taken >= 2 { break }
        }

        return MedCalcDisplayValue(value: value, unit: unit)
    }
}
