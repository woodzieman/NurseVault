import Foundation

// Oncology & Risk calculator specs — formulas from the Merck Manual clinical-calculator sources.

let oncologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "ecog.htm",
        guide: """
        The ECOG (Eastern Cooperative Oncology Group) performance status grades a patient's functional impairment on a 0–4 scale. Choose the description that best matches the patient today; it guides treatment decisions and prognosis in oncology.

        • 0 — fully active, no restrictions
        • 1 — restricted in strenuous activity but ambulatory and able to do light work
        • 2 — ambulatory, all self-care intact, unable to work; up >50% of waking hours
        • 3 — limited self-care only; confined to bed or chair >50% of waking hours
        • 4 — completely disabled, totally confined to bed or chair
        """,
        inputs: [
            MedCalcInput("scale", "Performance status", .choice(options: [
                "Fully active; no performance restrictions (0)",
                "Strenuous physical activity restricted; fully ambulatory and able to carry out light work (1)",
                "Capable of all self-care but unable to carry out any work activities. Up and about >50% of waking hours (2)",
                "Capable of only limited self-care; confined to bed or chair >50% of waking hours (3)",
                "Completely disabled; cannot carry out any self-care; totally confined to bed or chair (4)"
            ]))
        ],
        compute: { v in
            guard let level = v.selection("scale") else { return "" }
            return "ECOG Performance Status: \(level)/4"
        }
    ),
    MedCalcSpec(
        fileName: "maggic.htm",
        guide: """
        The MAGGIC score predicts 1-year and 3-year mortality in heart failure from 13 readily available variables.

        • Age (years, ≤85), sex, left ventricular ejection fraction (%), systolic blood pressure (mmHg), BMI (kg/m²), creatinine (µmol/L — note the source uses SI units).
        • NYHA class I–IV; current beta-blocker and ACEI/ARB use; smoking, diabetes, COPD; whether the heart-failure diagnosis is within 18 months.

        The score maps to observed mortality percentages from the MAGGIC cohort (Chatterjee et al., Ann Intern Med 2013).
        """,
        equation: "MAGGIC = EF + Age×EF + SBP×EF + BMI + Creatinine factors + NYHA + Sex + Smoker + Diabetes + COPD + HF<18mo + BetaBlocker + ACEI/ARB points",
        inputs: [
            MedCalcInput("age", "Age (years)", .number(unitHint: "years")),
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("ef", "Ejection fraction (%)", .number(unitHint: "%")),
            MedCalcInput("sbp", "Systolic blood pressure (mmHg)", .number(unitHint: "mmHg")),
            MedCalcInput("bmi", "Body mass index (kg/m²)", .number(unitHint: "kg/m²")),
            MedCalcInput("creatinine", "Creatinine (µmol/L)", .number(unitHint: "µmol/L")),
            MedCalcInput("nyha", "NYHA class", .choice(options: ["Class I", "Class II", "Class III", "Class IV"])),
            MedCalcInput("betaBlocker", "On beta blocker?", .yesNo),
            MedCalcInput("aceiArb", "On ACEI/ARB?", .yesNo),
            MedCalcInput("smoker", "Smoker?", .yesNo),
            MedCalcInput("diabetes", "Diabetes?", .yesNo),
            MedCalcInput("copd", "COPD?", .yesNo),
            MedCalcInput("hfRecent", "HF diagnosis within 18 months?", .yesNo)
        ],
        compute: { v in
            guard let age = v.number("age"),
                  let sex = v.selection("sex"),
                  let ef = v.number("ef"),
                  let sbp = v.number("sbp"),
                  let bmi = v.number("bmi"),
                  let creatinine = v.number("creatinine"),
                  let nyha = v.selection("nyha") else { return "" }
            guard age <= 85 else { return "Age must be ≤85 years." }

            // EF factor.
            let efFactor: Int
            switch ef {
            case ..<20: efFactor = 7
            case ...24: efFactor = 6
            case ...29: efFactor = 5
            case ...34: efFactor = 3
            case ...39: efFactor = 2
            default: efFactor = 0
            }

            // BMI factor.
            let bmiFactor: Int
            switch bmi {
            case ..<15: bmiFactor = 6
            case ...19: bmiFactor = 5
            case ...24: bmiFactor = 3
            case ...29: bmiFactor = 2
            default: bmiFactor = 0
            }

            // Creatinine factor (µmol/L).
            let creatinineFactor: Int
            switch creatinine {
            case 250...: creatinineFactor = 8
            case 210..<250: creatinineFactor = 6
            case 170..<210: creatinineFactor = 5
            case 150..<170: creatinineFactor = 4
            case 130..<150: creatinineFactor = 3
            case 110..<130: creatinineFactor = 2
            case 90..<110: creatinineFactor = 1
            default: creatinineFactor = 0
            }

            // Age×EF and SBP×EF factors.
            let agePoints: [Int] = [80, 75, 70, 65, 60, 56]
            func ageEf(_ table: [Int]) -> Int {
                for (threshold, points) in zip(agePoints, table) where age >= Double(threshold) { return points }
                return 0
            }
            let ageEfFactor = ef >= 40 ? ageEf([15, 12, 9, 7, 5, 3])
                : ef >= 30 ? ageEf([13, 10, 8, 6, 4, 2])
                : ageEf([10, 8, 6, 4, 2, 1])
            let sbpEfFactor: Int
            if ef >= 40 {
                sbpEfFactor = sbp < 110 ? 2 : (sbp <= 129 ? 1 : 0)
            } else if ef >= 30 {
                sbpEfFactor = sbp < 110 ? 3 : (sbp <= 119 ? 2 : (sbp <= 139 ? 1 : 0))
            } else {
                sbpEfFactor = sbp < 110 ? 5 : (sbp <= 119 ? 4 : (sbp <= 129 ? 3 : 0))
            }

            let nyhaPoints = [0, 2, 6, 8][nyha]
            let score = efFactor + ageEfFactor + sbpEfFactor + bmiFactor + creatinineFactor
                + nyhaPoints + sex + (v.selection("smoker") ?? 0)
                + ((v.selection("diabetes") ?? 0) == 1 ? 3 : 0)
                + ((v.selection("copd") ?? 0) == 1 ? 2 : 0)
                + ((v.selection("hfRecent") ?? 0) == 1 ? 2 : 0)
                + ((v.selection("betaBlocker") ?? 0) == 1 ? 0 : 3)
                + ((v.selection("aceiArb") ?? 0) == 1 ? 0 : 1)

            guard (0...27).contains(score) else { return "Score out of table range." }
            let m1 = [1.5, 1.6, 1.8, 2.0, 2.2, 2.4, 2.7, 2.9, 3.2, 3.6, 3.9, 4.3, 4.8, 5.2, 5.8, 6.3, 7.0, 7.7, 8.4, 9.3, 10.2, 11.1, 12.2, 13.4, 14.7, 16.0, 17.5, 19.1][score]
            let m3 = [3.9, 4.3, 4.8, 5.2, 5.8, 6.3, 7.0, 7.7, 8.4, 9.2, 10.2, 11.1, 12.2, 13.4, 14.6, 16.0, 17.5, 19.1, 20.9, 22.7, 24.7, 26.9, 29.2, 31.6, 34.2, 36.9, 39.7, 42.7][score]
            return String(format: "MAGGIC Score: %d\nEstimated mortality — 1 year: %.1f%% · 3 years: %.1f%%", score, m1, m3)
        }
    ),
    MedCalcSpec(
        fileName: "gail2018.htm",
        guide: """
        The GAIL model (NIH, 2018 update) estimates a woman's risk of invasive breast cancer over the next 5 years and her lifetime (to age 90), using race/ethnicity, biopsy history, atypical hyperplasia, menarche age, first live birth, and family history.

        • Age in years (20–85).
        • Biopsies: number of breast biopsies; if any showed atypical hyperplasia, mark it.
        • Menarche age group; age at first live birth (or nulliparous); first-degree relatives with breast cancer.

        Results are shown alongside the average-risk estimate for comparison. The model is validated for women ≥30 years old without a prior personal history of breast cancer.
        """,
        equation: "LogRR = NB·NBdata + AgeMen·AMdata + Age1st·AFdata + NRels·NRdata + Age1st·NRels·AFNRdata + HyperPlasia; risk by competing-risk integration (NIH GAIL v4.1)",
        inputs: [
            MedCalcInput("age", "Age (years, 20–85)", .number(unitHint: "years")),
            MedCalcInput("race", "Race/ethnicity/nativity", .choice(options: [
                "White non-Hispanic",
                "African American",
                "Hispanic US born",
                "Hispanic foreign born",
                "American Indian or Alaskan native",
                "Chinese American",
                "Japanese American",
                "Filipino American",
                "Hawaiian",
                "Other Pacific Islander American",
                "Other Asian American",
                "Other race/ethnicity American"
            ])),
            MedCalcInput("biopsies", "Number of breast biopsies", .choice(options: ["No biopsies", "1 biopsy", "2 or more biopsies"])),
            MedCalcInput("hyperplasia", "Biopsy with atypical hyperplasia?", .choice(options: ["No", "Yes", "Unknown"])),
            MedCalcInput("menarche", "Age at menarche", .choice(options: ["7 to 11 years old", "12 to 13 years old", "14 years or older", "Unknown"])),
            MedCalcInput("firstBirth", "Age at first live birth", .choice(options: [
                "<20 years old", "20 to 24 years old", "25 to 29 years old", "30 or more years old", "Nulliparous", "Unknown"
            ])),
            MedCalcInput("relatives", "First-degree relatives with breast cancer", .choice(options: ["None", "1 relative", "2 or more relatives", "Unknown"]))
        ],
        compute: { v in
            guard let age = v.number("age"),
                  let raceIndex = v.selection("race"),
                  let biopsies = v.selection("biopsies"),
                  let hyperplasia = v.selection("hyperplasia"),
                  let menarche = v.selection("menarche"),
                  let firstBirth = v.selection("firstBirth"),
                  let relatives = v.selection("relatives") else { return "" }
            guard age >= 20, age <= 85 else { return "Age must be between 20 and 85 years." }

            // Source option values (the original dropdown maps the last race option to 5).
            let ren = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 5][raceIndex]
            var nb = biopsies // 0, 1, 2 (Unknown → 0)
            let hyperValue: Double = [ -0.0725707, 0.5988365, 0 ][hyperplasia]
            var ageMen = [2, 1, 0, 0][menarche]
            var age1st = [0, 1, 2, 3, 2, 0][firstBirth]
            var nRels = relatives // 0, 1, 2 (Unknown → 0)

            if nb == 0 { _ = hyperValue } // no biopsies → atypical hyperplasia not applicable
            let hyperPlasia: Double = nb == 0 ? 0 : hyperValue
            if (ren == 3 || ren == 4), nb == 2 { nb = 1 }
            if ren == 2, ageMen == 2 { ageMen = 1 }
            if ren == 3 || ren == 4 {
                if age1st == 2 { age1st = 1 }
                if age1st == 3 { age1st = 2 }
            }
            if ren == 3 || ren == 4 || ren >= 6, nRels == 2 { nRels = 1 }

            let renBeta = min(ren, 6)
            let logRR = Double(nb) * GailData.nb[renBeta]
                + Double(ageMen) * GailData.am[renBeta]
                + Double(age1st) * GailData.af[renBeta]
                + Double(nRels) * GailData.nr[renBeta]
                + Double(age1st) * Double(nRels) * GailData.afnr[renBeta]
                + hyperPlasia
            let logRR50 = logRR + Double(nb) * GailData.a50nb[renBeta]
            let rrisk = exp(logRR)
            let rrisk50 = exp(logRR50)

            // absRisk(T1, T2, REN, REN_Beta, RR, RR50, doAVG) from the NIH source.
            func absRisk(_ t1: Double, _ t2: Double, ren: Int, renBeta: Int, avg: Bool) -> Double? {
                guard t1 >= 20, t1 <= 90 else { return nil }
                let strtIntvl = Int(t1.rounded(.down)) - 20 + 1
                let numbrIntvl = Int(t2.rounded(.up)) - Int(t1.rounded(.down))
                var rskWrk = 0.0
                var cumH = 0.0
                for jj in 1...numbrIntvl {
                    let jIntvl = strtIntvl + (jj - 1)
                    var oneARRR: Double
                    if jIntvl <= 30 { oneARRR = GailData.ar50[0][renBeta] * rrisk }
                    else { oneARRR = GailData.ar50[1][renBeta] * rrisk50 }
                    if avg { oneARRR = 1 }

                    let intgrlLngth: Double
                    if numbrIntvl > 1, jj > 1, jj < numbrIntvl {
                        intgrlLngth = 1
                    } else if numbrIntvl > 1, jj == 1 {
                        intgrlLngth = 1 - (t1 - t1.rounded(.down))
                    } else if numbrIntvl > 1, jj == numbrIntvl {
                        let frac = t2 - t2.rounded(.down)
                        intgrlLngth = frac * (t2 > t2.rounded(.down) ? 1 : 0) + (t2 == t2.rounded(.down) ? 1 : 0)
                    } else { // numbrIntvl == 1
                        intgrlLngth = t2 - t1
                    }

                    let curAgeGrp = Int(floor(Double(jIntvl + 19) / 5)) - 3
                    guard (1...14).contains(curAgeGrp), ren >= 1, ren <= 12 else { return nil }
                    let h1 = GailData.brCaCI[curAgeGrp - 1][ren - 1]
                    let h2 = GailData.compMort[curAgeGrp - 1][ren - 1]

                    let hj = (h1 * oneARRR) + h2
                    let piJ = ((oneARRR * h1 / hj) * exp(-cumH)) * (1 - exp(-hj * intgrlLngth))
                    rskWrk += piJ
                    cumH += hj * intgrlLngth
                }
                return 100 * rskWrk
            }

            // Average-risk comparison uses race column 12 / beta group 5 for White non-Hispanic and American Indian, as in the source.
            let (avgRen, avgBeta): (Int, Int) = (ren == 1 || ren == 5) ? (12, 5) : (ren, renBeta)
            guard let risk5 = absRisk(age, age + 5, ren: ren, renBeta: renBeta, avg: false),
                  let riskLife = absRisk(age, 90, ren: ren, renBeta: renBeta, avg: false),
                  let avg5 = absRisk(age, age + 5, ren: avgRen, renBeta: avgBeta, avg: true),
                  let avgLife = absRisk(age, 90, ren: avgRen, renBeta: avgBeta, avg: true) else {
                return "Could not compute risk for these inputs."
            }

            var lines = [
                String(format: "Relative risk (next 5 years): %.2f", rrisk),
                String(format: "Relative risk (age ≥50): %.2f", rrisk50),
                "",
                String(format: "Your estimated risk — next 5 years: %.3f%% (average for your group: %.3f%%)", risk5, avg5),
                String(format: "Your estimated lifetime risk (to age 90): %.2f%% (average: %.2f%%)", riskLife, avgLife)
            ]
            if risk5 > avg5 { lines.append("This is above the average-risk estimate.") }
            else if risk5 < avg5 { lines.append("This is below the average-risk estimate.") }
            return lines.joined(separator: "\n")
        }
    )
]
