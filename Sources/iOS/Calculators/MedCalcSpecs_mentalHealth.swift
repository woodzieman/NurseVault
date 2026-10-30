import Foundation

/// Calculator specs for the mental health & screening category.
let mentalHealthCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "AlcoholScreen.htm",
        guide: """
        The AUDIT alcohol consumption screening questionnaire (World Health Organization). Ask each question and select the patient's answer — points are shown with each option. Sum all ten items for the total score.

        Interpretation — total score:
        • 0 to 7 points: Low risk
        • 8 to 15 points: Medium risk
        • 16 to 19 points: High risk
        • 20 to 40 points: Addiction likely
        """,
        inputs: [
            MedCalcInput("q1", "1) How often do you drink anything containing alcohol?", .score(options: ["Never (0)", "Monthly or less (1)", "2–4 times a month (2)", "2–3 times a week (3)", "4+ times a week (4)"])),
            MedCalcInput("q2", "2) How many drinks do you have on a typical day?", .score(options: ["1 or 2 (0)", "3 or 4 (1)", "5 or 6 (2)", "7 to 9 (3)", "10 or more (4)"])),
            MedCalcInput("q3", "3) How often do you have 5 or more drinks on one occasion?", .score(options: ["Never (0)", "Less than monthly (1)", "Monthly (2)", "Weekly (3)", "Daily or almost daily (4)"])),
            MedCalcInput("q4", "4) In the last year, how often were you unable to stop drinking once started?", .score(options: ["Never (0)", "Less than monthly (1)", "Monthly (2)", "Weekly (3)", "Daily or almost daily (4)"])),
            MedCalcInput("q5", "5) In the last year, how often did you fail to do what was normally expected because of drinking?", .score(options: ["Never (0)", "Less than monthly (1)", "Monthly (2)", "Weekly (3)", "Daily or almost daily (4)"])),
            MedCalcInput("q6", "6) In the last year, how often did you need a morning drink to get going after heavy drinking?", .score(options: ["Never (0)", "Less than monthly (1)", "Monthly (2)", "Weekly (3)", "Daily or almost daily (4)"])),
            MedCalcInput("q7", "7) In the last year, how often did you feel guilty or remorseful after drinking?", .score(options: ["Never (0)", "Less than monthly (1)", "Monthly (2)", "Weekly (3)", "Daily or almost daily (4)"])),
            MedCalcInput("q8", "8) In the last year, how often did you forget what happened because of drinking?", .score(options: ["Never (0)", "Less than monthly (1)", "Monthly (2)", "Weekly (3)", "Daily or almost daily (4)"])),
            MedCalcInput("q9", "9) Have you or someone else been injured as a result of your drinking?", .score(options: ["No (0)", "Yes, but not in the last year (2)", "Yes, during the last year (4)"])),
            MedCalcInput("q10", "10) Has a relative, friend, or health care worker been concerned about your drinking or suggested you cut back?", .score(options: ["No (0)", "Yes, but not in the last year (2)", "Yes, during the last year (4)"]))
        ],
        compute: { v in
            let points = [0.0, 1, 2, 3, 4]
            var score = 0.0
            for i in 1...8 {
                guard let sel = v.selection("q\(i)") else { return "" }
                score += points[sel]
            }
            let injuryPoints = [0.0, 2, 4]
            guard let q9 = v.selection("q9"), let q10 = v.selection("q10") else { return "" }
            score += injuryPoints[q9] + injuryPoints[q10]
            let risk: String
            switch Int(score) {
            case 0...7: risk = "Low risk"
            case 8...15: risk = "Medium risk"
            case 16...19: risk = "High risk"
            default: risk = "Addiction likely"
            }
            return String(format: "Alcohol Screen Score: %.0f points — %@", score, risk)
        }
    )
]
