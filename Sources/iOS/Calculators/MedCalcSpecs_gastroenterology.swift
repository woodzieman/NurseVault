import Foundation

/// Calculator specs for the gastroenterology category.
let gastroenterologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "abc.htm",
        guide: """
        The ABC score predicts 30-day mortality in acute upper and lower gastrointestinal bleeding (Laursen 2021). Enter the patient's age, serum urea in mg/dL, albumin in g/L, creatinine in µmol/L, answer the three yes/no questions, and enter the ASA physical status class (I–V).

        Interpretation — total score:
        • 0–3 points: 0.7% 30-day mortality
        • 4–7 points: 9.3% 30-day mortality
        • 8–18 points: 34% 30-day mortality
        """,
        equation: "ABC = AgeFactor + UreaFactor + AlbuminFactor + CreatinineFactor + AMS(2) + Cirrhosis(2) + MetastaticCancer(4) + ASAfactor",
        inputs: [
            MedCalcInput("age", "Age (years)", .number(unitHint: "years")),
            MedCalcInput("urea", "Urea (mg/dL)", .number(unitHint: "mg/dL — >60 mg/dL scores 1 point")),
            MedCalcInput("albumin", "Albumin (g/L)", .number(unitHint: "g/L — <30 scores 2 points")),
            MedCalcInput("creatinine", "Creatinine (µmol/L)", .number(unitHint: "µmol/L — ≥100 = 1 pt, >150 = 2 pts")),
            MedCalcInput("ams", "Altered mental status?", .yesNo),
            MedCalcInput("cirrhosis", "Cirrhosis?", .yesNo),
            MedCalcInput("metastatic", "Metastatic cancer?", .yesNo),
            MedCalcInput("asa", "ASA physical status class (I–V)", .number(unitHint: "1-5"))
        ],
        compute: { v in
            guard let age = v.number("age"), let urea = v.number("urea"),
                  let albumin = v.number("albumin"), let creatinine = v.number("creatinine"),
                  let asa = v.number("asa") else { return "" }
            var score = 0.0
            if age >= 75 { score += 2 } else if age >= 60 { score += 1 }
            if urea / 6.0 > 10 { score += 1 } // internal threshold in mmol/L
            if albumin < 30 { score += 2 }
            if creatinine > 150 { score += 2 } else if creatinine >= 100 { score += 1 }
            if (v.selection("ams") ?? 0) == 1 { score += 2 }
            if (v.selection("cirrhosis") ?? 0) == 1 { score += 2 }
            if (v.selection("metastatic") ?? 0) == 1 { score += 4 }
            if asa >= 4 { score += 3 } else if asa >= 3 { score += 1 }
            let mortality: String
            switch Int(score) {
            case 0...3: mortality = "0.7% 30-day mortality"
            case 4...7: mortality = "9.3% 30-day mortality"
            default: mortality = "34% 30-day mortality"
            }
            return String(format: "ABC Score: %.0f\n%@", score, mortality)
        }
    ),

    MedCalcSpec(
        fileName: "BarrettProgRisk.htm",
        guide: """
        Decision tool for the risk of progression in Barrett's esophagus (Weston 2004). Answer the two questions from the patient's endoscopy and biopsy results to read off the published risk of progression.

        Risk depends on lesion length (<6 cm vs ≥6 cm) and the highest-grade dysplasia found on biopsy.
        """,
        inputs: [
            MedCalcInput("length", "Length of Barrett lesion", .choice(options: ["<6 cm", "≥6 cm"])),
            MedCalcInput("dysplasia", "Dysplasia on biopsy", .choice(options: ["None", "Low grade", "High grade unifocal"]))
        ],
        compute: { v in
            guard let length = v.selection("length"), let dysplasia = v.selection("dysplasia") else { return "" }
            let risksShort = ["2.4%", "5.3%", "66.7%"]
            let risksLong = ["6.8%", "35%", "77.8%"]
            let table = length == 0 ? risksShort : risksLong
            return String(format: "%@ Barrett lesion with %@ dysplasia:\n%.1f%% Risk of progression",
                          length == 0 ? "<6 cm" : "≥6 cm",
                          ["None", "Low grade", "High grade unifocal"][dysplasia],
                          Double(table[dysplasia].replacingOccurrences(of: "%", with: ""))!)
        }
    ),

    MedCalcSpec(
        fileName: "CDAI.htm",
        guide: """
        The Crohn's Disease Activity Index (CDAI) quantifies disease activity from the patient's 7-day symptom history, exam findings, and labs. Score each item as shown; points accumulate to a total out of ~1100.

        Interpretation — total score:
        • 0–149: Asymptomatic remission (note: patients needing steroids to stay asymptomatic are "steroid dependent," not in remission)
        • 150–220: Mildly to moderately active Crohn's disease
        • 221–450: Moderately to severely active Crohn's disease
        • 451–1100: Severely active to fulminant disease

        Hematocrit deviation = difference from 47% (males) or 42% (females). Weight deviation % = (1 − weight/standard weight) × 100; positive values mean weight loss.
        """,
        inputs: [
            MedCalcInput("stools", "Average liquid/soft stools per day over seven days (14 pts each)", .number(unitHint: "stools/day")),
            MedCalcInput("antidiarrheal", "Using diphenoxylate or loperamide for diarrhea? (+30)", .yesNo),
            MedCalcInput("pain", "Average abdominal pain rating over seven days", .choice(options: ["None (0)", "Mild pain (35)", "Moderate pain (70)", "Severe pain (105)"])),
            MedCalcInput("wellbeing", "General well being each day over seven days", .choice(options: ["Well (0)", "Slightly below average (49)", "Poor (98)", "Very poor (147)", "Terrible (196)"])),
            MedCalcInput("arthritis", "Arthritis or arthralgia? (+20)", .yesNo),
            MedCalcInput("iritis", "Iritis or uveitis? (+20)", .yesNo),
            MedCalcInput("skin", "Erythema nodosum, pyoderma gangrenosum or aphthous stomatitis? (+20)", .yesNo),
            MedCalcInput("anal", "Anal fissure, fistula or abscess? (+20)", .yesNo),
            MedCalcInput("otherfistula", "Other fistula? (+20)", .yesNo),
            MedCalcInput("fever", "Temperature over 100°F (37.8°C) in the last week? (+20)", .yesNo),
            MedCalcInput("mass", "Finding of an abdominal mass", .choice(options: ["No mass (0)", "Possible mass (20)", "Definite mass (50)"])),
            MedCalcInput("hctdev", "Absolute hematocrit deviation from 47% (M) / 42% (F), in % (6 pts each)", .number(unitHint: "%")),
            MedCalcInput("wtdev", "Percentage deviation from standard weight, in % (1 pt each; positive = loss)", .number(unitHint: "%"))
        ],
        compute: { v in
            guard let stools = v.number("stools"), let pain = v.selection("pain"),
                  let wellbeing = v.selection("wellbeing"), let mass = v.selection("mass"),
                  let hctdev = v.number("hctdev"), let wtdev = v.number("wtdev") else { return "" }
            var score = stools * 14 + Double(pain) * 35 + Double(wellbeing) * 49 + Double(mass) * 20
                + hctdev * 6 + wtdev
            if (v.selection("antidiarrheal") ?? 0) == 1 { score += 30 }
            for id in ["arthritis", "iritis", "skin", "anal", "otherfistula", "fever"] {
                if (v.selection(id) ?? 0) == 1 { score += 20 }
            }
            let interpretation: String
            switch Int(score) {
            case ...149: interpretation = "Asymptomatic remission"
            case 150...220: interpretation = "Mildly to moderately active Crohn's disease"
            case 221...450: interpretation = "Moderately to severely active Crohn's disease"
            default: interpretation = "Severely active to fulminant disease"
            }
            return String(format: "CDAI: %.0f\n%@", score, interpretation)
        }
    )
]
