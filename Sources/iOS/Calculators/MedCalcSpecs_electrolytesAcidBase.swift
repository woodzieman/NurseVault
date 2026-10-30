import Foundation

/// Calculator specs for the Electrolytes & Acid-Base category.
/// Sources: AnionGap.htm, AnionGapDeltaGradient.htm, AnionGapHypoAlb.htm,
/// CalciumAlbumin(_SI).htm, FractExcSodium(_SI).htm, HendersonHasselbach.htm,
/// HyponatremiaCorrection.htm, Osmolality.htm, Sodium*.htm, TBW*.htm,
/// UrineAnionGap.htm, WaterDeficit.htm, WinterFormula.htm
let electrolytesAcidBaseCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "AnionGap.htm",
        guide: """
        The anion gap (AG) is derived from the major serum electrolytes and helps classify metabolic acidemias. A typical reference range is 8–12 mEq/L (laboratories vary).

        Enter sodium, chloride, and bicarbonate in mEq/L. A high AG indicates an unmeasured anion (lactate, ketones, toxins); a normal AG acidosis is usually hyperchloremic (diarrhea, renal tubular acidosis).
        """,
        equation: "AG = Na − (Cl + HCO3)",
        inputs: [
            MedCalcInput("na", "Sodium (Na)", .number(unitHint: "mEq/L (e.g. 140)")),
            MedCalcInput("cl", "Chloride (Cl)", .number(unitHint: "mEq/L (e.g. 100)")),
            MedCalcInput("hco3", "Bicarbonate (HCO3)", .number(unitHint: "mEq/L (e.g. 24)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let cl = v.number("cl"), let hco3 = v.number("hco3") else { return "" }
            let ag = na - (cl + hco3)
            return "Anion Gap: \(String(format: "%.1f mEq/L", ag))"
        }
    ),

    MedCalcSpec(
        fileName: "AnionGapDeltaGradient.htm",
        guide: """
        The delta-delta gradient identifies mixed acid-base disorders in anion gap acidemias. Enter sodium, chloride, bicarbonate, and the patient's baseline anion gap (usually 12 mEq/L).

        Interpretation:
        • Around 0: simple high anion gap metabolic acidosis
        • Significantly > 0: high AG acidosis plus metabolic alkalosis (or chronic respiratory acidosis, or a non-acidotic high AG state such as excess penicillin)
        • Significantly < 0: high AG acidosis plus a normal-AG (hyperchloremic) acidosis, or with chronic respiratory alkalosis / pre-existing low AG (hypoalbuminemia, paraproteinemia)
        """,
        equation: """
        AnionGap = Na − (Cl + HCO3)
        DeltaGap = AnionGap − BaselineGap
        DeltaHCO3 = 25 − HCO3
        DeltaDeltaGradient = DeltaGap − DeltaHCO3
        """,
        inputs: [
            MedCalcInput("na", "Sodium (Na)", .number(unitHint: "mEq/L (e.g. 140)")),
            MedCalcInput("cl", "Chloride (Cl)", .number(unitHint: "mEq/L (e.g. 100)")),
            MedCalcInput("hco3", "Bicarbonate (HCO3)", .number(unitHint: "mEq/L (e.g. 12)")),
            MedCalcInput("basegap", "Baseline Anion Gap", .number(unitHint: "mEq/L (usually 12)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let cl = v.number("cl"),
                  let hco3 = v.number("hco3"), let base = v.number("basegap") else { return "" }
            let ag = na - (cl + hco3)
            let deltaGap = ag - base
            let deltaHco3 = 25 - hco3
            let ddg = deltaGap - deltaHco3
            let interp: String
            if ddg > -5 && ddg <= 5 { interp = "≈ 0 — simple high anion gap metabolic acidosis" }
            else if ddg < -5 { interp = "Significantly negative — high AG acidosis plus normal-AG acidosis (or chronic resp alkalosis / low baseline AG)" }
            else { interp = "Significantly positive — high AG acidosis plus metabolic alkalosis (or chronic resp acidosis)" }
            return """
            Anion Gap: \(String(format: "%.1f", ag))
            Delta Gap: \(String(format: "%.1f", deltaGap))
            Delta HCO3: \(String(format: "%.1f", deltaHco3))
            Delta-Delta Gradient: \(String(format: "%.1f", ddg))
            \(interp)
            """
        }
    ),

    MedCalcSpec(
        fileName: "AnionGapHypoAlb.htm",
        guide: """
        Albumin is a major unmeasured anion; hypoalbuminemia lowers the anion gap and can mask an anion gap acidosis. This calculator adjusts the AG for the patient's albumin.

        Enter sodium, chloride, bicarbonate (mEq/L), the normal albumin used by your lab (usually 4.0 or 4.4 g/dL), and the patient's observed albumin (g/dL).
        """,
        equation: """
        AnionGap = Na − Cl − HCO3
        AdjustedGap = AnionGap + 2.5 × (NormalAlb − ObservedAlb)
        """,
        inputs: [
            MedCalcInput("na", "Sodium (Na)", .number(unitHint: "mEq/L (e.g. 140)")),
            MedCalcInput("cl", "Chloride (Cl)", .number(unitHint: "mEq/L (e.g. 100)")),
            MedCalcInput("hco3", "Bicarbonate (HCO3)", .number(unitHint: "mEq/L (e.g. 24)")),
            MedCalcInput("normalalb", "Normal Albumin (lab reference)", .number(unitHint: "g/dL (usually 4.0)")),
            MedCalcInput("obsalb", "Observed Albumin", .number(unitHint: "g/dL (e.g. 2.0)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let cl = v.number("cl"), let hco3 = v.number("hco3"),
                  let normalAlb = v.number("normalalb"), let obsAlb = v.number("obsalb") else { return "" }
            let ag = na - cl - hco3
            let adj = ag + 2.5 * (normalAlb - obsAlb)
            return """
            Anion Gap: \(String(format: "%.1f mEq/L", ag))
            Albumin-Adjusted Gap: \(String(format: "%.1f mEq/L", adj))
            """
        }
    ),

    MedCalcSpec(
        fileName: "CalciumAlbumin.htm",
        guide: """
        Corrects a low measured serum calcium for hypoalbuminemia (Payne correction): roughly 0.8 mg/dL of calcium is bound per 1 g/dL of albumin.

        Choose the normal albumin reference (4 or 4.4 g/dL — practice varies), then enter the measured serum calcium and the patient's albumin in g/dL.
        """,
        equation: "CorrectedCa = SerumCa + 0.8 × (NormalAlbumin − PatientAlbumin)",
        inputs: [
            MedCalcInput("ca", "Measured Serum Calcium", .number(unitHint: "mg/dL (e.g. 8.5)")),
            MedCalcInput("normalalb", "Normal Albumin Reference", .choice(options: ["4 g/dL", "4.4 g/dL"])),
            MedCalcInput("alb", "Patient Albumin", .number(unitHint: "g/dL (e.g. 2.5)"))
        ],
        compute: { v in
            guard let ca = v.number("ca"), let alb = v.number("alb"), let normalIdx = v.selection("normalalb") else { return "" }
            let normalAlb = normalIdx == 1 ? 4.4 : 4.0
            let corrected = ca + 0.8 * (normalAlb - alb)
            return "Corrected Calcium: \(String(format: "%.2f mg/dL", corrected))"
        }
    ),

    MedCalcSpec(
        fileName: "CalciumAlbumin_SI.htm",
        guide: """
        SI-unit version of the Payne calcium correction for hypoalbuminemia (0.02 mmol/L per g/L of albumin difference).

        Choose the normal albumin reference (40 or 44 g/L), then enter the measured serum calcium in mmol/L and the patient's albumin in g/L.
        """,
        equation: "CorrectedCa = SerumCa + 0.02 × (NormalAlbumin − PatientAlbumin)",
        inputs: [
            MedCalcInput("ca", "Measured Serum Calcium", .number(unitHint: "mmol/L (e.g. 2.1)")),
            MedCalcInput("normalalb", "Normal Albumin Reference", .choice(options: ["40 g/L", "44 g/L"])),
            MedCalcInput("alb", "Patient Albumin", .number(unitHint: "g/L (e.g. 25)"))
        ],
        compute: { v in
            guard let ca = v.number("ca"), let alb = v.number("alb"), let normalIdx = v.selection("normalalb") else { return "" }
            let normalAlb = normalIdx == 1 ? 44.0 : 40.0
            let corrected = ca + 0.02 * (normalAlb - alb)
            return "Corrected Calcium: \(String(format: "%.2f mmol/L", corrected))"
        }
    ),

    MedCalcSpec(
        fileName: "FractExcSodium.htm",
        guide: """
        The fractional excretion of sodium (FENa) helps distinguish acute tubular necrosis from prerenal azotemia. Enter the paired urine and serum sodium (mEq/L) and creatinine (mg/dL).

        • FENa < 1%: usually prerenal (dehydration, prerenal azotemia)
        • FENa > 2%: usually acute tubular necrosis
        • 1–2%: indeterminate — either may be present
        """,
        equation: "FENa = (UrineNa / SerumNa) / (UrineCr / SerumCr) × 100",
        inputs: [
            MedCalcInput("una", "Urine Sodium", .number(unitHint: "mEq/L (e.g. 40)")),
            MedCalcInput("sna", "Serum Sodium", .number(unitHint: "mEq/L (e.g. 140)")),
            MedCalcInput("ucr", "Urine Creatinine", .number(unitHint: "mg/dL (e.g. 100)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.2)"))
        ],
        compute: { v in
            guard let una = v.number("una"), let sna = v.number("sna"),
                  let ucr = v.number("ucr"), let scr = v.number("scr") else { return "" }
            guard sna > 0, ucr > 0, scr > 0 else { return "" }
            let fena = (una / sna) / (ucr / scr) * 100
            let interp = fena < 1 ? "Prerenal (e.g. dehydration, prerenal azotemia)"
                : fena > 2 ? "Acute tubular necrosis likely"
                : "Indeterminate (1–2%) — either prerenal or ATN"
            return "FENa: \(String(format: "%.2f%%", fena))\n\(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "FractExcSodium_SI.htm",
        guide: """
        SI-unit version of the fractional excretion of sodium (FENa). Enter the paired urine and serum sodium (mmol/L) and creatinine (µmol/L) values.

        • FENa < 1%: usually prerenal
        • FENa > 2%: usually acute tubular necrosis
        • 1–2%: indeterminate
        """,
        equation: "FENa = (UrineNa / SerumNa) / (UrineCr / SerumCr) × 100",
        inputs: [
            MedCalcInput("una", "Urine Sodium", .number(unitHint: "mmol/L (e.g. 40)")),
            MedCalcInput("sna", "Serum Sodium", .number(unitHint: "mmol/L (e.g. 140)")),
            MedCalcInput("ucr", "Urine Creatinine", .number(unitHint: "µmol/L (e.g. 1000)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "µmol/L (e.g. 110)"))
        ],
        compute: { v in
            guard let una = v.number("una"), let sna = v.number("sna"),
                  let ucr = v.number("ucr"), let scr = v.number("scr") else { return "" }
            guard sna > 0, ucr > 0, scr > 0 else { return "" }
            let fena = (una / sna) / (ucr / scr) * 100
            let interp = fena < 1 ? "Prerenal (e.g. dehydration, prerenal azotemia)"
                : fena > 2 ? "Acute tubular necrosis likely"
                : "Indeterminate (1–2%) — either prerenal or ATN"
            return "FENa: \(String(format: "%.2f%%", fena))\n\(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "HendersonHasselbach.htm",
        guide: """
        The Henderson-Hasselbalch equation relates blood pH to bicarbonate and the partial pressure of carbon dioxide. Enter HCO3 in mEq/L and PaCO2 in mmHg from an arterial or venous blood gas.

        Typical reference: pH 7.35–7.45, PaCO2 35–45 mmHg, HCO3 22–26 mEq/L.
        """,
        equation: "pH = 6.1 + log10(HCO3 / (0.03 × PaCO2))",
        inputs: [
            MedCalcInput("hco3", "Bicarbonate (HCO3)", .number(unitHint: "mEq/L (e.g. 24)")),
            MedCalcInput("pco2", "PaCO2", .number(unitHint: "mmHg (e.g. 40)"))
        ],
        compute: { v in
            guard let hco3 = v.number("hco3"), let pco2 = v.number("pco2"),
                  hco3 > 0, pco2 > 0 else { return "" }
            let ph = 6.1 + log10(hco3 / (0.03 * pco2))
            let status = ph < 7.35 ? "Acidemia" : ph > 7.45 ? "Alkalemia" : "Normal"
            return "pH: \(String(format: "%.3f", ph)) (\(status))"
        }
    ),

    MedCalcSpec(
        fileName: "HyponatremiaCorrection.htm",
        guide: """
        Doses a hypertonic or isotonic infusion to achieve a target rate of serum sodium rise in hyponatremia.

        Enter the current serum Na (mEq/L), the desired change per hour (mEq/L/hr), the patient's weight (kg), choose the body-water fraction (by age/sex) and the IV fluid. Add any added IV potassium (mEq/L).

        ⚠️ Correcting sodium too rapidly can cause osmotic demyelination. Keep total correction ≤ 8 mEq/L/day; in severe symptomatic hyponatremia the initial rate may be 1–2 mEq/L/hr for a few hours. Mild cases are often managed with fluid restriction (800–1200 mL/day). Hypokalemia worsens cerebral effects and should be corrected.
        """,
        equation: """
        InfusateRate = (1000 × SerumNaChangePerHr × ((WaterFract × Weight) + 1)) / (IVNa + IVK − SerumNa)
        SerumNaChangePerLiter = (IVNa + IVK − SerumNa) / ((WaterFract × Weight) + 1)
        """,
        inputs: [
            MedCalcInput("na", "Serum Sodium", .number(unitHint: "mEq/L (e.g. 120)")),
            MedCalcInput("change", "Desired Na Change Per Hour", .number(unitHint: "mEq/L/hr (e.g. 1)")),
            MedCalcInput("wfract", "Body Water Fraction", .choice(options: ["Child (0.6)", "Adult Female (0.5)", "Elderly Female (0.45)", "Adult Male (0.6)", "Elderly Male (0.5)"])),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 70)")),
            MedCalcInput("ivna", "IV Solution", .choice(options: ["5% NaCl (855 mEq/L)", "3% NaCl (513 mEq/L)", "0.9% NaCl (154 mEq/L)", "Ringer Lactate (134 mEq/L Na)"])),
            MedCalcInput("ivk", "Added IV Potassium", .number(unitHint: "mEq/L (e.g. 0)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let change = v.number("change"),
                  let wgt = v.number("wgt"), let ivk = v.number("ivk"),
                  let wf = v.selection("wfract"), let ivIdx = v.selection("ivna") else { return "" }
            let waterFract = [0.6, 0.5, 0.45, 0.6, 0.5][wf]
            let ivNa = [855.0, 513, 154, 134][ivIdx]
            let tbw = waterFract * wgt
            let changePerLiter = (ivNa + ivk - na) / (tbw + 1)
            guard changePerLiter != 0 else { return "" }
            let rate = 1000 * change * (tbw + 1) / (ivNa + ivk - na)
            return """
            Na Change Per Liter of Infusate: \(String(format: "%.2f mEq/L", changePerLiter))
            Infusate Rate: \(String(format: "%.1f mL/hr", rate))
            """
        }
    ),

    MedCalcSpec(
        fileName: "Osmolality.htm",
        guide: """
        Estimates serum (effective osmotic) osmolality from the major solutes. Enter sodium (mEq/L), glucose (mg/dL), and BUN (mg/dL).

        A measured osmolality that exceeds the calculated value by more than about 10–20 mOsm/kg indicates an osmolar gap, suggesting unmeasured solutes (ethanol, methanol, ethylene glycol, acetone, isopropyl alcohol).
        """,
        equation: "Osmolality = (Na × 2) + (Glucose / 18) + (BUN / 2.8)",
        inputs: [
            MedCalcInput("na", "Sodium", .number(unitHint: "mEq/L (e.g. 140)")),
            MedCalcInput("glu", "Glucose", .number(unitHint: "mg/dL (e.g. 100)")),
            MedCalcInput("bun", "BUN", .number(unitHint: "mg/dL (e.g. 15)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let glu = v.number("glu"), let bun = v.number("bun") else { return "" }
            let osm = 2 * na + glu / 18 + bun / 2.8
            return "Calculated Osmolality: \(String(format: "%.1f mOsm/kg", osm))"
        }
    ),

    MedCalcSpec(
        fileName: "SodiumProtein.htm",
        guide: """
        Hyperproteinemia (total serum protein > 8 g/dL) can falsely raise measured sodium by up to about 0.25 mEq/L per g/dL above 8. Enter the total serum protein in g/dL; the result is the estimated change in the measured value.
        """,
        equation: "NaChange = (SerumProtein − 8) × 0.25",
        inputs: [
            MedCalcInput("prot", "Serum Protein", .number(unitHint: "g/dL (e.g. 9)"))
        ],
        compute: { v in
            guard let prot = v.number("prot") else { return "" }
            let change = (prot - 8) * 0.25
            let direction = change >= 0 ? "may falsely raise" : "may falsely lower"
            return "Na Change: \(String(format: "%+.2f mEq/L", change)) — measured value \(direction)"
        }
    ),

    MedCalcSpec(
        fileName: "SodiumLipids.htm",
        guide: """
        With indirect ion-selective electrode (ISE) methods, severe hyperlipidemia dilutes the sample and can falsely lower measured sodium (pseudohyponatremia) by about 0.002 mEq/L per mg/dL of triglycerides. Direct ISE avoids this.

        Enter the triglycerides in mg/dL; the result is the estimated change in the measured value.
        """,
        equation: "NaChange = Triglycerides × 0.002",
        inputs: [
            MedCalcInput("tg", "Triglycerides", .number(unitHint: "mg/dL (e.g. 1000)"))
        ],
        compute: { v in
            guard let tg = v.number("tg") else { return "" }
            let change = tg * 0.002
            return "Na Change: \(String(format: "%.1f mEq/L", change)) — consider a direct ISE measurement"
        }
    ),

    MedCalcSpec(
        fileName: "SodiumHyperglycemiaKatz.htm",
        guide: """
        Hyperglycemia draws water from the intracellular space and dilutes sodium. Katz (1973) correction: add 0.016 mEq/L for each mg/dL of glucose above 100 (equivalent to the commonly cited 1.6 mEq/L per 100 mg/dL).

        Enter the measured sodium (mEq/L) and the glucose (mg/dL); the result is the corrected sodium.
        """,
        equation: "CorrectedSodium = MeasuredSodium + 0.016 × (Glucose − 100)",
        inputs: [
            MedCalcInput("na", "Measured Sodium", .number(unitHint: "mEq/L (e.g. 125)")),
            MedCalcInput("glu", "Glucose", .number(unitHint: "mg/dL (e.g. 400)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let glu = v.number("glu") else { return "" }
            let corrected = na + 0.016 * (glu - 100)
            return "Corrected Sodium: \(String(format: "%.1f mEq/L", corrected))"
        }
    ),

    MedCalcSpec(
        fileName: "SodiumDeficit.htm",
        guide: """
        Estimates the total body sodium deficit in hyponatremia to guide replacement. Choose sex (the TBW factor is 0.6 for males, 0.5 for females), enter the normal weight (kg), current serum Na, and the desired target Na (mEq/L).
        """,
        equation: "NaDeficit = TBWFactor × Weight × (DesiredNa − SerumNa)",
        inputs: [
            MedCalcInput("sex", "Sex (TBW factor)", .choice(options: ["Female (0.5)", "Male (0.6)"])),
            MedCalcInput("wgt", "Normal Weight", .number(unitHint: "kg (e.g. 70)")),
            MedCalcInput("na", "Serum Sodium", .number(unitHint: "mEq/L (e.g. 125)")),
            MedCalcInput("target", "Desired Sodium", .number(unitHint: "mEq/L (e.g. 140)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let target = v.number("target"),
                  let wgt = v.number("wgt"), let sexIdx = v.selection("sex") else { return "" }
            let tbw = sexIdx == 0 ? 0.5 : 0.6
            let deficit = tbw * wgt * (target - na)
            return "Na Deficit: \(String(format: "%.0f mEq Na", deficit))"
        }
    ),

    MedCalcSpec(
        fileName: "TBW_58.htm",
        guide: """
        Estimates total body water from weight alone using the 58% rule. Enter the weight in kilograms; the result is in liters.
        """,
        equation: "TBW = Weight × 0.58",
        inputs: [
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 70)"))
        ],
        compute: { v in
            guard let wgt = v.number("wgt") else { return "" }
            return "Total Body Water: \(String(format: "%.1f L", wgt * 0.58))"
        }
    ),

    MedCalcSpec(
        fileName: "TBW_M_Watson.htm",
        guide: """
        Watson's formula (1980) estimates total body water in men from age, height, and weight. Enter age in years, height in cm, and weight in kg; the result is in liters.
        """,
        equation: "TBW = 2.447 − (0.09156 × Age) + (0.1074 × Height) + (0.3362 × Weight)",
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 50)")),
            MedCalcInput("hgt", "Height", .number(unitHint: "cm (e.g. 178)")),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 80)"))
        ],
        compute: { v in
            guard let age = v.number("age"), let hgt = v.number("hgt"), let wgt = v.number("wgt") else { return "" }
            let tbw = 2.447 - (0.09156 * age) + (0.1074 * hgt) + (0.3362 * wgt)
            return "Total Body Water: \(String(format: "%.1f L", tbw))"
        }
    ),

    MedCalcSpec(
        fileName: "TBW_W_Watson.htm",
        guide: """
        Watson's formula (1980) estimates total body water in women from height and weight. Enter height in cm and weight in kg; the result is in liters.
        """,
        equation: "TBW = (0.1069 × Height) + (0.2466 × Weight) − 2.097",
        inputs: [
            MedCalcInput("hgt", "Height", .number(unitHint: "cm (e.g. 165)")),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 65)"))
        ],
        compute: { v in
            guard let hgt = v.number("hgt"), let wgt = v.number("wgt") else { return "" }
            let tbw = (0.1069 * hgt) + (0.2466 * wgt) - 2.097
            return "Total Body Water: \(String(format: "%.1f L", tbw))"
        }
    ),

    MedCalcSpec(
        fileName: "UrineAnionGap.htm",
        guide: """
        The urine anion gap estimates urinary ammonium (an unmeasured cation) to distinguish renal from extrarenal causes of normal-anion-gap metabolic acidosis. Enter urine Na, K, and Cl in mEq/L.

        On a normal diet the value is typically −20 to −50 mEq/L (ammonium excretion).
        • Positive UAG: impaired ammonium excretion — renal tubular acidosis
        • Negative UAG: appropriate renal ammonium excretion — extrarenal loss (e.g. diarrhea)
        """,
        equation: "UrineAG = (Na + K) − Cl",
        inputs: [
            MedCalcInput("na", "Urine Sodium", .number(unitHint: "mEq/L (e.g. 40)")),
            MedCalcInput("k", "Urine Potassium", .number(unitHint: "mEq/L (e.g. 20)")),
            MedCalcInput("cl", "Urine Chloride", .number(unitHint: "mEq/L (e.g. 30)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let k = v.number("k"), let cl = v.number("cl") else { return "" }
            let uag = (na + k) - cl
            let interp = uag > 0 ? "Positive — renal cause (e.g. renal tubular acidosis)"
                : "Negative — extrarenal loss (e.g. diarrhea)"
            return "Urine Anion Gap: \(String(format: "%.1f mEq/L", uag))\n\(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "WaterDeficit.htm",
        guide: """
        Estimates the free-water deficit in hypernatremia. Choose the age/sex body-water factor (0.6 / 0.5 / 0.45), enter the patient's normal weight (kg), the current serum Na, and the desired target Na (mEq/L).
        """,
        equation: """
        WaterDeficit = (TBWFactor × Weight) × (SerumNa − DesiredNa) / DesiredNa
        """,
        inputs: [
            MedCalcInput("factor", "Age/Sex TBW Factor", .choice(options: ["Male < 65 (0.6)", "Male ≥ 65 (0.5)", "Female < 18 (0.6)", "Female 18–65 (0.5)", "Female ≥ 65 (0.45)"])),
            MedCalcInput("wgt", "Normal Weight", .number(unitHint: "kg (e.g. 70)")),
            MedCalcInput("na", "Serum Sodium", .number(unitHint: "mEq/L (e.g. 150)")),
            MedCalcInput("target", "Desired Sodium", .number(unitHint: "mEq/L (e.g. 140)"))
        ],
        compute: { v in
            guard let na = v.number("na"), let target = v.number("target"),
                  let wgt = v.number("wgt"), let factorIdx = v.selection("factor") else { return "" }
            guard target > 0 else { return "" }
            let factor = [0.6, 0.5, 0.6, 0.5, 0.45][factorIdx]
            let deficit = (factor * wgt) * (na - target) / target
            return "Water Deficit: \(String(format: "%.1f L", deficit))"
        }
    ),

    MedCalcSpec(
        fileName: "WinterFormula.htm",
        guide: """
        Winter's formula estimates the expected respiratory compensation (PaCO2) for a given serum bicarbonate in metabolic acidosis. Enter HCO3 in mEq/L.

        If the measured PaCO2 differs from the expected value by more than ±2 mmHg, suspect a concurrent (mixed) respiratory disorder.
        """,
        equation: "Expected PaCO2 = (1.5 × HCO3) + 8 (± 2)",
        inputs: [
            MedCalcInput("hco3", "Bicarbonate (HCO3)", .number(unitHint: "mEq/L (e.g. 12)"))
        ],
        compute: { v in
            guard let hco3 = v.number("hco3") else { return "" }
            let pco2 = 1.5 * hco3 + 8
            return "Expected PaCO2: \(String(format: "%.1f", pco2)) − \(String(format: "%.1f", pco2 + 2)) mmHg (± 2)"
        }
    )
]
