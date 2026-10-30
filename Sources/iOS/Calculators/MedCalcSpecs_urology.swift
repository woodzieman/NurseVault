import Foundation

/// Calculator specs for the urology category.
let urologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "ProstatismSymptomScore.htm",
        guide: """
        The International Prostate Symptom Score (IPSS) screens men for lower urinary tract symptoms of benign prostatic hyperplasia. Ask the patient to rate each symptom over the PAST MONTH using the options shown; each answer is worth 0–5 points.

        Interpretation — total score out of 35:
        • 0–7: Minimal symptoms
        • 8–19: Moderate symptoms
        • 20–35: Severe symptoms (consider urology referral)
        """,
        inputs: {
            let freqOptions = [
                "None (0)",
                "Less than once every 5 times (1)",
                "Less than once every 2 times (2)",
                "About once every 2 times (3)",
                "More than once every 2 times (4)",
                "Almost always (5)"
            ]
            let nightOptions = [
                "None (0)",
                "Once (1)",
                "Twice (2)",
                "3 Times (3)",
                "4 Times (4)",
                "5 times or more (5)"
            ]
            return [
                MedCalcInput("q1", "Incomplete emptying: bladder not completely empty after urination?", .score(options: freqOptions)),
                MedCalcInput("q2", "Frequency: had to void again within 2 hours of finishing?", .score(options: freqOptions)),
                MedCalcInput("q3", "Intermittency: urine stream stopped and started during voiding?", .score(options: freqOptions)),
                MedCalcInput("q4", "Urgency: found it hard to hold back urine?", .score(options: freqOptions)),
                MedCalcInput("q5", "Weak stream: weak or reduced urinary stream?", .score(options: freqOptions)),
                MedCalcInput("q6", "Straining: had to push/strain to start urination?", .score(options: freqOptions)),
                MedCalcInput("q7", "Nocturia: times you got up at night to void?", .score(options: nightOptions))
            ]
        }(),
        compute: { v in
            let ids = ["q1", "q2", "q3", "q4", "q5", "q6", "q7"]
            guard ids.allSatisfy({ v.selection($0) != nil }) else { return "" }
            let total = ids.reduce(0) { $0 + (v.selection($1) ?? 0) }
            let severity: String
            switch total {
            case 0...7: severity = "Minimal symptoms"
            case 8...19: severity = "Moderate symptoms"
            default: severity = "Severe symptoms — consider urology referral"
            }
            return "IPSS Score: \(total)/35\n\(severity)"
        }
    )
]
