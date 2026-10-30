import Foundation

// Rheumatology calculator specs — formulas from the Merck Manual clinical-calculator sources.

let rheumatologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "RheumatoidArthritisCDAI.htm",
        guide: """
        The Clinical Disease Activity Index (CDAI) tracks rheumatoid arthritis activity without laboratory values.

        • Swollen joint count (SJC): number of swollen joints on a 28-joint exam (0–28).
        • Tender joint count (TJC): number of tender joints on the same 28-joint exam (0–28).
        • Patient global assessment (PGA) and physician/evaluator global assessment (EGA), each scored 0–10.

        Interpretation: ≤2.8 remission; >2.8–≤10 low disease activity; >10–≤22 moderate disease activity; >22 high disease activity.
        """,
        equation: "CDAI = SJC + TJC + PGA + EGA",
        inputs: [
            MedCalcInput("sjc", "Swollen joint count (0–28)", .number(unitHint: "joints")),
            MedCalcInput("tjc", "Tender joint count (0–28)", .number(unitHint: "joints")),
            MedCalcInput("pga", "Patient global assessment (0–10)", .number(unitHint: "/10")),
            MedCalcInput("ega", "Physician global assessment (0–10)", .number(unitHint: "/10"))
        ],
        compute: { v in
            guard let sjc = v.number("sjc"), let tjc = v.number("tjc"),
                  let pga = v.number("pga"), let ega = v.number("ega") else { return "" }
            let cdai = sjc + tjc + pga + ega
            let interpretation: String
            switch cdai {
            case ...2.8: interpretation = "Remission"
            case 2.8...10: interpretation = "Low Disease Activity"
            case 10...22: interpretation = "Moderate Disease Activity"
            default: interpretation = "High Disease Activity"
            }
            return String(format: "CDAI: %.1f — %@", cdai, interpretation)
        }
    ),
    MedCalcSpec(
        fileName: "RheumatoidArthritisDAS28.htm",
        guide: """
        The Disease Activity Score 28 (DAS-28, ESR version) quantifies rheumatoid arthritis activity from joint counts, the erythrocyte sedimentation rate, and a patient global assessment.

        • Tender and swollen joint counts on the standard 28-joint exam (0–28 each).
        • ESR in mm/hr; patient global assessment as a 0–100 mm visual analog scale.

        Interpretation: <2.6 remission; ≥2.6–≤3.2 low disease activity; >3.2–≤5.1 moderate disease activity; >5.1 high disease activity.
        """,
        equation: "DAS-28 = 0.56·√TJC + 0.28·√SJC + 0.7·ln(ESR) + 0.014·PGA(mm)",
        inputs: [
            MedCalcInput("tjc", "Tender joint count (0–28)", .number(unitHint: "joints")),
            MedCalcInput("sjc", "Swollen joint count (0–28)", .number(unitHint: "joints")),
            MedCalcInput("esr", "ESR (mm/hr)", .number(unitHint: "mm/hr")),
            MedCalcInput("pga", "Patient global assessment (0–100 mm VAS)", .number(unitHint: "mm"))
        ],
        compute: { v in
            guard let tjc = v.number("tjc"), let sjc = v.number("sjc"),
                  let esr = v.number("esr"), let pga = v.number("pga") else { return "" }
            guard esr > 0 else { return "ESR must be greater than 0." }
            let das28 = 0.56 * sqrt(tjc) + 0.28 * sqrt(sjc) + 0.7 * log(esr) + 0.014 * pga
            let interpretation: String
            switch das28 {
            case ..<2.6: interpretation = "Remission"
            case 2.6...3.2: interpretation = "Low Disease Activity"
            case 3.2...5.1: interpretation = "Moderate Disease Activity"
            default: interpretation = "High Disease Activity"
            }
            return String(format: "DAS-28 (ESR): %.2f — %@", das28, interpretation)
        }
    )
]
