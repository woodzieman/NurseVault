import Foundation

/// One column of a "commonly used panels"-style table.
public struct LabPanelColumn: Hashable, Sendable {
    /// e.g. "CMP"
    public let abbreviation: String
    /// e.g. "Comprehensive metabolic panel"
    public let fullName: String

    public init(abbreviation: String, fullName: String) {
        self.abbreviation = abbreviation
        self.fullName = fullName
    }
}

/// One row of a "commonly used panels"-style table.
public struct LabPanelTest: Identifiable, Hashable, Sendable {
    /// Test name as published (e.g. "Aminotransferase, alanine (ALT)").
    public let name: String
    /// Which panels include the test — parallel to `LabReference.panelColumns`.
    public let inPanels: [Bool]

    public init(name: String, inPanels: [Bool]) {
        self.name = name
        self.inPanels = inPanels
    }

    public var id: String { name }
}

/// One row of a "therapeutic drug monitoring"-style table.
public struct LabTDMRow: Identifiable, Hashable, Sendable {
    public let drug: String
    /// Cell text; contains newlines for trough/peak sub-values. "—" = not defined.
    public let low: String
    public let high: String
    public let criticalHigh: String

    public init(drug: String, low: String, high: String, criticalHigh: String) {
        self.drug = drug
        self.low = low
        self.high = high
        self.criticalHigh = criticalHigh
    }

    public var id: String { drug }
}

/// One block of interpretive text (used by the watch's paragraph
/// presentation and the iOS "About" screens).
public struct LabReferenceSection: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let text: String

    public init(id: String, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}

/// A bundled laboratory reference dataset.
///
/// Shared by the iOS app (table presentation) and the watch app (plain-text
/// presentation) so both render from one source of truth. The data is code,
/// not a bundled resource, so the feature works offline with no file loading
/// or decompression.
public struct LabReference: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    /// Interpretive text sections (order = presentation order).
    public let sections: [LabReferenceSection]
    /// "Commonly Used Panels" table — empty if the reference has none.
    public let panelColumns: [LabPanelColumn]
    public let panelTests: [LabPanelTest]
    /// Footnote under the panels table ("" if none).
    public let panelNote: String
    /// "Therapeutic Drug Monitoring" table — empty if the reference has none.
    public let tdmRows: [LabTDMRow]
    /// Footnote under the TDM table ("" if none).
    public let tdmNote: String
    /// Attribution line.
    public let source: String
    public let sourceURL: String

    public init(
        id: String,
        title: String,
        sections: [LabReferenceSection],
        panelColumns: [LabPanelColumn],
        panelTests: [LabPanelTest],
        panelNote: String,
        tdmRows: [LabTDMRow],
        tdmNote: String,
        source: String,
        sourceURL: String
    ) {
        self.id = id
        self.title = title
        self.sections = sections
        self.panelColumns = panelColumns
        self.panelTests = panelTests
        self.panelNote = panelNote
        self.tdmRows = tdmRows
        self.tdmNote = tdmNote
        self.source = source
        self.sourceURL = sourceURL
    }
}

/// All bundled laboratory references.
public enum LabReferences {
    public static let all: [LabReference] = [
        .merckLaboratoryReferenceRanges
    ]
}

extension LabReference {

    /// Merck Manual Professional, Resources > Normal Laboratory Values >
    /// Laboratory Reference Ranges. Tables transcribed from the user's
    /// existing conversion (`Laboratory Reference Ranges.txt`, retrieved
    /// 2026-09-25) and verified against the live page (May 2026 revision).
    public static let merckLaboratoryReferenceRanges = LabReference(
        id: "merck-lab-ranges",
        title: "Laboratory Reference Ranges",
        sections: [
            LabReferenceSection(
                id: "about-ranges",
                title: "About Reference Ranges",
                text: """
                Laboratory reference ranges (also called reference values or reference intervals) for blood, urine, cerebrospinal fluid (CSF), stool, and other body fluids vary based on several factors, including the demographics of the healthy population from which specimens were obtained and the specific methods and instruments used to assay the specimens. These demographics can include age, sex, and geographic location.

                Many normal physiologic processes change through aging, so laboratory reference ranges change to reflect normal aging. For example, neonates and premature infants do not have fully developed hepatic, pulmonary, and renal function, and pediatric laboratory reference ranges are often different from adult ranges.

                Laboratories that are accredited (CAP, CLIA, COLA, or FDA) are required to establish and validate their own reference ranges for FDA-approved assays and for laboratory developed tests (LDTs). Thus, any given result should be interpreted based on the reference range of the laboratory in which the test was performed; the laboratory typically provides reference values on the clinical report that corresponds with the test result.

                Reference ranges generally represent 95% of the otherwise healthy population and do not usually allow 100% distinction between health and disease. Use these values as a general guide, and interpret a patient's result against the range printed by the laboratory that performed the test.
                """
            ),
            LabReferenceSection(
                id: "about-tdm",
                title: "About Therapeutic Drug Monitoring",
                text: """
                Therapeutic drug monitoring (TDM) is the clinical assessment and interpretation of targeted drug concentrations at designated time points, in order to manage the patient by maintaining a specified drug level in the circulation. TDM is mainly used for drugs with narrow therapeutic ranges, where the circulating concentration required for optimal efficacy must be kept within a tight window and missed levels can cause toxicity.

                TDM begins at initiation of the prescription (dose determination in the context of clinical presentation, the patient's age, weight, comorbidities, and concomitant drug therapy) and continues as dose adjustment based on the measured concentration, the sampling time (trough, peak, or random), the patient's response, and the desired outcome.
                """
            )
        ],
        panelColumns: [
            LabPanelColumn(abbreviation: "CMP", fullName: "comprehensive metabolic panel"),
            LabPanelColumn(abbreviation: "RFP", fullName: "renal function panel"),
            LabPanelColumn(abbreviation: "BMP", fullName: "basic metabolic panel"),
            LabPanelColumn(abbreviation: "ELEC", fullName: "electrolyte panel"),
            LabPanelColumn(abbreviation: "HFPA", fullName: "hepatic function panel"),
            LabPanelColumn(abbreviation: "LPP", fullName: "lipid panel"),
            LabPanelColumn(abbreviation: "AHP", fullName: "acute hepatitis panel")
        ],
        panelTests: [
            LabPanelTest(name: "Albumin", inPanels: [true, true, false, false, true, false, false]),
            LabPanelTest(name: "Alkaline phosphatase", inPanels: [true, false, false, false, true, false, false]),
            LabPanelTest(name: "Aminotransferase, alanine (ALT)", inPanels: [true, false, false, false, true, false, false]),
            LabPanelTest(name: "Aminotransferase, aspartate (AST)", inPanels: [true, false, false, false, true, false, false]),
            LabPanelTest(name: "Bilirubin, direct", inPanels: [false, false, false, false, true, false, false]),
            LabPanelTest(name: "Bilirubin, total", inPanels: [true, false, false, false, true, false, false]),
            LabPanelTest(name: "Calcium", inPanels: [true, true, true, false, false, false, false]),
            LabPanelTest(name: "Carbon dioxide", inPanels: [true, true, true, true, false, false, false]),
            LabPanelTest(name: "Chloride", inPanels: [true, true, true, true, false, false, false]),
            LabPanelTest(name: "Cholesterol, total", inPanels: [false, false, false, false, false, true, false]),
            LabPanelTest(name: "Cholesterol, HDL", inPanels: [false, false, false, false, false, true, false]),
            LabPanelTest(name: "Creatinine", inPanels: [true, true, true, false, false, false, false]),
            LabPanelTest(name: "Glucose, fasting", inPanels: [true, true, true, false, false, false, false]),
            LabPanelTest(name: "Hepatitis A, IgM antibody", inPanels: [false, false, false, false, false, false, true]),
            LabPanelTest(name: "Hepatitis B core, IgM antibody", inPanels: [false, false, false, false, false, false, true]),
            LabPanelTest(name: "Hepatitis B surface antigen", inPanels: [false, false, false, false, false, false, true]),
            LabPanelTest(name: "Hepatitis C antibody", inPanels: [false, false, false, false, false, false, true]),
            LabPanelTest(name: "Phosphorus", inPanels: [false, true, false, false, false, false, false]),
            LabPanelTest(name: "Potassium", inPanels: [true, true, true, true, false, false, false]),
            LabPanelTest(name: "Protein, total", inPanels: [true, false, false, false, true, false, false]),
            LabPanelTest(name: "Sodium", inPanels: [true, true, true, true, false, false, false]),
            LabPanelTest(name: "Triglycerides*", inPanels: [false, false, false, false, false, true, false]),
            LabPanelTest(name: "Urea nitrogen (BUN)", inPanels: [true, true, true, false, false, false, false])
        ],
        panelNote: "* Triglycerides includes calculations of risk ratios and low-density lipoprotein (LDL). See also American Medical Association Medicare Test Panels.",
        tdmRows: [
            LabTDMRow(drug: "Carbamazepine", low: "4.0 mcg/mL", high: "12.0 mcg/mL", criticalHigh: "≥ 15.0 mcg/mL"),
            LabTDMRow(drug: "Digoxin", low: "0.8 mg/dL", high: "2.0 mg/dL", criticalHigh: "≥ 2.1 mg/dL"),
            LabTDMRow(
                drug: "Gentamicin",
                low: "Trough: 1.0 mcg/mL\nPeak: 5.0 mcg/mL",
                high: "Trough: 1.9 mcg/mL\nPeak: 8.0 mcg/mL",
                criticalHigh: "Trough: ≥ 2.0 mcg/mL\nPeak: ≥ 12.0 mcg/mL\nRandom: ≥ 2.0 mcg/mL"
            ),
            LabTDMRow(drug: "Phenobarbital", low: "10.0 mcg/mL", high: "30.0 mcg/mL", criticalHigh: "≥ 50.0 mcg/mL"),
            LabTDMRow(drug: "Phenytoin", low: "10.0 mcg/mL", high: "20.0 mcg/mL", criticalHigh: "≥ 25.0 mcg/mL"),
            LabTDMRow(
                drug: "Tobramycin",
                low: "—\nTrough: 0.5 mcg/mL\nPeak: 6.0 mcg/mL",
                high: "—\nTrough: 2.0 mcg/mL\nPeak: 9.9 mcg/mL",
                criticalHigh: "Random: ≥ 2.0 mcg/mL\nTrough: ≥ 2.0 mcg/mL\nPeak: ≥ 10.0 mcg/mL"
            ),
            LabTDMRow(drug: "Valproic acid", low: "50 mcg/mL", high: "99 mcg/mL", criticalHigh: "≥ 100 mcg/mL"),
            LabTDMRow(
                drug: "Vancomycin",
                low: "—\nTrough: 5 mcg/mL\nPeak: 20 mcg/mL",
                high: "—\nTrough: 10 mcg/mL\nPeak: 40 mcg/mL",
                criticalHigh: "≥ 30 mcg/mL\nTrough: ≥ 30 mcg/mL\nPeak: ≥ 80 mcg/mL"
            )
        ],
        tdmNote: "* All values are for lithium-heparin serum samples. Source: Baselt, R. C. (2020). Disposition of toxic drugs and chemicals in man (12th ed.), Biomedical Publications.",
        source: "Merck Manual Professional — Resources > Normal Laboratory Values",
        sourceURL: "https://www.merckmanuals.com/professional/resources/normal-laboratory-values/laboratory-reference-ranges"
    )
}

// MARK: - Plain-text rendering (watch)

extension LabReference {

    /// Plain-text rendering of the "commonly used panels" table: a key line
    /// expanding the abbreviations, then one "Test — panels" line per test.
    public var panelsText: String {
        guard !panelTests.isEmpty else { return "" }
        let key = panelColumns.map { "\($0.abbreviation) = \($0.fullName)" }.joined(separator: "; ")
        let lines = panelTests.map { test in
            let included = zip(panelColumns, test.inPanels).compactMap { column, included in
                included ? column.abbreviation : nil
            }
            return "\(test.name) — \(included.joined(separator: ", "))"
        }
        return [key, "", lines.joined(separator: "\n"), panelNote]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// Plain-text rendering of the "therapeutic drug monitoring" table: one
    /// "Drug — low; high; critical" line per drug (multi-line cells joined).
    public var tdmText: String {
        guard !tdmRows.isEmpty else { return "" }
        let rows = tdmRows.map { row in
            func cell(_ value: String) -> String {
                value.replacingOccurrences(of: "\n", with: ", ")
            }
            return "\(row.drug) — low: \(cell(row.low)); high: \(cell(row.high)); critical: \(cell(row.criticalHigh))"
        }
        return [rows.joined(separator: "\n"), tdmNote]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
