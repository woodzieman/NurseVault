import Foundation

/// Calculator specs for the other category.
let otherCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "AscitesAlbGradient.htm",
        guide: """
        The serum-ascites albumin gradient (SAAG) distinguishes portal hypertension from other causes of ascites. Obtain simultaneous serum and ascitic fluid samples at the time of paracentesis.

        • Serum albumin (g/dL) — same-day blood draw
        • Ascites albumin (g/dL) — from the paracentesis specimen

        Interpretation:
        • SAAG ≥ 1.1 g/dL: consistent with portal hypertension, CHF, or Budd-Chiari syndrome
        • SAAG < 1.1 g/dL: consistent with carcinomatosis, tuberculosis, pancreatitis, serositis, or nephrosis
        """,
        equation: "SAAG = Serum Albumin − Ascites Albumin (g/dL)",
        inputs: [
            MedCalcInput("serumAlbumin", "Serum albumin (g/dL)", .number(unitHint: "g/dL")),
            MedCalcInput("ascitesAlbumin", "Ascites fluid albumin (g/dL)", .number(unitHint: "g/dL"))
        ],
        compute: { v in
            guard let serum = v.number("serumAlbumin"), let ascites = v.number("ascitesAlbumin") else { return "" }
            let saag = serum - ascites
            let interpretation = saag >= 1.1
                ? "Consistent with portal hypertension, CHF or Budd-Chiari syndrome"
                : "Consistent with carcinomatosis, tuberculosis, pancreatitis, serositis, or nephrosis"
            return String(format: "SAAG: %.2f g/dL\n%@ (threshold 1.1 g/dL)", saag, interpretation)
        }
    ),
    MedCalcSpec(
        fileName: "GeriatricDepression.htm",
        guide: """
        The Geriatric Depression Scale (GDS-15) screens for depression in older adults — it avoids somatic items that overlap with medical illness. Ask the patient to answer each question about how they felt over the PAST WEEK; some questions are reverse-scored (the scale handles this automatically).

        Interpretation — total score out of 15:
        • 0–5: Depression unlikely
        • 6–9: Depression possible
        • 10–15: Depression likely present — consider further evaluation and referral
        """,
        inputs: {
            let yesNo = ["Yes", "No"]
            return [
                MedCalcInput("q1", "Are you basically satisfied with your life?", .choice(options: yesNo)),
                MedCalcInput("q2", "Have you dropped many of your activities and interests?", .choice(options: yesNo)),
                MedCalcInput("q3", "Do you feel your life is empty?", .choice(options: yesNo)),
                MedCalcInput("q4", "Do you often get bored?", .choice(options: yesNo)),
                MedCalcInput("q5", "Are you in good spirits most of the time?", .choice(options: yesNo)),
                MedCalcInput("q6", "Are you afraid something bad is going to happen to you?", .choice(options: yesNo)),
                MedCalcInput("q7", "Do you feel happy most of the time?", .choice(options: yesNo)),
                MedCalcInput("q8", "Do you often feel helpless?", .choice(options: yesNo)),
                MedCalcInput("q9", "Do you prefer to stay home, rather than going out and doing new things?", .choice(options: yesNo)),
                MedCalcInput("q10", "Do you feel you have more problems with memory than most?", .choice(options: yesNo)),
                MedCalcInput("q11", "Do you think it is wonderful to be alive now?", .choice(options: yesNo)),
                MedCalcInput("q12", "Do you feel pretty worthless the way you are now?", .choice(options: yesNo)),
                MedCalcInput("q13", "Do you feel full of energy?", .choice(options: yesNo)),
                MedCalcInput("q14", "Do you feel that your situation is hopeless?", .choice(options: yesNo)),
                MedCalcInput("q15", "Do you think that most people are better off than you?", .choice(options: yesNo))
            ]
        }(),
        compute: { v in
            // Reverse-scored items (a "No" earns the point): q1, q5, q7, q11, q13.
            let reverse = ["q1", "q5", "q7", "q11", "q13"]
            var total = 0
            for i in 1...15 {
                guard let answer = v.selection("q\(i)") else { return "" }
                if reverse.contains("q\(i)") {
                    if answer == 1 { total += 1 } // No
                } else {
                    if answer == 0 { total += 1 } // Yes
                }
            }
            let interpretation: String
            switch total {
            case ...5: interpretation = "Depression unlikely"
            case 6...9: interpretation = "Depression possible"
            default: interpretation = "Depression likely present — consider further evaluation and referral"
            }
            return "GDS-15 Score: \(total)/15\n\(interpretation)"
        }
    ),
    MedCalcSpec(
        fileName: "aha_prev.htm",
        guide: """
        AHA PREVENT 2023 estimates absolute cardiovascular risk for adults aged 30–79 using the American Heart Association's pooled-cohort equations. Enter current values; HbA1C, urine albumin-to-creatinine ratio (UACR), and US ZIP code are optional add-ons that refine the estimate when available.

        • Age in years (30–79); height in cm and weight in kg for BMI
        • Total cholesterol and HDL in mg/dL; systolic blood pressure in mmHg
        • Serum creatinine in mg/dL (used to compute eGFR)
        • Mark whether the patient takes antihypertensive or statin medication, has diabetes, or currently smokes

        Interpretation — 10-year ASCVD risk: <3% low; 3–<5% borderline; 5–<10% intermediate; ≥10% high. Results are shown for total CVD, ASCVD (MI/stroke), and heart failure.
        """,
        equation: "Risk = 100 × e^logit / (1 + e^logit); logit from AHA PREVENT pooled-cohort coefficients (see Khan et al., Circulation 2023)",
        inputs: [
            MedCalcInput("age", "Age (years, 30–79)", .number(unitHint: "years")),
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("height", "Height (cm)", .number(unitHint: "cm")),
            MedCalcInput("weight", "Weight (kg)", .number(unitHint: "kg")),
            MedCalcInput("totalChol", "Total cholesterol (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("hdl", "HDL cholesterol (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("sbp", "Systolic blood pressure (mmHg)", .number(unitHint: "mmHg")),
            MedCalcInput("creatinine", "Serum creatinine (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("htnMed", "On antihypertensive medication?", .yesNo),
            MedCalcInput("statinMed", "On statin therapy?", .yesNo),
            MedCalcInput("diabetes", "Diagnosed diabetes?", .yesNo),
            MedCalcInput("smoker", "Current smoker?", .yesNo),
            MedCalcInput("hba1c", "HbA1C (%, optional add-on)", .number(unitHint: "%")),
            MedCalcInput("uacr", "Urine albumin-to-creatinine ratio (mg/g, optional)", .number(unitHint: "mg/g")),
            MedCalcInput("zip", "US ZIP code (optional SDI add-on)", .number(unitHint: "ZIP"))
        ],
        compute: { v in
            guard let age = v.number("age"),
                  let sexIndex = v.selection("sex"),
                  let height = v.number("height"),
                  let weight = v.number("weight"),
                  let tc = v.number("totalChol"),
                  let hdl = v.number("hdl"),
                  let sbp = v.number("sbp"),
                  let scr = v.number("creatinine") else { return "" }
            guard age >= 30, age <= 79 else {
                return "Age must be between 30 and 79 years."
            }

            let sex = sexIndex == 1 ? 1 : 0 // 0 female, 1 male (matches source)
            let bmi = weight / pow(height / 100, 2)
            guard bmi >= 18.5, bmi <= 39.9 else {
                return String(format: "Risks are not calculated for BMI out of the range of 18.5 to 39.9 kg/m² (BMI %.1f).", bmi)
            }

            // CKD-EPI eGFR as computed by the source calculator.
            let sexFactor = sex == 0 ? 1.012 : 1.0
            let alpha = sex == 0 ? -0.241 : -0.302
            let kappa = sex == 0 ? 0.7 : 0.9
            let egfr = 142 * pow(min(scr / kappa, 1), alpha) * pow(max(scr / kappa, 1), -1.2) * pow(0.9938, age) * sexFactor
            guard egfr >= 15, egfr <= 140 else {
                return String(format: "Risks are not calculated for eGFR out of the range of 15 to 140 mL/min (eGFR %.0f).", egfr)
            }

            let htnMed = v.selection("htnMed") ?? 0
            let statinMed = v.selection("statinMed") ?? 0
            let diabetes = v.selection("diabetes") ?? 0
            let smoker = v.selection("smoker") ?? 0
            let hba1c = v.number("hba1c")
            let uacr = v.number("uacr")
            var zipCode: Int? = nil
            if let z = v.number("zip"), z > 0 {
                zipCode = Int(z)
            }

            // SDI tier lookup (ZIP padded to 5 digits, as in the source).
            var sdiTier = 0
            if let zipCode {
                var ztxt = String(zipCode)
                while ztxt.count < 5 { ztxt = "0" + ztxt }
                if AhaPrevSdiTier1.zipCodes.contains(ztxt) { sdiTier = 1 }
                else if AhaPrevSdiTier2.zipCodes.contains(ztxt) { sdiTier = 2 }
                else if AhaPrevSdiTier3.zipCodes.contains(ztxt) { sdiTier = 3 }
                else {
                    return "ZIP code \(ztxt) not found in the SDI lookup tables."
                }
            }

            func coeff(_ row: Int, _ n: Int) -> Double {
                switch row {
                case 0: return AhaPrevCoefficients.row0[n]
                case 1: return AhaPrevCoefficients.row1[n]
                case 2: return AhaPrevCoefficients.row2[n]
                case 3: return AhaPrevCoefficients.row3[n]
                case 4: return AhaPrevCoefficients.row4[n]
                case 5: return AhaPrevCoefficients.row5[n]
                case 6: return AhaPrevCoefficients.row6[n]
                case 7: return AhaPrevCoefficients.row7[n]
                case 8: return AhaPrevCoefficients.row8[n]
                case 9: return AhaPrevCoefficients.row9[n]
                case 10: return AhaPrevCoefficients.row10[n]
                case 11: return AhaPrevCoefficients.row11[n]
                case 12: return AhaPrevCoefficients.row12[n]
                case 13: return AhaPrevCoefficients.row13[n]
                case 14: return AhaPrevCoefficients.row14[n]
                case 15: return AhaPrevCoefficients.row15[n]
                case 16: return AhaPrevCoefficients.row16[n]
                case 17: return AhaPrevCoefficients.row17[n]
                case 18: return AhaPrevCoefficients.row18[n]
                case 19: return AhaPrevCoefficients.row19[n]
                case 20: return AhaPrevCoefficients.row20[n]
                case 21: return AhaPrevCoefficients.row21[n]
                case 22: return AhaPrevCoefficients.row22[n]
                case 23: return AhaPrevCoefficients.row23[n]
                case 24: return AhaPrevCoefficients.row24[n]
                case 25: return AhaPrevCoefficients.row25[n]
                case 26: return AhaPrevCoefficients.row26[n]
                case 27: return AhaPrevCoefficients.row27[n]
                case 28: return AhaPrevCoefficients.row28[n]
                case 29: return AhaPrevCoefficients.row29[n]
                case 30: return AhaPrevCoefficients.row30[n]
                default: return AhaPrevCoefficients.row31[n]
                }
            }

            // calcRiskLogit(n) from the source, with n = model index + sex.
            func riskLogit(_ n: Int) -> Double {
                let ageTerm = (age - 55) / 10
                let cholTerm = ((tc - hdl) * 0.02586 - 3.5)
                let hdlTerm = (hdl * 0.02586 - 1.3) / 0.3
                var rl = coeff(0, n) * ageTerm
                    + coeff(1, n) * ageTerm * ageTerm
                    + coeff(2, n) * cholTerm
                    + coeff(3, n) * hdlTerm
                    + coeff(4, n) * (min(sbp, 110) - 110) / 20
                    + coeff(5, n) * (max(sbp, 110) - 130) / 20
                    + coeff(6, n) * Double(diabetes)
                    + coeff(7, n) * Double(smoker)
                    + coeff(8, n) * (min(bmi, 30) - 25) / 5
                    + coeff(9, n) * (max(bmi, 30) - 30) / 5
                    + coeff(10, n) * (min(egfr, 60) - 60) / -15
                    + coeff(11, n) * (max(egfr, 60) - 90) / -15
                    + coeff(12, n) * Double(htnMed)
                    + coeff(13, n) * Double(statinMed)
                    + coeff(14, n) * Double(htnMed) * (max(sbp, 110) - 130) / 20
                    + coeff(15, n) * Double(statinMed) * cholTerm
                    + coeff(16, n) * ageTerm * cholTerm
                    + coeff(17, n) * ageTerm * hdlTerm
                    + coeff(18, n) * ageTerm * (max(sbp, 110) - 130) / 20
                    + coeff(19, n) * ageTerm * Double(diabetes)
                    + coeff(20, n) * ageTerm * Double(smoker)
                    + coeff(21, n) * (max(bmi, 30) - 30) / 5
                    + coeff(22, n) * ageTerm * (min(egfr, 60) - 60) / -15
                    + coeff(31, n)
                let a1cFactor: Double
                if hba1c == nil {
                    a1cFactor = coeff(30, n)
                } else if diabetes == 1 {
                    a1cFactor = (hba1c! - 5.3) * coeff(28, n)
                } else {
                    a1cFactor = (hba1c! - 5.3) * coeff(29, n)
                }
                let uacrFactor: Double
                if uacr == nil || uacr == 0 {
                    uacrFactor = coeff(27, n)
                } else {
                    uacrFactor = log(uacr!) * coeff(26, n)
                }
                let sdiFactor: Double
                switch sdiTier {
                case 1: sdiFactor = 0
                case 2: sdiFactor = coeff(23, n)
                case 3: sdiFactor = coeff(24, n)
                default: sdiFactor = coeff(25, n)
                }
                return rl + a1cFactor + uacrFactor + sdiFactor
            }

            func risk(_ logit: Double) -> Double {
                let e = exp(logit)
                return 100 * e / (1 + e)
            }

            // Model index sets per source: base, HbA1C, UACR, SDI, add-on.
            let hasHba1c = hba1c != nil && hba1c! > 0
            let hasUacr = uacr != nil && uacr! > 0
            let hasZip = sdiTier != 0
            let (t10, a10, hf10, t30, a30, hf30): (Int, Int, Int, Int, Int, Int)
            if !hasHba1c && !hasUacr && !hasZip {
                (t10, a10, hf10) = (48, 50, 52); (t30, a30, hf30) = (54, 56, 58)
            } else if hasHba1c && !hasUacr && !hasZip {
                (t10, a10, hf10) = (12, 14, 16); (t30, a30, hf30) = (18, 20, 22)
            } else if !hasHba1c && hasUacr && !hasZip {
                (t10, a10, hf10) = (24, 26, 28); (t30, a30, hf30) = (30, 32, 34)
            } else if !hasHba1c && !hasUacr && hasZip {
                (t10, a10, hf10) = (36, 38, 40); (t30, a30, hf30) = (42, 44, 46)
            } else {
                (t10, a10, hf10) = (0, 2, 4); (t30, a30, hf30) = (6, 8, 10)
            }

            let model: String
            switch (hasHba1c, hasUacr, hasZip) {
            case (false, false, false): model = "Base model"
            case (true, false, false): model = "HbA1C model"
            case (false, true, false): model = "UACR model"
            case (false, false, true): model = "SDI model"
            default: model = "Add-on model"
            }

            var lines: [String] = []
            let t10r = risk(riskLogit(t10 + sex))
            let a10r = risk(riskLogit(a10 + sex))
            let hf10r = risk(riskLogit(hf10 + sex))
            lines.append("10-year risks (\(model)):")
            lines.append(String(format: "  Total CVD: %.2f%%", t10r))
            lines.append(String(format: "  ASCVD (MI/stroke): %.2f%% — %@", a10r,
                                 a10r < 3 ? "Low risk" : a10r < 5 ? "Borderline risk" : a10r < 10 ? "Intermediate risk" : "High risk"))
            lines.append(String(format: "  Heart failure: %.2f%%", hf10r))

            if age >= 60 {
                lines.append("30-year risks are not calculated for patients ≥60 years old.")
            } else {
                let t30r = risk(riskLogit(t30 + sex))
                let a30r = risk(riskLogit(a30 + sex))
                let hf30r = risk(riskLogit(hf30 + sex))
                lines.append("30-year risks:")
                lines.append(String(format: "  Total CVD: %.2f%%", t30r))
                lines.append(String(format: "  ASCVD (MI/stroke): %.2f%%", a30r))
                lines.append(String(format: "  Heart failure: %.2f%%", hf30r))
            }

            return lines.joined(separator: "\n")
        }
    )
]
