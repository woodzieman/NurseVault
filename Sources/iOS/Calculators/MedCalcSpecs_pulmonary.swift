import Foundation

/// Calculator specs for the Pulmonary and Respiratory & Gas Exchange categories.
/// Sources: BODE.htm, DLCO_Anemia.htm, Flow.htm, LungVolumes.htm, PeakExpFlow.htm,
/// pft_gli_22.htm, SolitaryPulmNod_Cummings.htm, AAGradient.htm, Oxygen.htm,
/// PaO2_FIO2Ratio.htm, PneumoThorax.htm
/// (ArterialBloodGas.htm is a TreeCalc and intentionally has no spec.)
let pulmonaryCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "BODE.htm",
        guide: """
        BODE index for COPD survival prediction: B ody mass index, airflow O bstruction, D yspnea, and E xercise capacity. For each item select the band that fits the patient.

        FEV1 is the post-bronchodilator value as a percentage of predicted; the 6-minute walk distance is from a standard 6MWT; MMRC is the Modified Medical Research Council dyspnea scale.
        """,
        inputs: [
            MedCalcInput("fev1", "FEV1 % Predicted (after bronchodilator)", .choice(options: ["≥65% (0 pts)", "50–64% (1 pt)", "36–49% (2 pts)", "≤35% (3 pts)"])),
            MedCalcInput("walk", "6-Minute Walk Distance", .choice(options: ["≥350 m (0 pts)", "250–349 m (1 pt)", "150–249 m (2 pts)", "≤149 m (3 pts)"])),
            MedCalcInput("mmrc", "MMRC Dyspnea Scale", .choice(options: [
                "MMRC 0: dyspneic on strenuous exercise (0 pts)",
                "MMRC 1: dyspneic walking a slight hill (0 pts)",
                "MMRC 2: dyspneic on level ground; must stop occasionally (1 pt)",
                "MMRC 3: must stop after walking 100 yards or a few minutes (2 pts)",
                "MMRC 4: cannot leave house; breathless dressing (3 pts)"
            ])),
            MedCalcInput("bmi", "Body Mass Index", .choice(options: [">21 kg/m² (0 pts)", "≤21 kg/m² (1 pt)"]))
        ],
        compute: { v in
            let score = (v.selection("fev1").map { [0, 1, 2, 3][$0 % 4] } ?? 0)
                + (v.selection("walk").map { [0, 1, 2, 3][$0 % 4] } ?? 0)
                + (v.selection("mmrc").map { [0, 0, 1, 2, 3][$0 % 5] } ?? 0)
                + (v.selection("bmi") ?? 0)
            let survival: String
            if score <= 2 { survival = "80% (0–2 points)" }
            else if score <= 4 { survival = "67% (3–4 points)" }
            else if score <= 6 { survival = "57% (5–6 points)" }
            else { survival = "18% (7–10 points)" }
            return """
            BODE Index: \(score) points
            Approximate 4-year survival: \(survival)
            """
        }
    ),

    MedCalcSpec(
        fileName: "DLCO_Anemia.htm",
        guide: """
        Corrects a measured DLCO for anemia, since hemoglobin is the oxygen carrier that binds CO. Select sex, enter age, hemoglobin, and the measured DLCO predicted (mL CO/min/mmHg).

        The age-sex factor is 9.38 for females of any age and for patients under 15; 10.22 for males 15 and older. To express the result in mmol/min/kPa, multiply by 0.3348. STPD = standard temperature and pressure, dry.
        """,
        equation: "DLCO Corrected = DLCO Predicted × (1.7 × Hgb / (Age-Sex-Factor + Hgb))",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female (factor 9.38)", "Male (factor 10.22 if ≥15 y)"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (1–120)")),
            MedCalcInput("hgb", "Hemoglobin", .number(unitHint: "g/dL (5–20)")),
            MedCalcInput("dlco", "DLCO Predicted", .number(unitHint: "mL CO/min/mmHg (STPD)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let age = v.number("age"),
                  let hgb = v.number("hgb"), let dlco = v.number("dlco"),
                  hgb > 0 else { return "" }
            let factor = (sexIdx == 0 || age < 15) ? 9.38 : 10.22
            let corrected = dlco * (1.7 * hgb / (factor + hgb))
            return """
            DLCO Corrected for Anemia: \(String(format: "%.1f", corrected)) mL CO/min/mmHg
            (= \(String(format: "%.2f", corrected * 0.3348)) mmol/min/kPa)
            """
        }
    ),

    MedCalcSpec(
        fileName: "Flow.htm",
        guide: """
        Simple flow unit conversion between L/min, L/sec, mL/hr, mL/min, and mL/sec. Enter a value, choose its units and the target units.
        """,
        equation: "Convert via mL/min: L/min ×1000 · L/sec ×60000 · mL/hr ÷60 · mL/min ×1 · mL/sec ×60",
        inputs: [
            MedCalcInput("value", "Value", .number(unitHint: "e.g. 0.5")),
            MedCalcInput("from", "From Units", .choice(options: ["L/min", "L/sec", "mL/hr", "mL/min", "mL/sec"])),
            MedCalcInput("to", "To Units", .choice(options: ["L/min", "L/sec", "mL/hr", "mL/min", "mL/sec"]))
        ],
        compute: { v in
            guard let value = v.number("value"), let fromIdx = v.selection("from"),
                  let toIdx = v.selection("to"), value >= 0 else { return "" }
            let factors: [Double] = [1000, 60000, 1.0 / 60, 1, 60]
            let labels = ["L/min", "L/sec", "mL/hr", "mL/min", "mL/sec"]
            let fromIdxC = min(4, max(0, fromIdx))
            let toIdxC = min(4, max(0, toIdx))
            let converted = value * factors[fromIdxC] / factors[toIdxC]
            return "\(String(format: "%.4g", converted)) \(labels[toIdxC])"
        }
    ),

    MedCalcSpec(
        fileName: "LungVolumes.htm",
        guide: """
        Derives the standard lung capacities from the basic lung volumes. Enter the measured volumes (in liters) for expiratory reserve, residual, inspiratory reserve, tidal, and closing volume.
        """,
        equation: """
        FRC = ERV + RV · IC = IRV + VT · TLC = IRV + VT + ERV + RV · VC = IRV + VT + ERV · CC = CV + RV
        CV/VC = 100 × ClosingVol / VC · CC/TLC = 100 × CC / TLC · RV/TLC = 100 × RV / TLC
        """,
        inputs: [
            MedCalcInput("erv", "Expiratory Reserve Volume (ERV)", .number(unitHint: "L (e.g. 1.1)")),
            MedCalcInput("rv", "Residual Volume (RV)", .number(unitHint: "L (e.g. 1.8)")),
            MedCalcInput("irv", "Inspiratory Reserve Volume (IRV)", .number(unitHint: "L (e.g. 2.5)")),
            MedCalcInput("vt", "Tidal Volume (VT)", .number(unitHint: "L (e.g. 0.5)")),
            MedCalcInput("cv", "Closing Volume (CV)", .number(unitHint: "L (e.g. 0.6)"))
        ],
        compute: { v in
            guard let erv = v.number("erv"), let rv = v.number("rv"),
                  let irv = v.number("irv"), let vt = v.number("vt"),
                  let cv = v.number("cv") else { return "" }
            let frc = erv + rv
            let ic = irv + vt
            let tlc = irv + vt + erv + rv
            let vc = irv + vt + erv
            let cc = cv + rv
            let cvVc = vc > 0 ? 100 * cv / vc : nil
            let ccTlc = tlc > 0 ? 100 * cc / tlc : nil
            let rvTlc = tlc > 0 ? 100 * rv / tlc : nil
            return """
            Functional Residual Capacity (FRC): \(String(format: "%.2f", frc)) L
            Inspiratory Capacity (IC): \(String(format: "%.2f", ic)) L
            Total Lung Capacity (TLC): \(String(format: "%.2f", tlc)) L
            Vital Capacity (VC): \(String(format: "%.2f", vc)) L
            Closing Capacity (CC): \(String(format: "%.2f", cc)) L
            CV/VC: \(cvVc.map { String(format: "%.1f%%", $0) } ?? "—")
            CC/TLC: \(ccTlc.map { String(format: "%.1f%%", $0) } ?? "—")
            RV/TLC: \(rvTlc.map { String(format: "%.1f%%", $0) } ?? "—")
            """
        }
    ),

    MedCalcSpec(
        fileName: "PeakExpFlow.htm",
        guide: """
        Predicted peak expiratory flow (PEF) for adults aged 15–85 from height and age (Nunn & Gregg regression equations). Both sex predictions are shown so the appropriate one can be used.
        """,
        equation: """
        PEF Female = e^(0.376·ln(Age) − 0.012·Age − 58.8/Height + 5.63)
        PEF Male = e^(0.544·ln(Age) − 0.0151·Age − 74.7/Height + 5.48)
        """,
        inputs: [
            MedCalcInput("hgt", "Height", .number(unitHint: "cm (e.g. 170)")),
            MedCalcInput("age", "Age", .number(unitHint: "years (15–85)"))
        ],
        compute: { v in
            guard let hgt = v.number("hgt"), let age = v.number("age"), hgt > 0, age > 0 else { return "" }
            let fe = exp(0.376 * log(age) - 0.012 * age - 58.8 / hgt + 5.63)
            let fm = exp(0.544 * log(age) - 0.0151 * age - 74.7 / hgt + 5.48)
            return """
            Predicted PEF Female: \(String(format: "%.0f", fe)) L/min
            Predicted PEF Male: \(String(format: "%.0f", fm)) L/min
            """
        }
    ),

    MedCalcSpec(
        fileName: "pft_gli_22.htm",
        guide: """
        2022 race-neutral GLI (Global Lung Function Initiative) predicted values for PFTs, ages 3 to 95. Enter sex, age (in years; fractional ages give the most accurate results for young patients), height, and the measured FEV1 and FVC.

        For each variable the result shows the predicted value, percent predicted, Z-score (number of standard deviations from predicted), and the LLN/ULN (5th/95th percentiles). The predicted FEV1/FVC ratio is population-based and is calculated independently from the FEV1 and FVC, so it may differ slightly from simple division of the two predicted values.
        """,
        equation: """
        Predicted = e^(a + b·ln(Height) + c·ln(Age) + M-spline)
        Z = ((measured/M)^L − 1) / (L·S) · LLN = M·(1 − 1.645·L·S)^(1/L) · ULN = M·(1 + 1.645·L·S)^(1/L)
        (GLI-2022 coefficients with age splines from the 2022 global equations)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (3–95; e.g. 8.5)")),
            MedCalcInput("hgt", "Height", .number(unitHint: "cm (e.g. 165)")),
            MedCalcInput("fev1m", "Measured FEV1", .number(unitHint: "L (e.g. 2.8)")),
            MedCalcInput("fvcm", "Measured FVC", .number(unitHint: "L (e.g. 3.5)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let age0 = v.number("age"),
                  let hgt = v.number("hgt"), let fev1m = v.number("fev1m"),
                  let fvcm = v.number("fvcm"),
                  age0 >= 3, age0 <= 95, hgt > 0, fvcm > 0 else { return "" }
            let age = age0
            let pos = age * 4 - 12
            let ratio = fev1m / fvcm
            let female = sexIdx == 0
            let (fev1M, fev1S, fvcM, fvcS, ratioM, ratioS): (Int, Int, Int, Int, Int, Int)
            let (fev1A, fev1H, fev1C, fvcA, fvcH, fvcC, ratioA, ratioH, ratioC,
                 sFev1A, sFev1C, sFvcA, sFvcC, sRatioA, sRatioC): (Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double)
            let (lFev1, lFvc, lRatioA, lRatioC): (Double, Double, Double, Double)
            if female {
                (fev1M, fev1S, fvcM, fvcS, ratioM, ratioS) = (0, 1, 2, 3, 4, 5)
                (fev1A, fev1H, fev1C) = (-10.901689, 2.385928, -0.076386)
                (fvcA, fvcH, fvcC) = (-12.055901, 2.621579, -0.035975)
                (ratioA, ratioH, ratioC) = (0.9189568, -0.1840671, -0.0461306)
                (sFev1A, sFev1C) = (-2.364047, 0.129402)
                (sFvcA, sFvcC) = (-2.310148, 0.120428)
                (sRatioA, sRatioC) = (-3.171582, 0.144358)
                lFev1 = 1.21388
                lFvc = 0.899
                lRatioA = 6.6490
                lRatioC = -0.9920
            } else {
                (fev1M, fev1S, fvcM, fvcS, ratioM, ratioS) = (6, 7, 8, 9, 10, 11)
                (fev1A, fev1H, fev1C) = (-11.399108, 2.462664, -0.011394)
                (fvcA, fvcH, fvcC) = (-12.629131, 2.727421, 0.009174)
                (ratioA, ratioH, ratioC) = (1.022608, -0.218592, -0.027586)
                (sFev1A, sFev1C) = (-2.256278, 0.080729)
                (sFvcA, sFvcC) = (-2.195595, 0.068466)
                (sRatioA, sRatioC) = (-2.882025, 0.068889)
                lFev1 = 1.22703
                lFvc = 0.9346
                lRatioA = 3.8243
                lRatioC = -0.3328
            }
            let lnAge = log(age)
            let lnHgt = log(hgt)
            let fev1Pred = exp(fev1A + fev1H * lnHgt + fev1C * lnAge + MedCalcPftGli22Data.interpSpline(position: pos, column: fev1M))
            let fvcPred = exp(fvcA + fvcH * lnHgt + fvcC * lnAge + MedCalcPftGli22Data.interpSpline(position: pos, column: fvcM))
            let ratioPred = exp(ratioA + ratioH * lnHgt + ratioC * lnAge + MedCalcPftGli22Data.interpSpline(position: pos, column: ratioM))
            let lRatio = lRatioA + lRatioC * lnAge
            let sFev1 = exp(sFev1A + sFev1C * lnAge + MedCalcPftGli22Data.interpSpline(position: pos, column: fev1S))
            let sFvc = exp(sFvcA + sFvcC * lnAge + MedCalcPftGli22Data.interpSpline(position: pos, column: fvcS))
            let sRatio = exp(sRatioA + sRatioC * lnAge + MedCalcPftGli22Data.interpSpline(position: pos, column: ratioS))
            let fev1Z = gliLms(measured: fev1m, l: lFev1, m: fev1Pred, s: sFev1)
            let fvcZ = gliLms(measured: fvcm, l: lFvc, m: fvcPred, s: sFvc)
            let ratioZ = gliLms(measured: ratio, l: lRatio, m: ratioPred, s: sRatio)
            func line(_ name: String, measured: Double, pred: Double, z: (z: Double, lln: Double, uln: Double), vol: Bool) -> String {
                let unit = vol ? " L" : ""
                let pp = pred > 0 ? 100 * measured / pred : 0
                return """
                \(name) Predicted: \(String(format: vol ? "%.2f" : "%.3f", pred))\(unit) · %Pred: \(String(format: "%.1f", pp))% · Z: \(String(format: "%.2f", z.z)) · LLN: \(String(format: vol ? "%.2f" : "%.3f", z.lln))\(unit) · ULN: \(String(format: vol ? "%.2f" : "%.3f", z.uln))\(unit)
                """
            }
            return """
            Measured FEV1/FVC: \(String(format: "%.3f", ratio))
            \(line("FEV1", measured: fev1m, pred: fev1Pred, z: fev1Z, vol: true))
            \(line("FVC", measured: fvcm, pred: fvcPred, z: fvcZ, vol: true))
            \(line("FEV1/FVC", measured: ratio, pred: ratioPred, z: ratioZ, vol: false))
            """
        }
    ),

    MedCalcSpec(
        fileName: "SolitaryPulmNod_Cummings.htm",
        guide: """
        Bayesian prediction of malignancy for a solitary pulmonary nodule (Cummings model). For each feature select the option that fits; "Not available" contributes a neutral factor of 1.

        The model uses a pretest odds of 0.28:1 from the Gurney series — local prevalence may differ.
        """,
        equation: "Post-test odds = 0.28 × Π(feature factors) · Cancer probability = 100 × odds / (1 + odds)",
        inputs: [
            MedCalcInput("age", "Patient Age", .choice(options: ["20–29 (0.05)", "30–39 (0.24)", "40–49 (0.94)", "50–59 (1.9)", "60–69 (2.64)", "≥70 (4.16)"])),
            MedCalcInput("size", "Nodule Size", .choice(options: ["0–1 cm (0.52)", "1.1–2 cm (0.74)", "2.1–3 cm (3.67)", ">3 cm (5.23)"])),
            MedCalcInput("edge", "Edge on CXR", .choice(options: ["Well defined, smooth (0.36)", "Well defined, lobular (1.27)", "Ill defined (2.51)"])),
            MedCalcInput("tomo", "Tomographic Appearance", .choice(options: ["Not available (1)", "Malignant (37.2)", "Intermediate (0.73)", "Benign (0)"])),
            MedCalcInput("edgect", "Edge by CT", .choice(options: ["Not available (1)", "Smooth (0.3)", "Lobulated (0.74)", "Irregular/spicular (5.54)"])),
            MedCalcInput("caltomo", "Calcification on Tomography", .choice(options: ["Not available (1)", "Calcified (0)", "Noncalcified (1.5)"])),
            MedCalcInput("cact", "Calcification on CT", .choice(options: ["Not available (1)", "In phantom, benign (0.07)", "In phantom (2.2)"])),
            MedCalcInput("growth", "Growth Rate", .choice(options: ["Not available (1)", "<7 days (0)", "7–465 days (3.4)", ">465 days (0.01)"])),
            MedCalcInput("loc", "Location", .choice(options: ["Lower lobe (0.66)", "Upper or middle lobe (1.22)"])),
            MedCalcInput("cavity", "Max Cavity Wall Thickness", .choice(options: ["Not available (1)", "≤4 mm (0.07)", "5–15 mm (0.72)", "≥16 mm (37.97)"])),
            MedCalcInput("smoke", "Smoking History", .choice(options: ["Never smoker (0.19)", "Current cigarette smoker (2.27)", "Pipe or cigar smoker (1)", "Ex-cigarette smoker (0.92)", "Ex pipe or cigar smoker (0.55)"])),
            MedCalcInput("hemo", "Hemoptysis", .choice(options: ["No (1)", "Yes (5.08)"])),
            MedCalcInput("malign", "Previous Malignancy", .choice(options: ["No (1)", "Yes (4.95)"]))
        ],
        compute: { v in
            let factors: [[Double]] = [
                [0.05, 0.24, 0.94, 1.9, 2.64, 4.16],
                [0.52, 0.74, 3.67, 5.23],
                [0.36, 1.27, 2.51],
                [1, 37.2, 0.73, 0],
                [1, 0.3, 0.74, 5.54],
                [1, 0, 1.5],
                [1, 0.07, 2.2],
                [1, 0, 3.4, 0.01],
                [0.66, 1.22],
                [1, 0.07, 0.72, 37.97],
                [0.19, 2.27, 1, 0.92, 0.55],
                [1, 5.08],
                [1, 4.95]
            ]
            let ids = ["age", "size", "edge", "tomo", "edgect", "caltomo", "cact", "growth", "loc", "cavity", "smoke", "hemo", "malign"]
            var odds = 0.28
            for (i, id) in ids.enumerated() {
                let idx = min(factors[i].count - 1, max(0, v.selection(id) ?? 0))
                odds *= factors[i][idx]
            }
            let prob = 100 * odds / (1 + odds)
            return """
            Post-test Odds: \(String(format: "%.2f", odds))
            Cancer Probability: \(String(format: "%.2f", prob))%
            """
        }
    ),

    MedCalcSpec(
        fileName: "AAGradient.htm",
        guide: """
        Alveolar-arterial (A-a) oxygen gradient. Enter age, patient temperature, altitude, inspired oxygen percentage, arterial pCO2, respiratory quotient, and arterial pO2 (pressures in mmHg).

        A high A-a gradient indicates an oxygen-transfer/gas-exchange problem (alveolar membrane disease, interstitial disease, or V/Q mismatch). Hypoxemia with a normal gradient implies hypoventilation. The expected-gradient equation assumes room air and is less accurate at higher inspired O2.
        """,
        equation: """
        pAtm = 760 · e^(Elevation/−7000) · pH2O = 47 · e^((Temp−37)/18.4) · FIO2 = %O2/100
        Expected A-a = 2.5 + 0.21 × Age
        Measured A-a = FIO2·(pAtm − pH2O) − pCO2/RQ + pCO2·FIO2·(1−RQ)/RQ − paO2
        """,
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 60)")),
            MedCalcInput("temp", "Patient Temperature", .number(unitHint: "°C (e.g. 37)")),
            MedCalcInput("elev", "Elevation", .number(unitHint: "meters (0–10000)")),
            MedCalcInput("o2", "Percent Inspired O2", .number(unitHint: "% (21 for room air)")),
            MedCalcInput("pco2", "Arterial pCO2", .number(unitHint: "mmHg (e.g. 40)")),
            MedCalcInput("rq", "Respiratory Quotient", .number(unitHint: "ratio (0.8 typical)")),
            MedCalcInput("pao2", "Arterial pO2", .number(unitHint: "mmHg (e.g. 85)"))
        ],
        compute: { v in
            guard let age = v.number("age"), let temp = v.number("temp"),
                  let elev = v.number("elev"), let o2 = v.number("o2"),
                  let pco2 = v.number("pco2"), let rq = v.number("rq"),
                  let pao2 = v.number("pao2"), rq > 0 else { return "" }
            let pAtm = 760 * exp(elev / -7000)
            let pH2O = 47 * exp((temp - 37) / 18.4)
            let fio2 = o2 / 100
            let expected = 2.5 + 0.21 * age
            let measured = fio2 * (pAtm - pH2O) - pco2 / rq + pco2 * fio2 * (1 - rq) / rq - pao2
            let note: String
            if measured <= expected { note = "Within the expected range — hypoxemia (if any) is most consistent with hypoventilation." }
            else { note = "Elevated above the expected gradient — suggests a gas-exchange problem (V/Q mismatch, shunt, or membrane disease)." }
            return """
            Expected A-a Gradient: \(String(format: "%.1f", expected)) mmHg
            Measured A-a Gradient: \(String(format: "%.1f", measured)) mmHg
            \(note)
            """
        }
    ),

    MedCalcSpec(
        fileName: "Oxygen.htm",
        guide: """
        Converts between percent oxygen and liters/minute via nasal cannula (1 L/min ≈ 3% inspired O2).
        """,
        equation: "%O2 = LitresO2(nasal) × 3",
        inputs: [
            MedCalcInput("value", "Value", .number(unitHint: "e.g. 4")),
            MedCalcInput("from", "From Units", .choice(options: ["%O2", "L/min (nasal)"])),
            MedCalcInput("to", "To Units", .choice(options: ["%O2", "L/min (nasal)"]))
        ],
        compute: { v in
            guard let value = v.number("value"), let fromIdx = v.selection("from"),
                  let toIdx = v.selection("to"), value >= 0 else { return "" }
            let fromPct = min(1, max(0, fromIdx)) == 0
            let toPct = min(1, max(0, toIdx)) == 0
            var pct = value
            if !fromPct { pct *= 3 }
            if fromPct == toPct { return "\(String(format: "%.2f", pct)) %O2" }
            return toPct ? "\(String(format: "%.1f", pct)) %O2" : "\(String(format: "%.1f", pct / 3)) L/min (nasal)"
        }
    ),

    MedCalcSpec(
        fileName: "PaO2_FIO2Ratio.htm",
        guide: """
        PaO2/FiO2 ratio, used for MODS criteria and ARDS staging. Enter arterial pO2 (mmHg) and the inspired oxygen fraction (e.g. 0.21 for room air, 1.0 for 100% O2).
        """,
        equation: "PaO2/FiO2 Ratio = PaO2 / FIO2",
        inputs: [
            MedCalcInput("pao2", "Arterial pO2", .number(unitHint: "mmHg (e.g. 80)")),
            MedCalcInput("fio2", "FiO2 (Fraction of Inspired O2)", .number(unitHint: "0–1 (e.g. 0.21)"))
        ],
        compute: { v in
            guard let pao2 = v.number("pao2"), let fio2 = v.number("fio2"), fio2 > 0 else { return "" }
            let ratio = pao2 / fio2
            let stage = ratio >= 300 ? "No oxygenation impairment (≥300)"
                : ratio >= 200 ? "Mild ARDS (200–299)"
                : ratio >= 100 ? "Moderate ARDS (100–199)"
                : "Severe ARDS (<100)"
            return """
            PaO2/FiO2 Ratio: \(String(format: "%.0f", ratio))
            \(stage)
            """
        }
    ),

    MedCalcSpec(
        fileName: "PneumoThorax.htm",
        guide: """
        Estimates the percent of pneumothorax (degree of lung collapse) from the chest x-ray by comparing lung and hemithorax diameters. Use average lung and hemithorax diameters (cm).
        """,
        equation: "Percent Pneumothorax = 100 × (1 − (LungDiameter³ / HemithoraxDiameter³))",
        inputs: [
            MedCalcInput("lung", "Lung Diameter", .number(unitHint: "cm (e.g. 8)")),
            MedCalcInput("hemi", "Hemithorax Diameter", .number(unitHint: "cm (e.g. 10)"))
        ],
        compute: { v in
            guard let lung = v.number("lung"), let hemi = v.number("hemi"), hemi > 0 else { return "" }
            let pct = 100 * (1 - pow(lung / hemi, 3))
            return "Estimated Pneumothorax: \(String(format: "%.0f", pct))% collapse"
        }
    )
]

/// GLI lognormal LMS Z-score with lower/upper limits of normal.
private func gliLms(measured: Double, l: Double, m: Double, s: Double) -> (z: Double, lln: Double, uln: Double) {
    let z = (pow(measured / m, l) - 1) / (l * s)
    let lln = m * pow(1 + l * s * -1.645, 1 / l)
    let uln = m * pow(1 + l * s * 1.645, 1 / l)
    return (z, lln, uln)
}
