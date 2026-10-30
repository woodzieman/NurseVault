import Foundation

/// Calculator specs for the pharmacologyToxicology category.
let pharmacologyToxicologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "acetaminophentox2023.htm",
        guide: """
        The 2023 US/Canadian consensus acetaminophen treatment line (Dart 2023) replaces the older Rumack-Matthew nomogram. Enter the time in hours since ingestion and the serum acetaminophen level drawn at that time — only results from 4 to 24 hours after ingestion are valid for this tool.

        The calculator compares the measured level against two thresholds at that hour:
        • Treatment threshold (half of the high-risk line): above it, start acetylcysteine
        • High-risk threshold: above it, there is a high risk of serious toxicity and an increased acetylcysteine dose may be appropriate

        Some patients still require treatment even below the thresholds (for example, extended-release product ingestion); consultation with a poison control center or clinical toxicologist is highly recommended.
        """,
        equation: "ToxLevel = e^(5.703782 − (hours−4) × 0.1732868); RxLevel = ToxLevel ÷ 2; µmol/L = mcg/mL × 6.62",
        inputs: [
            MedCalcInput("time", "Time after ingestion (4–24 hours)", .number(unitHint: "hours")),
            MedCalcInput("levelUnits", "Acetaminophen level units", .choice(options: ["mcg/mL", "µmol/L"])),
            MedCalcInput("level", "Serum acetaminophen level", .number(unitHint: "measured at the time entered above"))
        ],
        compute: { v in
            guard let hours = v.number("time"), let levelRaw = v.number("level") else { return "" }
            guard (4...24).contains(hours) else { return "Only 4–24 hour results are valid for this nomogram." }
            let levelMcgMl = (v.selection("levelUnits") ?? 0) == 1 ? levelRaw / 6.62 : levelRaw
            let toxLevel = exp(5.703782 - (hours - 4.0) * 0.1732868)
            let rxLevel = toxLevel * 0.5
            func both(_ mcgMl: Double) -> String {
                String(format: "%.1f mcg/mL [%.1f µmol/L]", mcgMl, mcgMl * 6.62)
            }
            let treatment = "treatment with acetylcysteine should be initiated for this overdose"
            if levelMcgMl < rxLevel {
                return """
                At \(String(format: "%.1f", hours)) h after ingestion the level is below the treatment threshold of \(both(rxLevel)).

                Some patients may still require treatment with acetylcysteine (eg, extended-release product); consultation with a poison control center or clinical toxicologist is highly recommended.

                Because the high-risk threshold at this hour is \(both(toxLevel)), there is lower risk of significant toxicity.
                """
            } else if levelMcgMl < toxLevel {
                return """
                At \(String(format: "%.1f", hours)) h after ingestion the level is ABOVE the treatment threshold of \(both(rxLevel)); \(treatment).

                Because the high-risk threshold at this hour is \(both(toxLevel)), there is a lower risk of significant toxicity.
                """
            } else {
                return """
                At \(String(format: "%.1f", hours)) h after ingestion the level is ABOVE the treatment threshold of \(both(rxLevel)); \(treatment).

                Because the high-risk threshold at this hour is \(both(toxLevel)), there is a HIGH RISK OF SERIOUS TOXICITY. An increased dose of acetylcysteine may be appropriate. Consultation with a poison control center or clinical toxicologist is highly recommended.
                """
            }
        }
    )
]
