import Foundation

/// Realistic stand-in data for widget placeholders, gallery snapshots, and previews.
/// Snapshots must never show an empty state, so these are populated with plausible values.
enum MedCalcSampleData {
    static var sampleResults: [CalculationResult] {
        let now = Date()
        let specs: [(id: String, text: String, secondsAgo: TimeInterval)] = [
            ("AtrialFibCHADSVASchtm", "CHA2DS2-VASc: 3 (AC recommended)", 45),
            ("GFRCKDEPIhtm", "eGFR: 62 mL/min/1.73m² (CKD Stage 2)", 4 * 60),
            ("meld3htm", "MELD 3.0: 11.4 (Low)", 26 * 60),
            ("BodyMassIndexhtm", "BMI: 24.3 kg/m² (Normal)", 55 * 60),
            ("QSOFAhtm", "qSOFA: 1 (Low risk)", 80 * 60),
            ("SOFAhtm", "SOFA: 4", 105 * 60),
            ("AnionGaphtm", "Anion Gap: 12 mEq/L (Normal)", 130 * 60),
            ("MifflinStJeorhtm", "REE: 1720 kcal/day", 150 * 60),
        ]
        return specs.compactMap { spec in
            guard let calculator = MedCalcCatalog.calculator(withID: spec.id) else { return nil }
            return CalculationResult(
                calculator: calculator,
                text: spec.text,
                date: now.addingTimeInterval(-spec.secondsAgo)
            )
        }
    }

    static var sampleFavoriteCalculators: [CalculatorInfo] {
        [
            "AtrialFibCHADSVASchtm",
            "GFRCKDEPIhtm",
            "meld3htm",
            "BodyMassIndexhtm",
            "QSOFAhtm",
            "AnionGaphtm",
            "MifflinStJeorhtm",
            "CIWAhtm",
        ].compactMap { MedCalcCatalog.calculator(withID: $0) }
    }
}
