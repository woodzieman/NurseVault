import Foundation

/// Calculator specs for the neonatology category.
let neonatologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "ApgarScore.htm",
        guide: """
        The Apgar score assesses a newborn's condition at 1 and 5 minutes after birth. Score each of the five signs — heart rate, respiratory effort, muscle tone, color, and reflex response — as observed; each sign scores 0, 1, or 2 points for a total out of 10.

        Interpretation:
        • 7 to 10 points: Normal
        • 0 to 6 points: Distress — the infant needs attention (resuscitation per neonatal resuscitation program)
        """,
        inputs: [
            MedCalcInput("heartRate", "Heart rate", .score(options: ["None (0)", "<100 beats/min (1)", "≥100 beats/min (2)"])),
            MedCalcInput("respiration", "Respiratory effort", .score(options: ["None (0)", "Irregular (1)", "Regular, good cry (2)"])),
            MedCalcInput("muscleTone", "Muscle tone and movement", .score(options: ["Limp (0)", "Moderate flexion (1)", "Active motion (2)"])),
            MedCalcInput("color", "Skin color / oxygenation", .score(options: ["Totally blue/pale (0)", "Body pink, extremities blue (1)", "Completely pink (2)"])),
            MedCalcInput("reflexes", "Reflex response to stimuli", .score(options: ["No response (0)", "Whimpering/grimace (1)", "Cough/cry/pulls away (2)"]))
        ],
        compute: { v in
            var score = 0.0
            for id in ["heartRate", "respiration", "muscleTone", "color", "reflexes"] {
                guard let sel = v.selection(id) else { return "" }
                score += Double(sel)
            }
            let status = score >= 7 ? "Normal" : "Distress — attention needed"
            return String(format: "Apgar Score: %.0f/10 (%@)", score, status)
        }
    ),

    MedCalcSpec(
        fileName: "westleycroupscore.htm",
        guide: """
        The Westley croup severity score grades the severity of laryngotracheobronchitis (croup) in children 6 years and younger. Assess each sign as observed; points are shown with each option for a total out of 17.

        Interpretation — total score:
        • 0 to 2: Mild — occasional barky cough, no stridor at rest, mild or no retractions
        • 3 to 7: Moderate — frequent barky cough, stridor at rest, mild-to-moderate retractions, little distress or agitation
        • 8 to 11: Severe — frequent barky cough, stridor at rest, marked retractions, significant distress and agitation
        • 12 to 17: Impending respiratory failure — depressed consciousness, stridor at rest, severe retractions, poor air entry, cyanosis or pallor
        """,
        inputs: [
            MedCalcInput("consciousness", "Level of consciousness", .score(options: ["Normal, including sleep (0)", "Disoriented (5)"])),
            MedCalcInput("cyanosis", "Cyanosis", .score(options: ["None (0)", "With agitation (4)", "At rest (5)"])),
            MedCalcInput("stridor", "Stridor", .score(options: ["None (0)", "With agitation (1)", "At rest (2)"])),
            MedCalcInput("airEntry", "Air entry", .score(options: ["Normal (0)", "Decreased (1)", "Markedly decreased (2)"])),
            MedCalcInput("retractions", "Retractions", .score(options: ["None (0)", "Mild (1)", "Moderate (2)", "Severe (3)"]))
        ],
        compute: { v in
            var score = 0.0
            for id in ["consciousness", "cyanosis", "stridor", "airEntry", "retractions"] {
                guard let sel = v.selection(id) else { return "" }
                switch (id, sel) {
                case ("consciousness", _): score += Double(sel * 5)
                case ("cyanosis", _): score += [0.0, 4, 5][sel]
                case ("stridor", _), ("airEntry", _): score += Double(sel)
                default: score += Double(sel) // retractions 0-3
                }
            }
            let severity: String
            switch Int(score) {
            case 0...2: severity = "Mild"
            case 3...7: severity = "Moderate"
            case 8...11: severity = "Severe"
            default: severity = "Impending respiratory failure"
            }
            return String(format: "Westley Croup Score: %.0f/17 (%@)", score, severity)
        }
    ),

    MedCalcSpec(
        fileName: "neonatalsepsis.htm",
        guide: """
        The early-onset sepsis (EOS) risk calculator (Puopolo 2011) estimates the probability of EOS per 1000 births from maternal risk factors, then adjusts for the newborn's clinical exam.

        Enter the local EOS incidence (per 1000 births), gestational age in completed weeks plus extra days, the highest antepartum maternal temperature, hours since rupture of membranes, GBS status, intrapartum antibiotic exposure, and how the baby appears on exam.

        The result gives the risk at birth and after the exam, with management recommendations:
        • Exam EOS <1 and birth EOS <1: no culture, no antibiotics, routine vitals
        • Exam EOS <1 and birth EOS ≥1: no culture, no antibiotics, vitals q4 hours for 24 hours
        • Exam EOS 1 to <3: blood culture, no antibiotics, vitals q4 hours for 24 hours
        • Exam EOS ≥3 (or ill-appearing with exam EOS <3): empiric antibiotics, vitals per NICU
        """,
        equation: "logit = incidence + 0.868×Temp(°F) − 6.9325×GAwks + 0.0877×GAwks² + 1.2256×(ROM+0.05)^0.2 + IPabx + GBS; risk = 1000/(1+e^−logit)",
        inputs: [
            MedCalcInput("incidence", "Local EOS incidence (per 1000 births)", .choice(options: ["0.1", "0.2", "0.3 (KPNC)", "0.4", "0.5 (CDC national)", "0.6", "0.7", "0.8", "0.9", "1", "2", "4"])),
            MedCalcInput("gestWeeks", "Gestational age — completed weeks", .choice(options: ["34", "35", "36", "37", "38", "39", "40", "41", "42", "43"])),
            MedCalcInput("gestDays", "Extra days of gestation", .choice(options: ["0", "1", "2", "3", "4", "5", "6"])),
            MedCalcInput("tempUnits", "Maternal temperature units", .choice(options: ["°F", "°C"])),
            MedCalcInput("temperature", "Highest antepartum maternal temperature", .number(unitHint: "body temperature")),
            MedCalcInput("romHours", "Hours since rupture of membranes", .number(unitHint: "hours (enter 0 if intact)")),
            MedCalcInput("gbs", "Maternal GBS status", .choice(options: ["Negative", "Positive", "Unknown"])),
            MedCalcInput("ipabx", "Intrapartum antibiotics", .score(options: [
                "Broad spectrum ≥4 h before birth",
                "Broad spectrum 2–3.99 h before birth",
                "GBS-specific ≥2 h before birth",
                "None, or any antibiotic <2 h before birth"
            ])),
            MedCalcInput("exam", "Newborn clinical exam", .score(options: ["Well appearing", "Equivocal exam", "Ill appearing"]))
        ],
        compute: { v in
            guard let incSel = v.selection("incidence"), let wkSel = v.selection("gestWeeks"),
                  let daySel = v.selection("gestDays"), let tempRaw = v.number("temperature"),
                  let romHours = v.number("romHours"), let gbsSel = v.selection("gbs"),
                  let ipabxSel = v.selection("ipabx"), let examSel = v.selection("exam") else { return "" }
            let incidenceLogits: [Double] = [38.952265, 39.646367, 40.0528, 40.3415, 40.5656, 40.7489,
                                             40.903919, 41.0384, 41.1571, 41.263432, 41.965852, 42.676976]
            let tempF = (v.selection("tempUnits") ?? 0) == 1 ? tempRaw * 1.8 + 32 : tempRaw
            let gaWeeks = Double(wkSel) + Double(daySel) / 7.0
            let gbsLogits: [Double] = [0, 0.5771, 0.0427]
            let ipabxLogits: [Double] = [-1.18610, -1.0488, -1.0488, 0]
            let examLRs: [Double] = [0.41, 5, 21.2]

            let logit = incidenceLogits[incSel] + 0.868 * tempF
                - 6.9325 * gaWeeks + 0.0877 * pow(gaWeeks, 2)
                + 1.2256 * pow(romHours + 0.05, 0.2)
                + ipabxLogits[ipabxSel] + gbsLogits[gbsSel]
            let riskAtBirth = 1000.0 / (1.0 + exp(-logit))
            let oddsAfterExam = exp(logit) * examLRs[examSel]
            let riskAfterExam = 1000.0 * oddsAfterExam / (1.0 + oddsAfterExam)

            let recommendation: String
            if riskAfterExam < 3 && examSel == 2 {
                recommendation = "Strongly consider empiric antibiotics, vitals per NICU"
            } else if riskAfterExam < 1 && riskAtBirth < 1 {
                recommendation = "No culture, no antibiotics, routine vitals"
            } else if riskAfterExam < 1 {
                recommendation = "No culture, no antibiotics, vitals q4 hours for 24 hours"
            } else if riskAfterExam < 3 {
                recommendation = "Blood culture, no antibiotics, vitals q4 hours for 24 hours"
            } else {
                recommendation = "Empiric antibiotics, vitals per NICU"
            }
            return """
            EOS risk at birth: \(String(format: "%.1f", riskAtBirth)) per 1000
            EOS risk after exam: \(String(format: "%.1f", riskAfterExam)) per 1000

            Recommendation: \(recommendation)
            """
        }
    ),

    MedCalcSpec(
        fileName: "newbornhyperbili2022.htm",
        guide: """
        The AAP 2022 hyperbilirubinemia thresholds (Kemper 2022) for infants 35 or more weeks of gestation. Enter the total serum bilirubin, the newborn's age in hours after birth, completed gestational weeks, and answer the four risk-factor questions — any one risk factor moves the infant to the higher threshold tables.

        The result shows the phototherapy threshold, the escalation-of-care threshold (2 mg/dL below exchange), and the exchange transfusion threshold for this infant's age and risk profile, plus where the measured level falls relative to them.
        """,
        inputs: [
            MedCalcInput("biliUnits", "Bilirubin units", .choice(options: ["mg/dL", "µmol/L"])),
            MedCalcInput("bilirubin", "Total serum bilirubin (TSB)", .number(unitHint: "measured level")),
            MedCalcInput("ageHours", "Newborn's age after birth", .number(unitHint: "hours of life (12–336)")),
            MedCalcInput("gestWeeks", "Gestational age — completed weeks", .number(unitHint: "weeks (≥35)")),
            MedCalcInput("instability", "Clinical instability within 24 hours?", .yesNo),
            MedCalcInput("sepsis", "Concern for sepsis?", .yesNo),
            MedCalcInput("hemolytic", "Hemolytic condition?", .choice(options: ["Yes", "No", "Unknown"])),
            MedCalcInput("hypoalb", "Serum albumin <3.0 g/dL?", .choice(options: ["Yes", "No", "Unknown"]))
        ],
        compute: { v in
            guard let biliRaw = v.number("bilirubin"), let ageHours = v.number("ageHours"),
                  let gestWeeks = v.number("gestWeeks") else { return "" }
            let bilirubin = (v.selection("biliUnits") ?? 0) == 1 ? biliRaw / 17.104 : biliRaw
            guard (12...336).contains(Int(ageHours.rounded())), gestWeeks >= 35, bilirubin > 0 else {
                return "Enter a postnatal age of 12–336 hours and gestational age ≥35 weeks."
            }
            let hour = Int(ageHours.rounded())
            let hasRisk = (v.selection("instability") ?? 0) == 1 || (v.selection("sepsis") ?? 0) == 1
                || (v.selection("hemolytic") ?? -1) == 0 || (v.selection("hypoalb") ?? -1) == 0

            let photoTable = hasRisk ? MedCalcHyperbiliData.phototherapyRisk : MedCalcHyperbiliData.phototherapyNoRisk
            let exchangeTable = hasRisk ? MedCalcHyperbiliData.exchangeRisk : MedCalcHyperbiliData.exchangeNoRisk
            guard let photoRow = photoTable[hour], let exchangeRow = exchangeTable[hour] else { return "" }
            let col = hasRisk ? MedCalcHyperbiliData.riskColumn(weeksGestation: gestWeeks)
                              : MedCalcHyperbiliData.noRiskColumn(weeksGestation: gestWeeks)

            let photoThreshold = photoRow[col]
            let exchangeThreshold = exchangeRow[col]
            let escalateThreshold = exchangeThreshold - 2.0
            func both(_ mgDl: Double) -> String { String(format: "%.1f mg/dL [%.0f µmol/L]", mgDl, (mgDl * 17.104).rounded()) }

            var advice: String
            if bilirubin >= exchangeThreshold {
                advice = "AT OR ABOVE THE THRESHOLD FOR EXCHANGE TRANSFUSION — AAP guidelines recommend EXCHANGE TRANSFUSION."
            } else if bilirubin >= escalateThreshold {
                advice = "AT OR ABOVE THE THRESHOLD FOR ESCALATING CARE — start PHOTOTHERAPY and IV HYDRATION immediately."
            } else if bilirubin >= photoThreshold {
                advice = "AT OR ABOVE THE THRESHOLD FOR PHOTOTHERAPY — AAP guidelines recommend immediate phototherapy, with repeat TSB after starting therapy."
            } else if abs(bilirubin - photoThreshold) < 2 {
                advice = "CLOSE TO THE THRESHOLD FOR PHOTOTHERAPY — within the first 24 hours of life, consider delaying discharge and recheck TSB in 4 to 8 hours."
            } else {
                advice = "BELOW THE THRESHOLD FOR PHOTOTHERAPY — consider repeat bilirubin levels per AAP guidelines."
            }

            let diff = bilirubin - photoThreshold
            let compareText: String
            if abs(diff) < 0.05 {
                compareText = "at the phototherapy threshold"
            } else if diff > 0 {
                compareText = String(format: "%.1f mg/dL above the phototherapy threshold", diff)
            } else {
                compareText = String(format: "%.1f mg/dL below the phototherapy threshold", -diff)
            }

            return """
            \(hasRisk ? "With risk factors for neurotoxicity" : "Without risk factors") — thresholds by age and gestation:

            Phototherapy threshold: \(both(photoThreshold))
            Escalate-care threshold: \(both(escalateThreshold))
            Exchange transfusion threshold: \(both(exchangeThreshold))

            Measured TSB is \(compareText).

            \(advice)
            """
        }
    )
]
