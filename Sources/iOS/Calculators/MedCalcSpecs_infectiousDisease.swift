import Foundation

/// Calculator specs for the infectiousDisease category.
let infectiousDiseaseCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "CentorMcIssacSoreThroatCriteria.htm",
        guide: """
        The Centor criteria with McIsaac modification estimate the probability of group A streptococcal pharyngitis. Examine the throat and score each finding, then enter the patient's age and temperature.

        Scoring:
        • Age under 15 adds 1 point; age 45 or older subtracts 1 point (ages 15–44 add nothing)
        • Temperature above 38°C adds 1 point
        • Absence of cough adds 1 point (cough present = 0 points)
        • Tender anterior cervical lymph nodes add 1 point
        • Tonsillar swelling or exudate adds 1 point

        Interpretation — total score:
        • 0 points: 2–3% chance of strep; no culture or antibiotics
        • 1 point: 4–6% chance of strep; no culture or antibiotics
        • 2 points: 10–12% chance of strep; culture and treat if positive
        • 3 points: 27–28% chance of strep; culture and treat if positive
        • 4 to 5 points: 38–63% chance of strep; culture and treat with antibiotic on clinical grounds

        A negative score (age ≥45 with no other findings) indicates a very low probability of streptococcal pharyngitis.
        """,
        equation: "Score = AgeFactor + TemperatureFactor + Cough + Tender Anterior Cervical Nodes + Tonsillar Swelling or Exudate",
        inputs: [
            MedCalcInput("age", "Age (years)", .number(unitHint: "years")),
            MedCalcInput("tempUnits", "Temperature units", .choice(options: ["°C", "°F"])),
            MedCalcInput("temperature", "Temperature", .number(unitHint: "body temperature")),
            MedCalcInput("cough", "Cough present?", .choice(options: ["Yes (0 pts)", "No (+1 pt)"])),
            MedCalcInput("nodes", "Tender anterior cervical nodes?", .yesNo),
            MedCalcInput("exudate", "Tonsillar swelling or exudate?", .yesNo)
        ],
        compute: { v in
            guard let age = v.number("age"), let tempRaw = v.number("temperature") else { return "" }
            let celsius = (v.selection("tempUnits") ?? 0) == 1 ? (tempRaw - 32.0) / 1.8 : tempRaw
            var score = 0.0
            if age < 15 { score += 1 } else if age >= 45 { score -= 1 }
            if celsius > 38 { score += 1 }
            if (v.selection("cough") ?? -1) == 1 { score += 1 } // "No cough" option
            if (v.selection("nodes") ?? 0) == 1 { score += 1 }
            if (v.selection("exudate") ?? 0) == 1 { score += 1 }
            let interpretation: String
            switch Int(score) {
            case 0: interpretation = "2–3% chance of strep; no culture or antibiotics"
            case 1: interpretation = "4–6% chance of strep; no culture or antibiotics"
            case 2: interpretation = "10–12% chance of strep; culture and treat if positive"
            case 3: interpretation = "27–28% chance of strep; culture and treat if positive"
            case 4...5: interpretation = "38–63% chance of strep; culture and treat with antibiotic on clinical grounds"
            default: interpretation = "below the published scoring range — very low probability of streptococcal pharyngitis"
            }
            return String(format: "Sore Throat Score: %.0f points\n%@", score, interpretation)
        }
    ),

    MedCalcSpec(
        fileName: "CommunityAcqPneumonia.htm",
        guide: """
        The Pneumonia Severity Index (PSI) predicts 30-day mortality in adults with community-acquired pneumonia and guides disposition. Enter the patient's sex and age, then check every comorbidity, exam finding, and lab/radiographic abnormality that is present — each checked item adds its listed points.

        Interpretation — total score:
        • Below 51 (Class I): 0.1% mortality — outpatient management
        • 51 to 70 (Class II): 0.6% mortality
        • 71 to 90 (Class III): 0.9% mortality
        • 91 to 130 (Class IV): 9.3% mortality
        • 131 to 395 (Class V): 27.0% mortality

        The PSI is validated for adults; do not use it in children or pregnant patients.
        """,
        equation: "Score = Sex + Age(×1) + Σ checked findings",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Male (0)", "Female (−10)"])),
            MedCalcInput("age", "Age — 1 point per year", .number(unitHint: "years")),
            MedCalcInput("nursingHome", "Nursing home resident (+10)", .yesNo),
            MedCalcInput("neoplastic", "Neoplastic disease (+30)", .yesNo),
            MedCalcInput("liver", "Liver disease (+20)", .yesNo),
            MedCalcInput("chf", "Congestive heart failure (+10)", .yesNo),
            MedCalcInput("cerebrovascular", "Cerebrovascular disease (+10)", .yesNo),
            MedCalcInput("renal", "Renal disease (+10)", .yesNo),
            MedCalcInput("ams", "Altered mental status (+20)", .yesNo),
            MedCalcInput("respRate", "Respiratory rate ≥30/minute (+20)", .yesNo),
            MedCalcInput("sbp", "Systolic blood pressure <90 mmHg (+20)", .yesNo),
            MedCalcInput("tempExtremes", "Temperature <35°C or ≥40°C (+15)", .yesNo),
            MedCalcInput("pulse", "Pulse ≥125/minute (+10)", .yesNo),
            MedCalcInput("ph", "Arterial pH <7.35 (+30)", .yesNo),
            MedCalcInput("bun", "Blood urea nitrogen ≥30 mg/dL (11 mmol/L) (+20)", .yesNo),
            MedCalcInput("sodium", "Sodium <130 mEq/L (+20)", .yesNo),
            MedCalcInput("glucose", "Glucose ≥250 mg/dL (14 mmol/L) (+10)", .yesNo),
            MedCalcInput("hematocrit", "Hematocrit <30 percent (+10)", .yesNo),
            MedCalcInput("pao2", "PaO₂ <60 mmHg or O₂ saturation <90% (+10)", .yesNo),
            MedCalcInput("effusion", "Pleural effusion (+10)", .yesNo)
        ],
        compute: { v in
            guard let sex = v.selection("sex"), let age = v.number("age") else { return "" }
            var score = (sex == 1 ? -10.0 : 0.0) + age
            let findings: [(String, Double)] = [
                ("nursingHome", 10), ("neoplastic", 30), ("liver", 20), ("chf", 10),
                ("cerebrovascular", 10), ("renal", 10), ("ams", 20), ("respRate", 20),
                ("sbp", 20), ("tempExtremes", 15), ("pulse", 10), ("ph", 30),
                ("bun", 20), ("sodium", 20), ("glucose", 10), ("hematocrit", 10),
                ("pao2", 10), ("effusion", 10)
            ]
            for (id, points) in findings where (v.selection(id) ?? 0) == 1 { score += points }
            let interpretation: String
            if score < 51 {
                interpretation = "Class I — 0.1% mortality"
            } else if score <= 70 {
                interpretation = "Class II — 0.6% mortality"
            } else if score <= 90 {
                interpretation = "Class III — 0.9% mortality"
            } else if score <= 130 {
                interpretation = "Class IV — 9.3% mortality"
            } else if score <= 395 {
                interpretation = "Class V — 27.0% mortality"
            } else {
                interpretation = "above the published interpretation bands"
            }
            return String(format: "PSI Score: %.0f\n%@", score, interpretation)
        }
    ),

    MedCalcSpec(
        fileName: "CSF_WBC.htm",
        guide: """
        Corrects the CSF white blood cell count for blood contamination when a traumatic tap is suspected. Enter all four counts from the same specimen pair; the formula subtracts the WBCs that entered the CSF with the red cells, using the blood's WBC-to-RBC ratio.

        Units: enter WBC and RBC counts in cells/mm³ (µL), except whole-blood RBC count which is conventionally reported in million cells/mm³ — enter it as reported by the lab.
        """,
        equation: "WBC = WBCCSF − ((WBCBlood × RBCCSF) / (RBCBlood × 1000000))",
        inputs: [
            MedCalcInput("wbcCsf", "WBC CSF (cells/mm³)", .number(unitHint: "cells/mm³")),
            MedCalcInput("wbcBlood", "WBC Blood (cells/mm³)", .number(unitHint: "cells/mm³")),
            MedCalcInput("rbcCsf", "RBC CSF (cells/mm³)", .number(unitHint: "cells/mm³")),
            MedCalcInput("rbcBlood", "RBC Blood (million cells/mm³)", .number(unitHint: "million cells/mm³"))
        ],
        compute: { v in
            guard let wbcCsf = v.number("wbcCsf"), let wbcBlood = v.number("wbcBlood"),
                  let rbcCsf = v.number("rbcCsf"), let rbcBlood = v.number("rbcBlood"),
                  rbcBlood > 0 else { return "" }
            let corrected = wbcCsf - (wbcBlood * rbcCsf) / (rbcBlood * 1_000_000.0)
            return String(format: "Corrected CSF WBC: %.0f cells/mm³", max(corrected, 0))
        }
    )
]
