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

/// One attribution line for a bundled laboratory reference.
public struct LabSource: Identifiable, Hashable, Sendable {
    public let text: String
    public let url: String

    public init(text: String, url: String) {
        self.text = text
        self.url = url
    }

    public var id: String { text }
}

/// One commonly ordered laboratory test with a typical adult range and a
/// concise description of what the test measures.
public struct LabValueEntry: Identifiable, Hashable, Sendable {
    public let name: String
    public let description: String
    /// Typical adult reference interval. May contain sex-specific or
    /// condition-specific sub-values separated by newlines.
    public let range: String
    /// Collection tube color for this lab (e.g. "Gold" for serum,
    /// "Green" for heparin plasma, "Lavender" for EDTA plasma, "Red" for
    /// EDTA urine, "Blue" for sodium citrate, "Gray" for blood gas).
    /// Every bundled lab carries a collection-tube color; the UI renders a
    /// color swatch at the top of each lab row.
    public let tubeColor: String?

    public init(name: String, description: String, range: String, tubeColor: String? = nil) {
        self.name = name
        self.description = description
        self.range = range
        self.tubeColor = tubeColor
    }

    public var id: String { name }
}

/// A category of laboratory tests (e.g. "Electrolytes", "Hepatic").
public struct LabValueGroup: Identifiable, Hashable, Sendable {
    public let title: String
    public let tests: [LabValueEntry]

    public init(title: String, tests: [LabValueEntry]) {
        self.title = title
        self.tests = tests
    }

    public var id: String { title }
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
    /// Primary attribution line.
    public let source: String
    public let sourceURL: String
    /// Normal lab values, grouped by category — empty if the reference has none.
    public let valueGroups: [LabValueGroup]
    /// Additional attribution lines (normal-range sources, etc.).
    public let additionalSources: [LabSource]

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
        sourceURL: String,
        valueGroups: [LabValueGroup] = [],
        additionalSources: [LabSource] = []
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
        self.valueGroups = valueGroups
        self.additionalSources = additionalSources
    }

    /// Primary source plus any additional sources, in presentation order.
    public var allSources: [LabSource] {
        [LabSource(text: source, url: sourceURL)] + additionalSources
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
                id: "about-values",
                title: "About Normal Lab Values",
                text: """
                The normal lab values below are typical adult serum/venous reference intervals compiled from NBME, Medscape, and Merck Manual sources. They are general guides, not patient-specific targets.

                Ranges vary by laboratory, assay, instrument, age, sex, pregnancy status, altitude, and specimen type. Some values are sex-specific (for example, hemoglobin and creatinine clearance). Always interpret a patient's result against the reference interval printed on the report from the laboratory that performed the test.
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
        sourceURL: "https://www.merckmanuals.com/professional/resources/normal-laboratory-values/laboratory-reference-ranges",
        valueGroups: [
            LabValueGroup(title: "Electrolytes & Acid–Base", tests: [
                LabValueEntry(
                    name: "Sodium (Na)",
                    description: "Major extracellular cation; regulates fluid balance, nerve conduction, and muscle function.",
                    range: "136–146 mEq/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Potassium (K)",
                    description: "Major intracellular cation; critical for resting membrane potential and cardiac rhythm.",
                    range: "3.5–5.0 mEq/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Chloride (Cl)",
                    description: "Principal extracellular anion; follows sodium in fluid and acid–base balance.",
                    range: "95–105 mEq/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Bicarbonate / CO2",
                    description: "Metabolic component of acid–base balance; low suggests metabolic acidosis, high suggests metabolic alkalosis.",
                    range: "22–28 mEq/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Calcium (total)",
                    description: "Bone health, muscle contraction, and clotting; interpret together with albumin.",
                    range: "8.4–10.2 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Magnesium",
                    description: "Cofactor for many enzymes; low levels can cause arrhythmias and neuromuscular irritability.",
                    range: "1.5–2.0 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Phosphorus",
                    description: "Bone mineral and energy metabolism; affected by renal function and vitamin D status.",
                    range: "3.0–4.5 mg/dL",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Renal Function", tests: [
                LabValueEntry(
                    name: "BUN (urea nitrogen)",
                    description: "Urea from protein breakdown; rises with renal impairment, dehydration, or GI bleeding.",
                    range: "7–18 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Creatinine",
                    description: "Waste product of muscle metabolism; primary marker of kidney filtration.",
                    range: "0.6–1.2 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Creatinine clearance",
                    description: "Estimated kidney filtration over 24 h; often replaced by eGFR in routine care.",
                    range: "Male: 97–137 mL/min\nFemale: 88–128 mL/min",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Uric acid",
                    description: "Purine breakdown product; high in gout, tumor lysis, and renal impairment.",
                    range: "3.0–8.2 mg/dL",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Glucose & Endocrine", tests: [
                LabValueEntry(
                    name: "Glucose (fasting)",
                    description: "Primary energy source; fasting range is used for diabetes screening.",
                    range: "70–100 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Hemoglobin A1c",
                    description: "Glycated hemoglobin reflecting approximately 3 months of average glucose.",
                    range: "Normal: <5.7% (<39 mmol/mol)\nDiabetes: ≥6.5% (≥48 mmol/mol)",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "TSH",
                    description: "Pituitary hormone regulating the thyroid; first-line screen for thyroid disease.",
                    range: "0.4–4.0 mIU/L",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Hepatic", tests: [
                LabValueEntry(
                    name: "ALT (alanine aminotransferase)",
                    description: "Liver enzyme; rises with hepatocellular injury.",
                    range: "10–40 U/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "AST (aspartate aminotransferase)",
                    description: "Found in liver, heart, and skeletal muscle; less specific than ALT.",
                    range: "12–38 U/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Alkaline phosphatase",
                    description: "Elevated with bile duct obstruction, liver disease, and high bone turnover.",
                    range: "25–100 U/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Albumin",
                    description: "Most abundant plasma protein; reflects liver synthetic function and nutrition.",
                    range: "3.5–5.5 g/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Total protein",
                    description: "Albumin plus globulins; affected by liver, kidney, and immune status.",
                    range: "6.0–7.8 g/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Bilirubin, total",
                    description: "Breakdown product of hemoglobin; elevated in hemolysis, hepatocellular injury, or cholestasis.",
                    range: "0.1–1.0 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Bilirubin, direct",
                    description: "Conjugated fraction; elevated with obstructive/biliary disease.",
                    range: "0.0–0.3 mg/dL",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Pancreatic / GI", tests: [
                LabValueEntry(
                    name: "Amylase",
                    description: "Pancreatic and salivary enzyme; rises in pancreatitis and salivary gland disease.",
                    range: "25–125 U/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Lipase",
                    description: "More specific than amylase for acute pancreatitis.",
                    range: "13–60 U/L",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Lipids", tests: [
                LabValueEntry(
                    name: "Cholesterol, total",
                    description: "Overall atherosclerotic risk marker; includes all lipoprotein fractions.",
                    range: "Desirable: <200 mg/dL\nHigh: >240 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "HDL cholesterol",
                    description: "“Good” cholesterol; higher levels are generally protective.",
                    range: "40–60 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "LDL cholesterol",
                    description: "“Bad” cholesterol; target is lower in high-risk patients.",
                    range: "<160 mg/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Triglycerides",
                    description: "Endogenous fat; high levels increase cardiovascular and pancreatitis risk.",
                    range: "Normal: <150 mg/dL\nBorderline: 150–199 mg/dL\nHigh: ≥200 mg/dL",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Complete Blood Count", tests: [
                LabValueEntry(
                    name: "WBC",
                    description: "Total leukocyte count; high suggests infection/inflammation, low suggests marrow suppression or sepsis.",
                    range: "4,500–11,000/µL",
                    tubeColor: "Lavender"
                ),
                LabValueEntry(
                    name: "RBC count",
                    description: "Red blood cell count; low suggests anemia, high suggests polycythemia or dehydration.",
                    range: "Male: 4.3–5.9 million/µL\nFemale: 3.5–5.5 million/µL",
                    tubeColor: "Lavender"
                ),
                LabValueEntry(
                    name: "Hemoglobin",
                    description: "Oxygen-carrying protein in red cells; the main anemia marker.",
                    range: "Male: 13.5–17.5 g/dL\nFemale: 12.0–16.0 g/dL",
                    tubeColor: "Lavender"
                ),
                LabValueEntry(
                    name: "Hematocrit",
                    description: "Volume fraction of blood occupied by red cells.",
                    range: "Male: 41–53%\nFemale: 36–46%",
                    tubeColor: "Lavender"
                ),
                LabValueEntry(
                    name: "MCV",
                    description: "Mean corpuscular volume; classifies anemia as microcytic, normocytic, or macrocytic.",
                    range: "80–100 fL",
                    tubeColor: "Lavender"
                ),
                LabValueEntry(
                    name: "MCH",
                    description: "Mean corpuscular hemoglobin; average hemoglobin content per red cell.",
                    range: "25–35 pg",
                    tubeColor: "Lavender"
                ),
                LabValueEntry(
                    name: "MCHC",
                    description: "Mean corpuscular hemoglobin concentration; hemoglobin density inside red cells.",
                    range: "31–36 g/dL",
                    tubeColor: "Lavender"
                ),
                LabValueEntry(
                    name: "Platelets",
                    description: "Thrombocyte count; low increases bleeding risk, high may be reactive or myeloproliferative.",
                    range: "150,000–400,000/µL",
                    tubeColor: "Lavender"
                )
            ]),
            LabValueGroup(title: "Coagulation", tests: [
                LabValueEntry(
                    name: "PT",
                    description: "Prothrombin time; extrinsic and common pathways of coagulation.",
                    range: "11–15 seconds",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "INR",
                    description: "Standardized PT; used to monitor warfarin therapy.",
                    range: "Un anticoagulated: 0.9–1.2",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "aPTT",
                    description: "Activated partial thromboplastin time; intrinsic and common pathways.",
                    range: "25–40 seconds",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "D-dimer",
                    description: "Fibrin degradation product; high suggests active clot formation/lysis.",
                    range: "≤250 ng/mL (lab-specific)",
                    tubeColor: "Blue"
                ),
                LabValueEntry(
                    name: "Fibrinogen",
                    description: "Clotting factor; low with liver disease or DIC, high as an acute-phase reactant.",
                    range: "200–400 mg/dL",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Cardiac & Inflammatory", tests: [
                LabValueEntry(
                    name: "Troponin I",
                    description: "Cardiac-specific protein; rises with myocardial injury.",
                    range: "≤0.04 ng/mL (assay-specific)",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Creatine kinase (CK)",
                    description: "Muscle enzyme; rises with myocardial, skeletal, or brain injury.",
                    range: "Male: 25–90 U/L\nFemale: 10–70 U/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "LDH",
                    description: "Tissue enzyme released with cell turnover; nonspecific marker of hemolysis or tissue injury.",
                    range: "45–200 U/L",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "CRP",
                    description: "Acute-phase reactant; rises with inflammation, infection, and tissue injury.",
                    range: "Usually <10 mg/L (lab-specific)",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "ESR",
                    description: "Erythrocyte sedimentation rate; nonspecific marker of inflammation.",
                    range: "Male: 0–15 mm/h\nFemale: 0–20 mm/h",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Blood Gas (arterial)", tests: [
                LabValueEntry(
                    name: "pH",
                    description: "Acid–base balance of the blood; <7.35 is acidemia, >7.45 is alkalemia.",
                    range: "7.35–7.45",
                    tubeColor: "Gray"
                ),
                LabValueEntry(
                    name: "PaCO2",
                    description: "Respiratory component of acid–base balance; reflects alveolar ventilation.",
                    range: "35–45 mm Hg",
                    tubeColor: "Gray"
                ),
                LabValueEntry(
                    name: "PaO2",
                    description: "Arterial oxygen tension; the primary marker of oxygenation (room-air reference).",
                    range: "80–100 mm Hg",
                    tubeColor: "Gray"
                ),
                LabValueEntry(
                    name: "HCO3\u{208B} (bicarbonate)",
                    description: "Metabolic component of acid–base balance.",
                    range: "22–26 mEq/L",
                    tubeColor: "Gray"
                ),
                LabValueEntry(
                    name: "Base excess",
                    description: "Calculated metabolic correction; negative suggests metabolic acidosis.",
                    range: "0 \u{00B1} 2 mEq/L",
                    tubeColor: "Gray"
                ),
                LabValueEntry(
                    name: "SaO2",
                    description: "Oxygen saturation of hemoglobin; the target is \u{2265}95% on room air.",
                    range: "95–100%",
                    tubeColor: "Gray"
                ),
                LabValueEntry(
                    name: "Lactate",
                    description: "Rises with tissue hypoperfusion; used to monitor shock, sepsis, and post-resuscitation care.",
                    range: "0.5–2.0 mmol/L (\u{2248}5–18 mg/dL)",
                    tubeColor: "Gray"
                )
            ]),
            LabValueGroup(title: "Urinalysis", tests: [
                LabValueEntry(
                    name: "pH",
                    description: "Acidity of the urine; diet, infection, and renal tubular function shift it.",
                    range: "4.6–8.0 (average \u{2248}6)",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Specific gravity",
                    description: "Urine concentration; reflects kidney concentrating ability and hydration.",
                    range: "1.005–1.030",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Protein",
                    description: "Dipstick detects mainly albumin; sustained protein suggests glomerular disease.",
                    range: "Negative (<150 mg/day)",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Glucose",
                    description: "Present above the renal threshold (\u{2248}180 mg/dL blood glucose); a diabetes screen.",
                    range: "Negative",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Ketones",
                    description: "Fat-metabolism byproduct; positive in DKA, starvation, and very low-carbohydrate diets.",
                    range: "None (trace possible)",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Blood",
                    description: "Detects hemoglobin; positive in UTIs, stones, trauma, or malignancy.",
                    range: "Negative",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Leukocyte esterase",
                    description: "Enzyme from white cells; a screen for urinary tract infection.",
                    range: "Negative",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Nitrite",
                    description: "Produced when nitrate-reducing bacteria sit in the bladder; suggests bacteriuria.",
                    range: "Negative",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Bilirubin",
                    description: "Urine bilirubin indicates conjugated hyperbilirubinemia (hepatic/biliary disease).",
                    range: "Negative",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Urobilinogen",
                    description: "Breakdown product of bilirubin; high in hemolysis or hepatocellular injury, absent in obstruction.",
                    range: "0.2–1.0 mg/dL",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "WBC (microscopy)",
                    description: "Bacteria with WBCs suggests infection; many WBCs without bacteria suggests other inflammation.",
                    range: "0–4 per high-power field",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "RBC (microscopy)",
                    description: "Dysmorphic RBCs suggest glomerular bleeding; uniform RBCs suggest stones or trauma.",
                    range: "\u{2264}2 per high-power field",
                    tubeColor: "Red"
                )
            ]),
            LabValueGroup(title: "Iron & Bone", tests: [
                LabValueEntry(
                    name: "Iron, serum",
                    description: "Circulating iron; low in iron-deficiency anemia, high in hemochromatosis.",
                    range: "50–150 \u{00B5}g/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "TIBC",
                    description: "Total iron-binding capacity; rises when iron stores are depleted.",
                    range: "250–310 \u{00B5}g/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Transferrin saturation",
                    description: "Fraction of the iron-binding capacity that is saturated (serum iron \u{00F7} TIBC).",
                    range: "20–50%",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Ferritin",
                    description: "Iron stores; the most sensitive marker of iron deficiency (also an acute-phase reactant).",
                    range: "Male: 12–300 ng/mL\nFemale: 10–150 ng/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Vitamin D (25-hydroxy)",
                    description: "Primary measure of vitamin D status; <20 ng/mL indicates deficiency.",
                    range: "30–60 ng/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Vitamin B12",
                    description: "Low levels suggest pernicious anemia, malabsorption, or strict vegan diet without supplementation.",
                    range: "200–800 pg/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Folate, serum",
                    description: "Deficiency causes macrocytic anemia; affected by diet, alcohol, and malabsorption.",
                    range: "5–25 ng/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "PTH (intact)",
                    description: "Regulates calcium and phosphorus; high in primary hyperparathyroidism or vitamin D deficiency.",
                    range: "15–65 pg/mL",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Hormones", tests: [
                LabValueEntry(
                    name: "Free T4",
                    description: "Active thyroid hormone; the key test for hypo-/hyperthyroidism alongside TSH.",
                    range: "0.8–1.8 ng/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Total T3",
                    description: "Thyroid hormone; falls in non-thyroidal illness and with amiodarone.",
                    range: "80–180 ng/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Cortisol (8 a.m.)",
                    description: "Adrenal steroid with a morning peak; low values suggest adrenal insufficiency.",
                    range: "5–23 \u{00B5}g/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Testosterone (total)",
                    description: "Primary sex hormone; low in hypogonadism, rises in PCOS.",
                    range: "Male: 291–1100 ng/dL\nFemale: 18–54 ng/dL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Estradiol",
                    description: "Primary estrogen; interpret against the menstrual phase or menopausal status.",
                    range: "Follicular: 20–350 pg/mL\nMidcycle peak: 150–750 pg/mL\nLuteal: 30–450 pg/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "Prolactin",
                    description: "Elevated in hypothyroidism, pregnancy, and many medications; a macroadenoma marker.",
                    range: "Male: 3–13 ng/mL\nFemale: 3–27 ng/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "\u{03B}-hCG",
                    description: "Pregnancy test; also a tumor marker for germ-cell and trophoblastic cancers.",
                    range: "Male: <1.4 IU/L\nFemale (nonpregnant): <1.0 IU/L",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Tumor Markers", tests: [
                LabValueEntry(
                    name: "AFP",
                    description: "Hepatocellular carcinoma and germ-cell tumor marker; elevated in liver disease and pregnancy.",
                    range: "<40 ng/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "PSA",
                    description: "Prostate screening/monitoring; also elevated in BPH and prostatitis, so interpret with the clinical picture.",
                    range: "0–2.5 ng/mL (age-adjusted higher)",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "CEA",
                    description: "Colorectal cancer monitoring; not a screening test, and smokers may run mildly higher.",
                    range: "<2.5 ng/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "CA-125",
                    description: "Ovarian cancer monitoring; rises with many benign conditions (endometriosis, menstruation, ascites).",
                    range: "<35 U/mL",
                    tubeColor: "Gold"
                ),
                LabValueEntry(
                    name: "CA 19-9",
                    description: "Pancreatic and biliary cancers; can be elevated in cholestasis even without cancer.",
                    range: "0–37 U/mL",
                    tubeColor: "Gold"
                )
            ]),
            LabValueGroup(title: "Cerebrospinal Fluid (CSF)", tests: [
                LabValueEntry(
                    name: "WBC",
                    description: "Lymphocytes predominate in healthy adults; neutrophilic shifts suggest bacterial infection.",
                    range: "0–5 cells/\u{00B5}L",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "RBC",
                    description: "Usually absent; a few may be traumatic tap, many suggest hemorrhage.",
                    range: "0",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Protein",
                    description: "Elevated in infection, inflammation, or spinal block; very high in Guillian-Barr\u{00E9}.",
                    range: "15–45 mg/dL",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Glucose",
                    description: "Normally 60–70% of simultaneous serum glucose; low in bacterial/fungal infection.",
                    range: "25–80 mg/dL (60–70% of blood)",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Chloride",
                    description: "Low with tuberculous or carcinomatous meningitis; rarely used now.",
                    range: "120–130 mEq/L",
                    tubeColor: "Red"
                ),
                LabValueEntry(
                    name: "Opening pressure",
                    description: "Measured with the patient lateral; high suggests raised intracranial pressure or meningitis.",
                    range: "6–25 cm H2O",
                    tubeColor: "Red"
                )
            ])
        ],
        additionalSources: [
            LabSource(
                text: "NBME Laboratory Values (ranges above)",
                url: "https://www.nbme.org/laboratory-values/"
            ),
            LabSource(
                text: "Medscape — Lab Values, Normal Adult (ranges above)",
                url: "https://emedicine.medscape.com/article/2172316-overview"
            )
        ]
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

    /// Plain-text rendering of the normal lab values: one block per test.
    public var valuesText: String {
        guard !valueGroups.isEmpty else { return "" }
        let blocks = valueGroups.flatMap { group -> [String] in
            let header = group.title
            let entries = group.tests.map { entry in
                [
                    entry.name,
                    "Range: \(entry.range.replacingOccurrences(of: "\n", with: "; ")),",
                    entry.description
                ]
                .joined(separator: "\n")
            }
            return [header, ""] + entries
        }
        return blocks.joined(separator: "\n\n")
    }
}
