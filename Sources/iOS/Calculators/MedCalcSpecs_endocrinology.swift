import Foundation

/// Calculator specs for the endocrinology category.
let endocrinologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "AndrogenDef.htm",
        guide: """
        The ADAM (Androgen Deficiency in Aging Males) screener identifies men who should be tested for androgen deficiency. Ask the patient to answer YES/NO to each statement below — 2 major criteria plus 7 minor criteria.

        Interpretation: a positive screen (≥1 major criterion, or ≥3 minor criteria) means consider testing total testosterone in the morning; confirm with repeat testing before starting therapy.
        """,
        inputs: [
            MedCalcInput("cc1", "MAJOR — Decreased libido?", .yesNo),
            MedCalcInput("cc2", "MAJOR — Decrease in erection strength?", .yesNo),
            MedCalcInput("cc3", "Minor — Decrease in strength, endurance or both?", .yesNo),
            MedCalcInput("cc4", "Minor — Loss of body height?", .yesNo),
            MedCalcInput("cc5", "Minor — Decreased enjoyment of life?", .yesNo),
            MedCalcInput("cc6", "Minor — Sadness, grumpiness, or both?", .yesNo),
            MedCalcInput("cc7", "Minor — Recent deterioration in the ability to play sports?", .yesNo),
            MedCalcInput("cc8", "Minor — Tendency to fall asleep after dinner?", .yesNo),
            MedCalcInput("cc9", "Minor — Recent deterioration in work performance?", .yesNo)
        ],
        compute: { v in
            let major = ["cc1", "cc2"].reduce(0) { $0 + (v.selection($1) ?? 0) }
            let minor = ["cc3", "cc4", "cc5", "cc6", "cc7", "cc8", "cc9"].reduce(0) { $0 + (v.selection($1) ?? 0) }
            let verdict: String
            if major >= 1 || minor >= 3 {
                verdict = "Consider Testing for Possible Androgen Deficiency"
            } else {
                verdict = "Insufficient — no positive screen"
            }
            return "\(verdict)\nwith:\n\(major) Major Criteria\n\(minor) Minor Criteria"
        }
    ),

    MedCalcSpec(
        fileName: "DMSelfAssess.htm",
        guide: """
        Patient self-assessment score for diabetes risk (Bang 2009). Enter the patient's age group, sex, weight in pounds, and height in inches, then answer the three yes/no questions.

        Interpretation — Diabetes Risk Score:
        • ≥5: increased risk of undiagnosed diabetes
        • 4: increased risk of pre-diabetes or undiagnosed diabetes
        • <4: below the increased-risk threshold (reassess with new risk factors)
        """,
        equation: "BMI = (Weight_lb/2.205)/(Height_in/39.37)²; Score = BMIPoints + AgePts + SexPts + FamilyHistory − Active(1 if yes) + Hypertension",
        inputs: [
            MedCalcInput("age", "Age group", .choice(options: ["<40 years (0)", "40–49 years (1)", "50–59 years (2)", "≥60 years (3)"])),
            MedCalcInput("sex", "Sex", .choice(options: ["Female (0)", "Male (1)"])),
            MedCalcInput("weight", "Weight (lb)", .number(unitHint: "pounds")),
            MedCalcInput("height", "Height (in)", .number(unitHint: "inches")),
            MedCalcInput("active", "Physically active?", .yesNo),
            MedCalcInput("htn", "History of hypertension?", .yesNo),
            MedCalcInput("fmh", "Family history of diabetes?", .yesNo)
        ],
        compute: { v in
            guard let age = v.selection("age"), let sex = v.selection("sex"),
                  let weight = v.number("weight"), let height = v.number("height"),
                  weight > 0, height > 0 else { return "" }
            let bmi = (weight / 2.205) / pow(height / 39.37, 2)
            let bmiPoints: Int
            switch bmi {
            case ..<25: bmiPoints = 0
            case ..<30: bmiPoints = 1
            case ..<40: bmiPoints = 2
            default: bmiPoints = 3
            }
            let activePts = (v.selection("active") ?? 0) == 1 ? -1 : 0
            let score = bmiPoints + age + sex + (v.selection("fmh") ?? 0) + activePts + (v.selection("htn") ?? 0)
            let interpretation: String
            if score >= 5 {
                interpretation = "Increased risk of undiagnosed diabetes"
            } else if score == 4 {
                interpretation = "Increased risk of pre-diabetes or undiagnosed diabetes"
            } else {
                interpretation = "Below the increased-risk threshold"
            }
            return String(format: "BMI: %.1f kg/m² (%d pts)\nDiabetes Risk Score: %d\n%@", bmi, bmiPoints, score, interpretation)
        }
    ),

    MedCalcSpec(
        fileName: "GlycemicAssessment.htm",
        guide: """
        Converts hemoglobin A1C between reporting scales and to estimated average glucose (eAG). Enter ONLY ONE of the four values — the other three are calculated from it.

        • A1C %DCCT is the percent reported by most US labs (6% ≈ 42 mmol/mol IFCC)
        • eAG mg/dL = 28.7 × A1C(%) − 46.7; eAG mmol/L = eAG(mg/dL)/18.015

        Interpretation: A1C <5.7% is normal, 5.7–6.4% prediabetes, ≥6.5% diabetes range (ADA).
        """,
        equation: "IFCC mmol/mol = 10.929×(%DCCT − 2.15); eAG mg/dL = 28.7×%DCCT − 46.7; eAG mmol/L = eAG/18.015",
        inputs: [
            MedCalcInput("h1", "A1C (DCCT)", .number(unitHint: "% — enter only one value")),
            MedCalcInput("h2", "A1C (IFCC, SI units)", .number(unitHint: "mmol/mol")),
            MedCalcInput("ag", "Estimated average glucose", .number(unitHint: "mg/dL")),
            MedCalcInput("ags", "Estimated average glucose (SI units)", .number(unitHint: "mmol/L"))
        ],
        compute: { v in
            let filled = ["h1", "h2", "ag", "ags"].filter { v.number($0) != nil }
            guard filled.count == 1 else { return "" }
            var h1: Double?
            switch filled[0] {
            case "h1": h1 = v.number("h1")
            case "h2": h1 = (v.number("h2")! / 10.929) + 2.15
            case "ag": h1 = (v.number("ag")! + 46.7) / 28.7
            default: h1 = ((v.number("ags")! * 18.015) + 46.7) / 28.7
            }
            guard let pct = h1 else { return "" }
            let ifcc = 10.929 * (pct - 2.15)
            let eag = 28.7 * pct - 46.7
            let eagSI = eag / 18.015
            return String(
                format: "A1C (DCCT): %.1f%%\nA1C (IFCC): %.1f mmol/mol\nEstimated average glucose: %.1f mg/dL\nEstimated average glucose (SI): %.1f mmol/L",
                pct, ifcc, eag, eagSI
            )
        }
    )
]
