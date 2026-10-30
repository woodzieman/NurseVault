import Foundation

/// Calculator specs for the sleepMedicine category.
let sleepMedicineCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "epworthsleepscale.htm",
        guide: """
        The Epworth Sleepiness Scale (ESS) screens for excessive daytime sleepiness, commonly used to evaluate suspected obstructive sleep apnea. Ask the patient how likely they are to DOZE or fall asleep in each of these 8 everyday situations — based on their experience over the past few months while awake during the day.

        Interpretation — total score out of 24:
        • 1–6: Normal sleep
        • 7–8: Average (borderline) sleepiness
        • 9–24: Abnormal (possibly pathologic) sleepiness — consider polysomnography
        """,
        inputs: {
            let options = [
                "No chance of dozing (0)",
                "Slight chance of dozing (1)",
                "Moderate chance of dozing (2)",
                "High chance of dozing (3)"
            ]
            return [
                MedCalcInput("q1", "Sitting and reading", .score(options: options)),
                MedCalcInput("q2", "Watching television", .score(options: options)),
                MedCalcInput("q3", "Sitting inactive in a public place (theater, meeting)", .score(options: options)),
                MedCalcInput("q4", "As a passenger in a car for an hour without stopping", .score(options: options)),
                MedCalcInput("q5", "Lying down in the afternoon to rest", .score(options: options)),
                MedCalcInput("q6", "Sitting and talking to someone", .score(options: options)),
                MedCalcInput("q7", "Sitting quietly after lunch (no alcohol)", .score(options: options)),
                MedCalcInput("q8", "In a car, stopped for a few minutes in traffic", .score(options: options))
            ]
        }(),
        compute: { v in
            let ids = ["q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8"]
            guard ids.allSatisfy({ v.selection($0) != nil }) else { return "" }
            let total = ids.reduce(0) { $0 + (v.selection($1) ?? 0) }
            let interpretation: String
            switch total {
            case ...6: interpretation = "Normal sleep"
            case 7...8: interpretation = "Average (borderline) sleepiness"
            default: interpretation = "Abnormal (possibly pathologic) sleepiness — consider polysomnography"
            }
            return "ESS Score: \(total)/24\n\(interpretation)"
        }
    )
]
