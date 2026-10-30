import Foundation

/// Calculator specs for the criticalCare category.
let criticalCareCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "ApacheScore.htm",
        guide: """
        The APACHE II score (Acute Physiology and Chronic Health Evaluation II) estimates ICU mortality from 12 acute physiology measurements, the patient's age, and chronic health status. For each item, select the range that matches the worst value recorded in the first 24 hours of ICU care — points are shown with each option.

        Interpretation — total score (approximate mortality):
        • 0 to 4: 4% non-op, 1% post-op
        • 5 to 9: 8% non-op, 3% post-op
        • 10 to 14: 15% non-op, 7% post-op
        • 15 to 19: 24% non-op, 12% post-op
        • 20 to 24: 40% non-op, 30% post-op
        • 25 to 29: 55% non-op, 35% post-op
        • 30 to 34: approximately 73% both
        • 35 to 100: 85% non-op, 88% post-op
        """,
        inputs: [
            MedCalcInput("temp", "Temperature (°C)", .score(options: ["≥41 (4)", "39–40.9 (3)", "38.5–38.9 (1)", "36–38.4 (0)", "34–35.9 (1)", "32–33.9 (2)", "30–31.9 (3)", "≤29.9 (4)"])),
            MedCalcInput("map", "Mean arterial pressure (mmHg)", .score(options: ["≥160 (4)", "130–159 (3)", "110–129 (2)", "70–109 (0)", "50–69 (2)", "≤49 (4)"])),
            MedCalcInput("hr", "Heart rate (beats/min)", .score(options: ["≥180 (4)", "140–179 (3)", "110–139 (2)", "70–109 (0)", "55–69 (2)", "40–54 (3)", "≤39 (4)"])),
            MedCalcInput("rr", "Respiratory rate (breaths/min)", .score(options: ["≥50 (4)", "35–49 (3)", "25–34 (1)", "12–24 (0)", "10–11 (1)", "6–9 (2)", "≤5 (4)"])),
            MedCalcInput("oxygenation", "A-aDO₂ (FiO₂>50%) or PaO₂ (FiO₂<50%)", .score(options: ["≥500 (4)", "350–499 (3)", "200–349 (2)", "<200, or PaO₂ >70 (0)", "PaO₂ 61–70 (1)", "PaO₂ 55–60 (3)", "PaO₂ <55 (4)"])),
            MedCalcInput("ph", "Arterial pH or HCO₃⁻", .score(options: ["pH ≥7.7 or HCO₃ ≥52 (4)", "pH 7.6–7.69 or HCO₃ 41–51.9 (3)", "pH 7.5–7.59 or HCO₃ 32–40.9 (1)", "pH 7.33–7.49 or HCO₃ 22–31.9 (0)", "pH 7.25–7.32 or HCO₃ 18–21.9 (2)", "pH 7.15–7.24 or HCO₃ 15–17.9 (3)", "pH <7.15 or HCO₃ <15 (4)"])),
            MedCalcInput("na", "Serum Na⁺ (mEq/L)", .score(options: ["≥180 (4)", "160–179 (3)", "155–159 (2)", "150–154 (1)", "130–149 (0)", "120–129 (2)", "111–119 (3)", "≤110 (4)"])),
            MedCalcInput("k", "Serum K⁺ (mEq/L)", .score(options: ["≥7 (4)", "6–6.9 (3)", "5.5–5.9 (1)", "3.5–5.4 (0)", "3–3.4 (1)", "2.5–2.9 (2)", "<2.5 (4)"])),
            MedCalcInput("creatinine", "Serum creatinine (mg/dL; ARF = acute renal failure)", .score(options: ["≥3.5 (4)", ">3.5 in ARF (8)", "2–3.4 (3)", "2–3.4 in ARF (6)", "1.5–1.9 (2)", "1.5–1.9 in ARF (4)", "0.6–1.4 (0)", "<0.6 (2)"])),
            MedCalcInput("hematocrit", "Hematocrit (%)", .score(options: ["≥60 (4)", "50–59.9 (2)", "46–49.9 (1)", "30–45.9 (0)", "20–29.9 (2)", "<20 (4)"])),
            MedCalcInput("wbc", "WBC count (×10⁹/L)", .score(options: ["≥40 (4)", "20–39.9 (2)", "15–19.9 (1)", "3–14.9 (0)", "1–2.9 (2)", "<1 (4)"])),
            MedCalcInput("gcs", "Glasgow Coma Score", .score(options: ["15 (0)", "14 (1)", "13 (2)", "12 (3)", "11 (4)", "10 (5)", "9 (6)", "8 (7)", "7 (8)", "6 (9)", "5 (10)", "4 (11)", "≤3 (12)"])),
            MedCalcInput("age", "Age (years)", .score(options: ["≥75 (6)", "65–74 (5)", "55–64 (3)", "45–54 (2)", "≤44 (0)"])),
            MedCalcInput("chronic", "Chronic health problems / surgery type (cirrhosis, NYHA IV heart failure, severe COPD, dialysis, or immunocompromised)", .choice(options: ["None (0)", "Non-surgical (5)", "Emergent operation (5)", "Elective operation (2)"]))
        ],
        compute: { v in
            let items = ["temp", "map", "hr", "rr", "oxygenation", "ph", "na", "k", "creatinine", "hematocrit", "wbc", "gcs", "age"]
            var score = 0.0
            for id in items {
                guard let sel = v.selection(id) else { return "" }
                score += Double(sel)
            }
            guard let chronic = v.selection("chronic") else { return "" }
            score += [0.0, 5, 5, 2][chronic]
            let mortality: String
            switch Int(score) {
            case 0...4: mortality = "4% non-op, 1% post-op"
            case 5...9: mortality = "8% non-op, 3% post-op"
            case 10...14: mortality = "15% non-op, 7% post-op"
            case 15...19: mortality = "24% non-op, 12% post-op"
            case 20...24: mortality = "40% non-op, 30% post-op"
            case 25...29: mortality = "55% non-op, 35% post-op"
            case 30...34: mortality = "approximately 73% both"
            default: mortality = "85% non-op, 88% post-op"
            }
            return String(format: "APACHE II Score: %.0f\nApproximate mortality: %@", score, mortality)
        }
    ),

    MedCalcSpec(
        fileName: "BISAPScore.htm",
        guide: """
        The Bedside Index for Severity in Acute Pancreatitis (BISAP) predicts mortality using five bedside findings — no labs or imaging required beyond the listed items. Check each finding present at presentation; one point per item, total out of 5.

        Interpretation:
        • 0 to 2 points: lower mortality (<2 percent)
        • 3 to 5 points: higher mortality (>15 percent)
        """,
        inputs: [
            MedCalcInput("bun", "BUN >25 mg/dL (8.9 mmol/L)", .yesNo),
            MedCalcInput("ams", "Abnormal mental status (Glasgow Coma Score <15)", .yesNo),
            MedCalcInput("sirs", "Evidence of SIRS (systemic inflammatory response syndrome)", .yesNo),
            MedCalcInput("age60", "Age >60 years old", .yesNo),
            MedCalcInput("effusion", "Imaging reveals pleural effusion", .yesNo)
        ],
        compute: { v in
            var score = 0.0
            for id in ["bun", "ams", "sirs", "age60", "effusion"] where (v.selection(id) ?? 0) == 1 {
                score += 1
            }
            let mortality = score <= 2 ? "Lower mortality (<2 percent)" : "Higher mortality (>15 percent)"
            return String(format: "BISAP Score: %.0f/5\n%@", score, mortality)
        }
    ),

    MedCalcSpec(
        fileName: "BurnInjuryFluidParkland.htm",
        guide: """
        The Parkland (Baxter) formula estimates the crystalloid resuscitation volume for a major burn in the first 24 hours. Enter the patient's weight and the percent of total body surface area with partial- or full-thickness (non-superficial) burns, usually estimated with the rule of nines.

        The result gives the total 24-hour crystalloid volume and the two infusion rates: half the total is given in the first 8 hours after the burn (not admission), the remainder over the next 16 hours. Adjust to urine output (0.5–1 mL/kg/hr) as resuscitation proceeds.
        """,
        equation: "Total = 4 × weight(kg) × %TBSA; first-8h rate = Total ÷ 16; next-16h rate = Total ÷ 32",
        inputs: [
            MedCalcInput("weightUnits", "Weight units", .choice(options: ["kg", "lb"])),
            MedCalcInput("weight", "Body weight", .number(unitHint: "patient weight")),
            MedCalcInput("tbsa", "Percent nonsuperficial burn area (% TBSA)", .number(unitHint: "% body surface"))
        ],
        compute: { v in
            guard let weightRaw = v.number("weight"), let tbsa = v.number("tbsa") else { return "" }
            let kg = (v.selection("weightUnits") ?? 0) == 1 ? weightRaw * 0.45359237 : weightRaw
            guard kg > 0, tbsa > 0, tbsa <= 100 else { return "Enter a positive weight and burn area of 1–100%." }
            let total = 4 * kg * tbsa
            return """
            Total crystalloid for first 24 hours: \(String(format: "%.0f", total)) mL (\(String(format: "%.1f", total / 1000)) L)
            Infusion rate, first 8 hours after burn: \(String(format: "%.0f", total / 16)) mL/hr
            Infusion rate, next 16 hours: \(String(format: "%.0f", total / 32)) mL/hr
            """
        }
    ),

    MedCalcSpec(
        fileName: "MedsScore.htm",
        guide: """
        The MEDS score (Mortality in Emergency Department Sepsis) predicts mortality in ED patients with sepsis. Check each finding present; points are shown with each item for a total out of 27.

        Interpretation — mortality risk:
        • 0 to 4 points: 0.9–1.1%
        • 5 to 7 points: 2–4.4%
        • 8 to 12 points: 7.8–9.3%
        • 13 to 15 points: 16.1–20.2%
        • 16 to 27 points: 38–50%
        """,
        inputs: [
            MedCalcInput("terminal", "Terminal illness with possible death within 1 month (+6)", .yesNo),
            MedCalcInput("hypoxia", "Hypoxia or tachypnea (+3)", .yesNo),
            MedCalcInput("shock", "Shock from sepsis (+3)", .yesNo),
            MedCalcInput("platelets", "Platelet count below 150,000 (+3)", .yesNo),
            MedCalcInput("bands", "Granulocytic bands >5% of WBC (+3)", .yesNo),
            MedCalcInput("age65", "Patient older than 65 years old (+3)", .yesNo),
            MedCalcInput("lri", "Lower respiratory infection (+2)", .yesNo),
            MedCalcInput("nursingHome", "Patient is from a nursing home (+2)", .yesNo),
            MedCalcInput("mentalStatus", "Mental status is altered (+2)", .yesNo)
        ],
        compute: { v in
            let points: [(String, Double)] = [("terminal", 6), ("hypoxia", 3), ("shock", 3), ("platelets", 3),
                                              ("bands", 3), ("age65", 3), ("lri", 2), ("nursingHome", 2), ("mentalStatus", 2)]
            var score = 0.0
            for (id, pts) in points where (v.selection(id) ?? 0) == 1 { score += pts }
            let mortality: String
            switch Int(score) {
            case 0...4: mortality = "0.9–1.1%"
            case 5...7: mortality = "2–4.4%"
            case 8...12: mortality = "7.8–9.3%"
            case 13...15: mortality = "16.1–20.2%"
            default: mortality = "38–50%"
            }
            return String(format: "MEDS Score: %.0f/27\nMortality risk: %@", score, mortality)
        }
    ),

    MedCalcSpec(
        fileName: "MODS.htm",
        guide: """
        The Multiple Organ Dysfunction Score (Marshall 1995) tracks organ failure in the ICU. Enter the worst values from the first 24 hours of admission; each organ system scores 0–4 and the total ranges from 0 to 24.

        Units: PaO₂, central venous pressure, and mean arterial pressure in mmHg; heart rate in beats/min; platelets in ×10³/µL (thousands); bilirubin in mg/dL; creatinine in mg/dL; Glasgow Coma Score out of 15.
        """,
        equation: "PaO₂/FiO₂ and pressure-adjusted heart rate are scored per organ system; MODS = sum of six organ scores (0–24)",
        inputs: [
            MedCalcInput("pao2", "PaO₂ (mmHg)", .number(unitHint: "mmHg")),
            MedCalcInput("fio2", "FiO₂ (%)", .number(unitHint: "% inspired oxygen")),
            MedCalcInput("cvp", "Central venous pressure (mmHg)", .number(unitHint: "mmHg")),
            MedCalcInput("map", "Mean arterial pressure (mmHg)", .number(unitHint: "mmHg")),
            MedCalcInput("hr", "Heart rate (beats/min)", .number(unitHint: "beats/min")),
            MedCalcInput("platelets", "Platelets (×10³/µL)", .number(unitHint: "thousands per µL")),
            MedCalcInput("bilirubin", "Bilirubin (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("creatinine", "Creatinine (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("gcs", "Glasgow Coma Score (/15)", .number(unitHint: "0–15"))
        ],
        compute: { v in
            guard let pao2 = v.number("pao2"), let fio2 = v.number("fio2"), fio2 > 0,
                  let cvp = v.number("cvp"), let map = v.number("map"), map > 0,
                  let hr = v.number("hr"), let platelets = v.number("platelets"),
                  let bilirubin = v.number("bilirubin"), let creatinine = v.number("creatinine"),
                  let gcs = v.number("gcs") else { return "" }
            let pafi = 100 * pao2 / fio2
            var pafiScore: Int
            if pafi > 300 { pafiScore = 0 }
            else if pafi >= 226 { pafiScore = 1 }
            else if pafi >= 151 { pafiScore = 2 }
            else if pafi >= 76 { pafiScore = 3 }
            else { pafiScore = 4 }

            let pahr = hr * cvp / map
            var pahrScore: Int
            if pahr > 30 { pahrScore = 4 }
            else if pahr > 20 { pahrScore = 3 }
            else if pahr > 15 { pahrScore = 2 }
            else if pahr > 10 { pahrScore = 1 }
            else { pahrScore = 0 }

            let plateletScore: Int = platelets > 120 ? 0 : platelets >= 81 ? 1 : platelets >= 51 ? 2 : platelets >= 21 ? 3 : 4
            let biliUmolL = bilirubin * 17.1
            let biliScore: Int = biliUmolL <= 20 ? 0 : biliUmolL < 61 ? 1 : biliUmolL < 121 ? 2 : biliUmolL <= 240 ? 3 : 4
            let creatUmolL = creatinine * 88.4
            let renalScore: Int = creatUmolL <= 100 ? 0 : creatUmolL < 201 ? 1 : creatUmolL < 351 ? 2 : creatUmolL <= 500 ? 3 : 4
            let gcsScore: Int = gcs > 14 ? 0 : gcs > 12 ? 1 : gcs > 9 ? 2 : gcs > 6 ? 3 : 4

            let total = pafiScore + plateletScore + biliScore + pahrScore + renalScore + gcsScore
            let interpretation: String
            switch total {
            case 0: interpretation = "ICU mortality 0%, hospital mortality 0%, ICU stay ~2 days"
            case 1...4: interpretation = "ICU mortality 1–2%, hospital mortality 7%, ICU stay ~3 days"
            case 5...8: interpretation = "ICU mortality 3–5%, hospital mortality 16%, ICU stay ~6 days"
            case 9...12: interpretation = "ICU mortality 25%, hospital mortality 50%, ICU stay ~10 days"
            case 13...16: interpretation = "ICU mortality 50%, hospital mortality 70%, ICU stay ~17 days"
            case 17...20: interpretation = "ICU mortality 75%, hospital mortality 82%, ICU stay ~21 days"
            default: interpretation = "ICU mortality 100%, hospital mortality 100%"
            }
            return """
            PaO₂/FiO₂: \(String(format: "%.0f", pafi)) (score \(pafiScore))
            Pressure-adjusted heart rate: \(String(format: "%.1f", pahr)) (score \(pahrScore))

            MODS Score: \(total)/24 — \(interpretation)
            """
        }
    ),

    MedCalcSpec(
        fileName: "QSOFA.htm",
        guide: """
        The quick Sequential Organ Failure Assessment (qSOFA) screens for poor outcomes in suspected infection outside the ICU. One point for each of three findings — altered mentation, respiratory rate ≥22/min, or systolic blood pressure ≤100 mmHg — total out of 3.

        Interpretation:
        • 2 to 3 points: high risk (consider ICU-level care)
        • 0 to 1 point: not high risk
        """,
        equation: "qSOFA = (GCS <15) + (RR ≥22) + (SBP ≤100)",
        inputs: [
            MedCalcInput("gcs", "Glasgow Coma Score (/15)", .number(unitHint: "0–15")),
            MedCalcInput("sbp", "Systolic blood pressure (mmHg)", .number(unitHint: "mmHg")),
            MedCalcInput("rr", "Respiratory rate (breaths/min)", .number(unitHint: "breaths/min"))
        ],
        compute: { v in
            guard let gcs = v.number("gcs"), let sbp = v.number("sbp"), let rr = v.number("rr") else { return "" }
            var score = 0.0
            if gcs < 15 { score += 1 }
            if rr >= 22 { score += 1 }
            if sbp <= 100 { score += 1 }
            let risk = score >= 2 ? "High risk" : "Not high risk"
            return String(format: "qSOFA Score: %.0f/3 (%@)", score, risk)
        }
    ),

    MedCalcSpec(
        fileName: "SOFA.htm",
        guide: """
        The Sequential Organ Failure Assessment (SOFA) scores six organ systems 0–4 from the worst values in the first 24 hours of ICU care; total out of 24. A rise of ≥2 points indicates organ dysfunction.

        Units: PaO₂ and pressures in mmHg, FiO₂ as a percentage, platelets in ×10³/µL (thousands), bilirubin and creatinine in mg/dL, urine output in mL/day.
        """,
        equation: "SOFA = respiratory + coagulation + hepatic + cardiovascular + neurological + renal scores (each 0–4)",
        inputs: [
            MedCalcInput("pao2", "PaO₂ (mmHg)", .number(unitHint: "mmHg")),
            MedCalcInput("fio2", "FiO₂ (%)", .number(unitHint: "% inspired oxygen")),
            MedCalcInput("ventilated", "Mechanically ventilated?", .yesNo),
            MedCalcInput("platelets", "Platelets (×10³/µL)", .number(unitHint: "thousands per µL")),
            MedCalcInput("bilirubin", "Total bilirubin (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("bp", "Blood pressure / vasopressor status", .score(options: [
                "Hypotension absent (0)",
                "MAP <70 mmHg (1)",
                "Dopamine ≤5 µg/kg/min or any dobutamine (2)",
                "Dopamine >5, epinephrine ≤0.1, or norepinephrine ≤0.1 µg/kg/min (3)",
                "Dopamine >15, epinephrine >0.1, or norepinephrine >0.1 µg/kg/min (4)"
            ])),
            MedCalcInput("gcs", "Glasgow Coma Score (/15)", .number(unitHint: "0–15")),
            MedCalcInput("creatinine", "Creatinine (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("urineOutput", "Urine output (mL/day)", .number(unitHint: "mL per day"))
        ],
        compute: { v in
            guard let pao2 = v.number("pao2"), let fio2 = v.number("fio2"), fio2 > 0,
                  let platelets = v.number("platelets"), let bilirubin = v.number("bilirubin"),
                  let bpSel = v.selection("bp"), let gcs = v.number("gcs"),
                  let creatinine = v.number("creatinine"), let urineOutput = v.number("urineOutput") else { return "" }
            let ventilated = (v.selection("ventilated") ?? 0) == 1

            let pafi = 100 * pao2 / fio2
            var respScore: Int
            if pafi <= 100 && ventilated { respScore = 4 }
            else if pafi <= 200 && ventilated { respScore = 3 }
            else if pafi <= 300 { respScore = 2 }
            else if pafi <= 400 { respScore = 1 }
            else { respScore = 0 }

            let coagScore: Int = platelets < 20 ? 4 : platelets < 50 ? 3 : platelets < 100 ? 2 : platelets < 150 ? 1 : 0
            let hepaticScore: Int = bilirubin < 1.2 ? 0 : bilirubin < 2 ? 1 : bilirubin < 6 ? 2 : bilirubin < 12 ? 3 : 4
            let neuroScore: Int = gcs > 14 ? 0 : gcs > 12 ? 1 : gcs > 9 ? 2 : gcs > 5 ? 3 : 4

            var renalScore: Int
            if creatinine < 1.2 { renalScore = 0 }
            else if creatinine < 2 { renalScore = 1 }
            else if creatinine < 3.5 { renalScore = 2 }
            else if creatinine < 5 { renalScore = 3 }
            else { renalScore = 4 }
            if renalScore < 3 && urineOutput < 500 { renalScore = 3 }
            if renalScore < 4 && urineOutput < 200 { renalScore = 4 }

            let total = respScore + coagScore + hepaticScore + bpSel + neuroScore + renalScore
            return """
            PaO₂/FiO₂: \(String(format: "%.0f", pafi)) (respiratory score \(respScore))

            SOFA Score: \(total)/24 — respiratory \(respScore), coagulation \(coagScore), hepatic \(hepaticScore), cardiovascular \(bpSel), neurological \(neuroScore), renal \(renalScore)
            """
        }
    )
]
