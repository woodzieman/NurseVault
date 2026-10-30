import Foundation

/// Martin LDL "Novel Factor" table: row = triglyceride band, column = non-HDL cholesterol band.
/// Rows (TG mg/dL): <100, 100-129, 130-159, 160-189, 190-219, ≥220 (source lookup thresholds).
private let martinNovelFactors: [[Double]] = [
    [3.5, 3.4, 3.3, 3.3, 3.2, 3.1],
    [4.0, 3.9, 3.7, 3.6, 3.6, 3.4],
    [4.3, 4.1, 4.0, 3.9, 3.8, 3.6],
    [4.5, 4.3, 4.1, 4.0, 3.9, 3.9],
    [4.7, 4.4, 4.3, 4.2, 4.1, 3.9],
    [4.8, 4.6, 4.4, 4.2, 4.2, 4.1],
    [4.9, 4.6, 4.5, 4.3, 4.3, 4.2],
    [5.0, 4.8, 4.6, 4.4, 4.3, 4.2],
    [5.1, 4.8, 4.6, 4.5, 4.4, 4.3],
    [5.2, 4.9, 4.7, 4.6, 4.4, 4.3],
    [5.3, 5.0, 4.8, 4.7, 4.5, 4.4],
    [5.4, 5.1, 4.8, 4.7, 4.5, 4.3],
    [5.5, 5.2, 5.0, 4.7, 4.6, 4.5],
    [5.6, 5.3, 5.0, 4.8, 4.6, 4.5],
    [5.7, 5.4, 5.1, 4.9, 4.7, 4.5],
    [5.8, 5.5, 5.2, 5.0, 4.8, 4.6],
    [6.0, 5.5, 5.3, 5.0, 4.8, 4.6],
    [6.1, 5.7, 5.3, 5.1, 4.9, 4.7],
    [6.2, 5.8, 5.4, 5.2, 5.0, 4.7],
    [6.3, 5.9, 5.6, 5.3, 5.0, 4.8],
    [6.5, 6.0, 5.7, 5.4, 5.1, 4.8],
    [6.7, 6.2, 5.8, 5.4, 5.2, 4.9],
    [6.8, 6.3, 5.9, 5.5, 5.3, 5.0],
    [7.0, 6.5, 6.0, 5.7, 5.4, 5.1],
    [7.3, 6.7, 6.2, 5.8, 5.5, 5.2],
    [7.6, 6.9, 6.4, 6.0, 5.6, 5.3],
    [8.0, 7.2, 6.6, 6.2, 5.9, 5.4],
    [8.5, 7.6, 7.0, 6.5, 6.1, 5.6],
    [9.5, 8.3, 7.5, 7.0, 6.5, 5.9],
    [11.9, 10.0, 8.8, 8.1, 7.5, 6.7]
]

/// Martin equation row index from triglycerides (mg/dL), matching the source lookup.
private func martinRow(_ tg: Double) -> Int {
    switch tg {
    case 400...: return 29
    case 293..<400: return 28
    case 248..<293: return 27
    case 221..<248: return 26
    case 202..<221: return 25
    case 186..<202: return 24
    case 174..<186: return 23
    case 164..<174: return 22
    case 155..<164: return 21
    case 147..<155: return 20
    case 139..<147: return 19
    case 133..<139: return 18
    case 127..<133: return 17
    case 121..<127: return 16
    case 116..<121: return 15
    case 111..<116: return 14
    case 106..<111: return 13
    case 101..<106: return 12
    case 97..<101: return 11
    case 93..<97: return 10
    case 88..<93: return 9
    case 84..<88: return 8
    case 80..<84: return 7
    case 76..<80: return 6
    case 72..<76: return 5
    case 67..<72: return 4
    case 62..<67: return 3
    case 57..<62: return 2
    case 50..<57: return 1
    default: return 0
    }
}

/// Martin equation column index from non-HDL cholesterol (mg/dL), matching the source lookup.
private func martinColumn(_ nonHdl: Double) -> Int {
    switch nonHdl {
    case 220...: return 5
    case 190..<220: return 4
    case 160..<190: return 3
    case 130..<160: return 2
    case 100..<130: return 1
    default: return 0
    }
}

/// GRACE 2.0 piecewise age factor (source ordered logic).
private func graceAgeFactor(_ age: Double) -> Double {
    if age < 35 { return 0 }
    if age < 45 { return (age - 35) * 1.8 }
    if age < 55 { return 18 + ((age - 45) * 1.8) }
    if age < 65 { return 36 + ((age - 55) * 1.8) }
    if age < 75 { return 54 + ((age - 65) * 1.9) }
    if age < 85 { return 73 + ((age - 75) * 1.8) }
    if age < 90 { return 91 + ((age - 85) * 1.8) }
    return 100
}

/// GRACE 2.0 piecewise heart-rate factor (source ordered logic).
private func graceHeartRateFactor(_ hr: Double) -> Double {
    if hr < 70 { return 0 }
    if hr < 80 { return (hr - 70) * 0.3 }
    if hr < 90 { return 3 + ((hr - 80) * 0.2) }
    if hr < 100 { return 5 + ((hr - 90) * 0.3) }
    if hr < 110 { return 8 + ((hr - 100) * 0.2) }
    if hr < 150 { return 10 + ((hr - 110) * 0.3) }
    if hr < 200 { return 22 + ((hr - 150) * 0.3) }
    return 34
}

/// GRACE 2.0 piecewise systolic BP factor (source ordered logic).
private func graceSbpFactor(_ sbp: Double) -> Double {
    if sbp < 80 { return 40 }
    if sbp < 100 { return 40 - ((sbp - 80) * 0.3) }
    if sbp < 110 { return 34 - ((sbp - 100) * 0.3) }
    if sbp < 120 { return 31 - ((sbp - 110) * 0.4) }
    if sbp < 130 { return 27 - ((sbp - 120) * 0.3) }
    if sbp < 140 { return 24 - ((sbp - 130) * 0.3) }
    if sbp < 150 { return 20 - ((sbp - 140) * 0.4) }
    if sbp < 160 { return 17 - ((sbp - 150) * 0.3) }
    if sbp < 180 { return 14 - ((sbp - 160) * 0.3) }
    if sbp < 200 { return 8 - ((sbp - 180) * 0.4) }
    return 0
}

/// GRACE 2.0 piecewise serum creatinine factor (source ordered logic; creatinine in mg/dL).
private func graceCreatinineFactor(_ creat: Double) -> Double {
    if creat < 0.2 { return creat * 5 }
    if creat < 0.4 { return 1 + ((creat - 0.2) * 10) }
    if creat < 0.6 { return 3 + ((creat - 0.4) * 5) }
    if creat < 0.8 { return 4 + ((creat - 0.6) * 10) }
    if creat < 1.0 { return 6 + ((creat - 0.8) * 5) }
    if creat < 1.2 { return 7 + ((creat - 1.0) * 5) }
    if creat < 1.4 { return 8 + ((creat - 1.2) * 10) }
    if creat < 1.6 { return 10 + ((creat - 1.4) * 5) }
    if creat < 1.8 { return 11 + ((creat - 1.6) * 10) }
    if creat < 2.0 { return 13 + ((creat - 1.8) * 5) }
    if creat < 3.0 { return 14 + ((creat - 2.0) * 7) }
    if creat < 4.0 { return 21 + ((creat - 3.0) * 7) }
    return 28
}

/// Calculator specs for the Cardiovascular category.
let cardiovascularCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "CVDinDM1.htm",
        guide: """
        Swedish National Diabetes Register (NDR) model predicting 5-year risk of cardiovascular events in Type 1 diabetes (validated in patients aged 30-65).

        Enter age (years), diabetes duration (years), total cholesterol and HDL (mg/dL), HbA1C (DCCT scale, %), systolic BP (mmHg), and check the status of smoking, macroalbuminuria, and prior CVD.
        """,
        equation: """
        Terms = 0.08426(DMdur−28.014) + 0.04742(Age−DMdur−16.601) + 0.80050(ln(TC/HDL)−1.1470)
                + 1.27275(ln(HbA1c)−2.065) + 1.20050(ln(SBP)−4.8598)
                + 0.56688(Smoker−0.1483) + 0.41995(AlbU−0.1237) + 1.25506(PrevCVD−0.0612)
        CVD5YearRisk = 100 × (1 − 0.97136^e(Terms))
        """,
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 45)")),
            MedCalcInput("dm", "Diabetes Duration", .number(unitHint: "years (e.g. 15)")),
            MedCalcInput("tc", "Total Cholesterol", .number(unitHint: "mg/dL (e.g. 180)")),
            MedCalcInput("hdl", "HDL Cholesterol", .number(unitHint: "mg/dL (e.g. 50)")),
            MedCalcInput("a1c", "HbA1C", .number(unitHint: "% DCCT (e.g. 7.5)")),
            MedCalcInput("sbp", "Systolic Blood Pressure", .number(unitHint: "mmHg (e.g. 130)")),
            MedCalcInput("smoker", "Smoker", .yesNo),
            MedCalcInput("alburia", "Macroalbuminuria", .yesNo),
            MedCalcInput("priorcvd", "Prior CVD", .yesNo)
        ],
        compute: { v in
            guard let age = v.number("age"), let dm = v.number("dm"), let tc = v.number("tc"),
                  let hdl = v.number("hdl"), let a1c = v.number("a1c"), let sbp = v.number("sbp"),
                  let smoker = v.selection("smoker"), let alb = v.selection("alburia"),
                  let cvd = v.selection("priorcvd") else { return "" }
            guard tc > 0, hdl > 0, a1c > 0, sbp > 0, tc > hdl else { return "" }
            let terms = (0.08426 * (dm - 28.014))
                + (0.04742 * (age - dm - 16.601))
                + (0.80050 * (log(tc / hdl) - 1.1470))
                + (1.27275 * (log(a1c) - 2.065))
                + (1.20050 * (log(sbp) - 4.8598))
                + (0.56688 * (Double(smoker) - 0.1483))
                + (0.41995 * (Double(alb) - 0.1237))
                + (1.25506 * (Double(cvd) - 0.0612))
            let risk = 100 * (1 - pow(0.97136, exp(terms)))
            return "5-Year CVD Risk: \(String(format: "%.1f%%", max(risk, 0)))"
        }
    ),

    MedCalcSpec(
        fileName: "AtrialFibCHADSVASc.htm",
        guide: """
        CHA(2)DS(2)-VASc score for stroke risk in atrial fibrillation. Check each criterion that is present, then select the patient's age band and sex.

        The guideline suggests aspirin or no treatment for a score of 0-1, and oral anticoagulation when the score is 2 or greater (individualize based on bleeding risk).
        """,
        equation: "Score = sum of criteria points (C 1, H 1, A2 2, D 1, S 2, V 1, Age 1-2, Sex 1)",
        inputs: [
            MedCalcInput("hf", "Congestive heart failure / LV dysfunction (+1)", .yesNo),
            MedCalcInput("htn", "Hypertension (+1)", .yesNo),
            MedCalcInput("ageband", "Age", .choice(options: ["<65 years (0)", "65-74 years (+1)", "≥75 years (+2)"])),
            MedCalcInput("dm", "Diabetes mellitus (+1)", .yesNo),
            MedCalcInput("stroke", "History of stroke, TIA or thromboembolism (+2)", .yesNo),
            MedCalcInput("vasc", "Vascular disease (MI, PVD or aortic atherosclerosis) (+1)", .yesNo),
            MedCalcInput("sex", "Sex", .choice(options: ["Female (+1)", "Male (0)"]))
        ],
        compute: { v in
            guard let hf = v.selection("hf"), let htn = v.selection("htn"),
                  let ageIdx = v.selection("ageband"), let dm = v.selection("dm"),
                  let stroke = v.selection("stroke"), let vasc = v.selection("vasc"),
                  let sex = v.selection("sex") else { return "" }
            let score = hf + htn + dm + stroke + vasc + sex + [0, 1, 2][ageIdx]
            let annual: String
            switch score {
            case 0: annual = "0 points: 0% per year"
            case 1: annual = "1 point: 1.3% per year"
            case 2: annual = "2 points: 2.2% per year"
            case 3: annual = "3 points: 3.2% per year"
            case 4: annual = "4 points: 4% per year"
            case 5: annual = "5 points: 6.7% per year"
            case 6: annual = "6 points: 9.8% per year"
            case 7: annual = "7 points: 9.6% per year"
            case 8: annual = "8 points: 6.7% per year"
            default: annual = "9+ points: 15.2% per year"
            }
            return "CHA(2)DS(2)-VASc Score: \(String(format: "%.0f", Double(score)))\nAdjusted Stroke Rate: \(annual)"
        }
    ),

    MedCalcSpec(
        fileName: "CardiacOutput.htm",
        guide: """
        Cardiac output from the Fick principle: CO = O2 consumption ÷ arteriovenous O2 content difference. Enter O2 consumption in mL/min (about 250 mL/min in a healthy resting person, or a measured value), hemoglobin in g/dL, arterial and mixed-venous oxygen saturations in %, and the paired PaO2/PvO2 in mmHg.
        """,
        equation: """
        CaO2 = (Hgb × 13.4 × ArterialSat/100) + (PaO2 × 0.031)
        CvO2 = (Hgb × 13.4 × VenousSat/100) + (PvO2 × 0.031)
        CO = O2Consumption ÷ (CaO2 − CvO2)
        """,
        inputs: [
            MedCalcInput("o2", "O2 Consumption", .number(unitHint: "mL/min (e.g. 250)")),
            MedCalcInput("hgb", "Hemoglobin", .number(unitHint: "g/dL (e.g. 14)")),
            MedCalcInput("asat", "Arterial O2 Saturation", .number(unitHint: "% (e.g. 97)")),
            MedCalcInput("pao2", "PaO2", .number(unitHint: "mmHg (e.g. 95)")),
            MedCalcInput("vsat", "Venous O2 Saturation", .number(unitHint: "% (e.g. 75)")),
            MedCalcInput("pvo2", "PvO2", .number(unitHint: "mmHg (e.g. 40)"))
        ],
        compute: { v in
            guard let o2 = v.number("o2"), let hgb = v.number("hgb"),
                  let asat = v.number("asat"), let pao2 = v.number("pao2"),
                  let vsat = v.number("vsat"), let pvo2 = v.number("pvo2") else { return "" }
            let caO2 = (hgb * 13.4 * asat / 100) + (pao2 * 0.031)
            let cvO2 = (hgb * 13.4 * vsat / 100) + (pvo2 * 0.031)
            let diff = caO2 - cvO2
            guard diff > 0 else { return "" }
            let co = (o2 / 10) / diff
            return """
            Arterial O2 Content: \(String(format: "%.1f mL/dL", caO2))
            Venous O2 Content: \(String(format: "%.1f mL/dL", cvO2))
            Cardiac Output: \(String(format: "%.1f L/min", co))
            """
        }
    ),

    MedCalcSpec(
        fileName: "CardiacOutput_MC.htm",
        guide: """
        Cardiac output, cardiac index, stroke volume, and stroke index from the Fick principle. Enter O2 consumption (mL/min, about 250 at rest), arterial and venous O2 content (mL/dL from blood gas and saturation calculations), heart rate (beats/min), height (cm), and weight (kg).
        """,
        equation: """
        CO = O2Consumption ÷ (ArterialO2Content − VenousO2Content)
        BSA = 0.007184 × Height^0.725 × Weight^0.425
        CI = CO ÷ BSA  •  SV = 1000 × CO ÷ HR  •  SI = SV ÷ BSA
        """,
        inputs: [
            MedCalcInput("o2", "O2 Consumption", .number(unitHint: "mL/min (e.g. 250)")),
            MedCalcInput("ao2", "Arterial O2 Content", .number(unitHint: "mL/dL (e.g. 20)")),
            MedCalcInput("vo2", "Venous O2 Content", .number(unitHint: "mL/dL (e.g. 14)")),
            MedCalcInput("hr", "Heart Rate", .number(unitHint: "beats/min (e.g. 75)")),
            MedCalcInput("hgt", "Height", .number(unitHint: "cm (e.g. 170)")),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 70)"))
        ],
        compute: { v in
            guard let o2 = v.number("o2"), let ao2 = v.number("ao2"), let vo2 = v.number("vo2"),
                  let hr = v.number("hr"), let hgt = v.number("hgt"), let wgt = v.number("wgt") else { return "" }
            let diff = ao2 - vo2
            guard diff > 0, hr > 0, hgt > 0, wgt > 0 else { return "" }
            let co = (o2 / 10) / diff
            let bsa = 0.007184 * pow(hgt, 0.725) * pow(wgt, 0.425)
            let ci = co / bsa
            let sv = 1000 * co / hr
            let si = sv / bsa
            return """
            Cardiac Output: \(String(format: "%.1f L/min", co))
            BSA: \(String(format: "%.2f m²", bsa))
            Cardiac Index: \(String(format: "%.2f L/min/m²", ci))
            Stroke Volume: \(String(format: "%.0f mL", sv))
            Stroke Index: \(String(format: "%.1f mL/m²", si))
            """
        }
    ),

    MedCalcSpec(
        fileName: "CVRiskRevised2018.htm",
        guide: """
        2018 Revised Pooled Cohort Equations (PCEs) for 10-year atherosclerotic cardiovascular disease risk (ASCVD risk estimator). Valid for adults aged 20-79 without established ASCVD or CKD.

        Select race and sex, enter age (years), total and HDL cholesterol (mg/dL), systolic BP (mmHg), and check whether the patient is on antihypertensive medication, has diabetes, or is a current smoker.
        """,
        equation: """
        10-year risk = 100 ÷ (1 + e^(−Logit))
        (sex-specific logistic regression on Age, Race, SBP, HTN meds, Diabetes, Smoking, TC/HDL)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("race", "Race", .choice(options: ["American Indian or Alaska Native", "Asian", "Black or African American", "Native Hawaiian or Other Pacific Islander", "White"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (20-79, e.g. 55)")),
            MedCalcInput("tc", "Total Cholesterol", .number(unitHint: "mg/dL (e.g. 200)")),
            MedCalcInput("hdl", "HDL Cholesterol", .number(unitHint: "mg/dL (e.g. 50)")),
            MedCalcInput("sbp", "Systolic Blood Pressure", .number(unitHint: "mmHg (e.g. 125)")),
            MedCalcInput("htnmed", "On Hypertension Medication", .yesNo),
            MedCalcInput("dm", "Diabetes", .yesNo),
            MedCalcInput("smoker", "Current Smoker", .yesNo)
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let raceIdx = v.selection("race"),
                  let age = v.number("age"), let tc = v.number("tc"), let hdl = v.number("hdl"),
                  let sbp = v.number("sbp"), let htn = v.selection("htnmed"),
                  let dm = v.selection("dm"), let smoker = v.selection("smoker") else { return "" }
            guard age >= 20, age <= 79, hdl > 0 else { return "" }
            let race = raceIdx == 2 ? 1.0 : 0.0
            let cholHdl = tc / hdl
            let sbp2 = sbp * sbp
            let logit = sexIdx == 0
                ? (-12.823110 + (0.106501 * age) + (0.432440 * race) + (0.000056 * sbp2)
                    + (0.017666 * sbp) + (0.731678 * Double(htn)) + (0.943970 * Double(dm))
                    + (1.009790 * Double(smoker)) + (0.151318 * cholHdl)
                    + (-0.008580 * age * race) + (-0.003647 * sbp * Double(htn))
                    + (0.006208 * sbp * race) + (0.152968 * race * Double(htn))
                    + (-0.000153 * age * sbp) + (0.115232 * race * Double(dm))
                    + (-0.092231 * race * Double(smoker)) + (0.070498 * race * cholHdl)
                    + (-0.000173 * race * sbp * Double(htn)) + (-0.000094 * age * sbp * race))
                : (-11.679980 + (0.064200 * age) + (0.482835 * race) + (-0.000061 * sbp2)
                    + (0.038950 * sbp) + (2.055533 * Double(htn)) + (0.842209 * Double(dm))
                    + (0.895589 * Double(smoker)) + (0.193307 * cholHdl)
                    + (-0.014207 * sbp * Double(htn)) + (0.011609 * sbp * race)
                    + (-0.119460 * Double(htn) * race) + (0.000025 * age * sbp)
                    + (-0.077214 * race * Double(dm)) + (-0.226771 * race * Double(smoker))
                    + (-0.117749 * race * cholHdl) + (0.004190 * race * Double(htn) * sbp)
                    + (-0.000199 * race * age * sbp))
            let risk = 100 / (1 + exp(-logit))
            let category = risk < 5 ? "Low risk (<5%)"
                : risk < 7.5 ? "Borderline (5-7.5%)"
                : risk < 20 ? "Intermediate (7.5-20%)"
                : "High risk (≥20%)"
            return "10-Year ASCVD Risk: \(String(format: "%.1f%%", risk)) — \(category)"
        }
    ),

    MedCalcSpec(
        fileName: "DVTScoreWells.htm",
        guide: """
        Wells score for the pretest probability of deep vein thrombosis. Check each clinical finding present in the patient; an alternative diagnosis more likely than DVT subtracts 2 points.

        Interpretation: 3-8 points = high probability; 1-2 points = moderate; -2 to 0 = low.
        """,
        equation: "Score = sum of findings (each +1, alternative diagnosis −2)",
        inputs: [
            MedCalcInput("paralysis", "Paralysis, paresis or recent orthopedic casting of lower extremity (+1)", .yesNo),
            MedCalcInput("bedridden", "Recently bedridden (>3 days) or major surgery within past 4 weeks (+1)", .yesNo),
            MedCalcInput("tenderness", "Localized tenderness in deep vein system (+1)", .yesNo),
            MedCalcInput("swelling", "Swelling of entire leg (+1)", .yesNo),
            MedCalcInput("calf", "Calf swelling 3 cm greater than other leg (+1)", .yesNo),
            MedCalcInput("pitting", "Pitting edema greater in the symptomatic leg (+1)", .yesNo),
            MedCalcInput("collateral", "Collateral non-varicose superficial veins (+1)", .yesNo),
            MedCalcInput("cancer", "Active cancer or cancer treated within 6 months (+1)", .yesNo),
            MedCalcInput("alt", "Alternative diagnosis more likely than DVT (−2)", .yesNo)
        ],
        compute: { v in
            guard let paralysis = v.selection("paralysis"), let bed = v.selection("bedridden"),
                  let tend = v.selection("tenderness"), let swelling = v.selection("swelling"),
                  let calf = v.selection("calf"), let pitting = v.selection("pitting"),
                  let collat = v.selection("collateral"), let cancer = v.selection("cancer"),
                  let alt = v.selection("alt") else { return "" }
            let score = Double(paralysis + bed + tend + swelling + calf + pitting + collat + cancer - 2 * alt)
            let interp = score >= 3 ? "High probability of DVT"
                : score >= 1 ? "Moderate probability"
                : "Low probability"
            return "Wells DVT Score: \(String(format: "%.0f", score)) — \(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "EuroSCOREAdd.htm",
        guide: """
        Additive EuroSCORE for operative mortality risk in adult cardiac surgery. Select age band, sex, and ejection fraction category, then check each applicable condition.

        Interpretation: 0-2 points = low risk; 3-5 = intermediate; 6-45 = high.
        """,
        equation: "Score = age points + sex (1) + EF points + sum of condition points",
        inputs: [
            MedCalcInput("age", "Age", .choice(options: ["<60 (0)", "60-64 (1)", "65-69 (2)", "70-74 (3)", "75-79 (4)", "80-84 (5)", "85-89 (6)", "90-94 (7)", "95-100 (8)"])),
            MedCalcInput("sex", "Sex", .choice(options: ["Female (+1)", "Male (0)"])),
            MedCalcInput("ef", "Ejection Fraction", .choice(options: ["≥30% (0)", "30-50% (+1)", "<30% (+3)"])),
            MedCalcInput("renal", "Renal dysfunction (+2)", .yesNo),
            MedCalcInput("pvd", "Peripheral vascular disease (+2)", .yesNo),
            MedCalcInput("resp", "Respiratory disease (+1)", .yesNo),
            MedCalcInput("cva", "Cerebrovascular disease (+2)", .yesNo),
            MedCalcInput("prevcx", "Previous cardiac surgery (+3)", .yesNo),
            MedCalcInput("endo", "Active endocarditis (+3)", .yesNo),
            MedCalcInput("critical", "Critical preoperative state (+3)", .yesNo),
            MedCalcInput("ua", "Unstable angina (+2)", .yesNo),
            MedCalcInput("mirecent", "Recent myocardial infarction (+2)", .yesNo),
            MedCalcInput("pah", "Pulmonary hypertension (+2)", .yesNo),
            MedCalcInput("emerg", "Emergency surgery (+2)", .yesNo),
            MedCalcInput("noncabg", "Other than isolated CABG (+2)", .yesNo),
            MedCalcInput("vsd", "Ventricular septal rupture (+4)", .yesNo),
            MedCalcInput("aorta", "Thoracic aortic surgery (+3)", .yesNo)
        ],
        compute: { v in
            guard let age = v.selection("age"), let sex = v.selection("sex"), let ef = v.selection("ef"),
                  let renal = v.selection("renal"), let pvd = v.selection("pvd"),
                  let resp = v.selection("resp"), let cva = v.selection("cva"),
                  let prev = v.selection("prevcx"), let endo = v.selection("endo"),
                  let crit = v.selection("critical"), let ua = v.selection("ua"),
                  let mi = v.selection("mirecent"), let pah = v.selection("pah"),
                  let emerg = v.selection("emerg"), let noncabg = v.selection("noncabg"),
                  let vsd = v.selection("vsd"), let aorta = v.selection("aorta") else { return "" }
            let score = age + sex + [0, 1, 3][ef]
                + renal + pvd + resp + cva + prev + endo + crit + ua + mi + pah + emerg + noncabg + vsd + aorta
            let interp = score <= 2 ? "Low risk" : score <= 5 ? "Intermediate risk" : "High risk"
            return "EuroSCORE: \(String(format: "%.0f", Double(score))) points — \(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "Friedewald_SI.htm",
        guide: """
        Friedewald equation estimates LDL cholesterol from the standard lipid panel, SI units (mmol/L). Enter total cholesterol, HDL cholesterol, and triglycerides in mmol/L.

        ⚠️ Not valid when triglycerides are ≥ 4.5 mmol/L; measure LDL directly in that setting.
        """,
        equation: "LDL = TotalChol − (Triglyceride ÷ 2.2) − HDL",
        inputs: [
            MedCalcInput("tc", "Total Cholesterol", .number(unitHint: "mmol/L (e.g. 5.2)")),
            MedCalcInput("hdl", "HDL Cholesterol", .number(unitHint: "mmol/L (e.g. 1.3)")),
            MedCalcInput("tg", "Triglycerides", .number(unitHint: "mmol/L (e.g. 1.2)"))
        ],
        compute: { v in
            guard let tc = v.number("tc"), let hdl = v.number("hdl"), let tg = v.number("tg") else { return "" }
            let ldl = tc - (tg / 2.2) - hdl
            if tg >= 4.5 {
                return "⚠️ Triglycerides ≥ 4.5 mmol/L — Friedewald estimate is invalid; LDL should be measured directly."
            }
            return "Estimated LDL: \(String(format: "%.2f mmol/L", ldl))"
        }
    ),

    MedCalcSpec(
        fileName: "Friedewald.htm",
        guide: """
        Friedewald equation estimates LDL cholesterol from the standard lipid panel, US units (mg/dL). Enter total cholesterol, HDL cholesterol, and triglycerides in mg/dL.

        ⚠️ Not valid when triglycerides are ≥ 400 mg/dL; measure LDL directly in that setting.
        """,
        equation: "LDL = TotalChol − (Triglyceride ÷ 5) − HDL",
        inputs: [
            MedCalcInput("tc", "Total Cholesterol", .number(unitHint: "mg/dL (e.g. 200)")),
            MedCalcInput("hdl", "HDL Cholesterol", .number(unitHint: "mg/dL (e.g. 50)")),
            MedCalcInput("tg", "Triglycerides", .number(unitHint: "mg/dL (e.g. 100)"))
        ],
        compute: { v in
            guard let tc = v.number("tc"), let hdl = v.number("hdl"), let tg = v.number("tg") else { return "" }
            if tg >= 400 {
                return "⚠️ Triglycerides ≥ 400 mg/dL — Friedewald estimate is invalid; LDL should be measured directly."
            }
            let ldl = tc - (tg / 5) - hdl
            return "Estimated LDL: \(String(format: "%.0f mg/dL", ldl))"
        }
    ),

    MedCalcSpec(
        fileName: "GRACE2Score.htm",
        guide: """
        GRACE 2.0 (non-linear 2014) score for prognosis in acute coronary syndrome. Enter age (years), heart rate (beats/min), systolic BP (mmHg), and serum creatinine (mg/dL); select Killip class and check the three binary findings.

        Interpretation is 6-month mortality from admission: 0-75 pts ≈ 0.2-1.8%; 76-128 ≈ 2-10%; 129-140 ≈ 11-15%; 141-149 ≈ 16-20%; 150-173 ≈ 21-30%; 174-199 ≈ 40-60%; 200-218 ≈ 70-80%; 219-306 ≈ 90-99%.
        """,
        equation: """
        GRACE = round(AgeFactor + HR Factor + SBP Factor + CreatinineFactor
        + Killip + Arrest(30) + Enzymes(13) + ST-deviation(17))
        """,
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 65)")),
            MedCalcInput("hr", "Heart Rate", .number(unitHint: "beats/min (e.g. 85)")),
            MedCalcInput("sbp", "Systolic BP", .number(unitHint: "mmHg (e.g. 110)")),
            MedCalcInput("creat", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.2)")),
            MedCalcInput("killip", "Killip Class", .choice(options: ["Class 1: no heart failure findings (0)", "Class 2: pulmonary rales (15)", "Class 3: pulmonary edema (29)", "Class 4: cardiogenic shock (44)"])),
            MedCalcInput("arrest", "Cardiac arrest at presentation", .choice(options: ["No (0)", "Yes (30)"])),
            MedCalcInput("enzymes", "Elevated cardiac enzymes", .choice(options: ["No (0)", "Yes (13)"])),
            MedCalcInput("stdev", "ST-segment deviation", .choice(options: ["No (0)", "Yes (17)"]))
        ],
        compute: { v in
            guard let age = v.number("age"), let hr = v.number("hr"), let sbp = v.number("sbp"),
                  let creat = v.number("creat"), let killip = v.selection("killip"),
                  let arrest = v.selection("arrest"), let enz = v.selection("enzymes"),
                  let st = v.selection("stdev") else { return "" }
            let killipPts = [0.0, 15, 29, 44][killip]
            let arrestPts = arrest == 1 ? 30.0 : 0
            let enzPts = enz == 1 ? 13.0 : 0
            let stPts = st == 1 ? 17.0 : 0
            let score = (graceAgeFactor(age) + graceHeartRateFactor(hr)
                + graceSbpFactor(sbp) + graceCreatinineFactor(creat)
                + killipPts + arrestPts + enzPts + stPts).rounded()
            let mortality: String
            if score <= 75 { mortality = "0-75 points: 0.2-1.8% 6-month mortality" }
            else if score <= 128 { mortality = "76-128 points: 2-10% 6-month mortality" }
            else if score <= 140 { mortality = "129-140 points: 11-15% 6-month mortality" }
            else if score <= 149 { mortality = "141-149 points: 16-20% 6-month mortality" }
            else if score <= 173 { mortality = "150-173 points: 21-30% 6-month mortality" }
            else if score <= 199 { mortality = "174-199 points: 40-60% 6-month mortality" }
            else if score <= 218 { mortality = "200-218 points: 70-80% 6-month mortality" }
            else { mortality = "219+ points: 90-99% 6-month mortality" }
            return "GRACE 2.0 Score: \(String(format: "%.0f", score))\n\(mortality)"
        }
    ),

    MedCalcSpec(
        fileName: "HASBLED.htm",
        guide: """
        HAS-BLED score estimates bleeding risk in atrial fibrillation patients (mostly on anticoagulation). Check each criterion present.

        Interpretation: 0 = 1.13 bleeds/100 patient-years; 1 = 1.02; 2 = 1.88; 3 = 3.74; 4 = 8.70; 5-9 = high risk. A score ≥ 3 flags high bleeding risk and should prompt modification of modifiable risk factors (it is not a reason to withhold anticoagulation).
        """,
        equation: "Score = sum of HAS-BLED letters (each 1 point, max 9)",
        inputs: [
            MedCalcInput("h", "Hypertension (+1)", .yesNo),
            MedCalcInput("aL", "Abnormal liver function (+1)", .yesNo),
            MedCalcInput("aR", "Abnormal renal function (+1)", .yesNo),
            MedCalcInput("s", "Stroke (+1)", .yesNo),
            MedCalcInput("b", "Bleeding tendency or history (+1)", .yesNo),
            MedCalcInput("l", "Labile INRs (+1)", .yesNo),
            MedCalcInput("e", "Elderly, age > 65 (+1)", .yesNo),
            MedCalcInput("dD", "Drugs: antiplatelet agents or NSAIDs (+1)", .yesNo),
            MedCalcInput("dA", "Alcohol abuse (+1)", .yesNo)
        ],
        compute: { v in
            guard let h = v.selection("h"), let aL = v.selection("aL"), let aR = v.selection("aR"),
                  let s = v.selection("s"), let b = v.selection("b"), let l = v.selection("l"),
                  let e = v.selection("e"), let dD = v.selection("dD"), let dA = v.selection("dA")
            else { return "" }
            let score = h + aL + aR + s + b + l + e + dD + dA
            let interp: String
            switch score {
            case 0: interp = "1.13 bleeds per 100 patient-years"
            case 1: interp = "1.02 bleeds per 100 patient-years"
            case 2: interp = "1.88 bleeds per 100 patient-years"
            case 3: interp = "3.74 bleeds per 100 patient-years"
            case 4: interp = "8.70 bleeds per 100 patient-years"
            default: interp = "High risk (insufficient data above 4)"
            }
            return "HAS-BLED Score: \(String(format: "%.0f", Double(score)))\n\(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "MICriteriaLBBB.htm",
        guide: """
        Sgarbossa criteria for diagnosing acute MI in patients with left bundle branch block. Check each ECG finding present on the 12-lead EKG.

        Interpretation (probability of MI): 10 pts = 100%; 8 = 92%; 7 = 93%; 5 = 88%; 3 = 66%; 2 = 50%; 0 = 16%. A score ≥ 3 has high specificity for acute MI.
        """,
        equation: "Score = concordant ST elevation (5) + ST depression V1-V3 (3) + discordant ST elevation ≥5 mm (2)",
        inputs: [
            MedCalcInput("concordant", "ST elevation ≥1 mm concordant with QRS axis (+5)", .yesNo),
            MedCalcInput("dep", "ST depression ≥1 mm in V1, V2 or V3 (+3)", .yesNo),
            MedCalcInput("discordant", "ST elevation ≥5 mm discordant with QRS axis (+2)", .yesNo)
        ],
        compute: { v in
            guard let c = v.selection("concordant"), let d = v.selection("dep"), let x = v.selection("discordant") else { return "" }
            let score = 5 * c + 3 * d + 2 * x
            let prob: String
            switch score {
            case 10: prob = "100% probability of MI"
            case 8: prob = "92% probability of MI"
            case 7: prob = "93% probability of MI"
            case 5: prob = "88% probability of MI"
            case 3: prob = "66% probability of MI"
            case 2: prob = "50% probability of MI"
            default: prob = "16% probability of MI"
            }
            return "Sgarbossa Score: \(String(format: "%.0f", Double(score))) — \(prob)"
        }
    ),

    MedCalcSpec(
        fileName: "MartinLDL.htm",
        guide: """
        Martin equation estimates LDL cholesterol using a "Novel Factor" (triglyceride-to-VLDL-cholesterol ratio) that varies with triglyceride and non-HDL levels, improving accuracy across a wide range of triglycerides (including ≥ 400 mg/dL, where Friedewald fails).

        Enter total cholesterol, HDL cholesterol, and triglycerides in mg/dL.
        """,
        equation: """
        Non-HDL Cholesterol = Total − HDL
        LDL = Non-HDL − (Triglycerides ÷ Novel Factor)
        (Novel Factor from the published TG/non-HDL table)
        """,
        inputs: [
            MedCalcInput("tc", "Total Cholesterol", .number(unitHint: "mg/dL (e.g. 200)")),
            MedCalcInput("hdl", "HDL Cholesterol", .number(unitHint: "mg/dL (e.g. 45)")),
            MedCalcInput("tg", "Triglycerides", .number(unitHint: "mg/dL (e.g. 150)"))
        ],
        compute: { v in
            guard let tc = v.number("tc"), let hdl = v.number("hdl"), let tg = v.number("tg") else { return "" }
            let nonHdl = tc - hdl
            guard nonHdl > 0, tg >= 0 else { return "" }
            let factor = martinNovelFactors[martinRow(tg)][martinColumn(nonHdl)]
            let ldl = nonHdl - (tg / factor)
            return """
            Non-HDL Cholesterol: \(String(format: "%.0f mg/dL", nonHdl))
            Novel Factor: \(String(format: "%.1f", factor))
            Estimated LDL: \(String(format: "%.0f mg/dL", ldl))
            """
        }
    ),

    MedCalcSpec(
        fileName: "MeanVascPres.htm",
        guide: """
        Mean arterial pressure (MAP) from systolic and diastolic readings. Enter both in the same units (mmHg).

        MAP ≈ diastolic BP + one-third of the pulse pressure (diastole occupies about two-thirds of the cardiac cycle). Typical systemic reference: 70-105 mmHg.
        """,
        equation: "MAP = DiastolicBP + ((SystolicBP − DiastolicBP) ÷ 3)",
        inputs: [
            MedCalcInput("sbp", "Systolic BP", .number(unitHint: "mmHg (e.g. 120)")),
            MedCalcInput("dbp", "Diastolic BP", .number(unitHint: "mmHg (e.g. 80)"))
        ],
        compute: { v in
            guard let sbp = v.number("sbp"), let dbp = v.number("dbp") else { return "" }
            let map = dbp + ((sbp - dbp) / 3)
            return "Mean Arterial Pressure: \(String(format: "%.0f mmHg", map))"
        }
    ),

    MedCalcSpec(
        fileName: "PulmonaryEmbRisk.htm",
        guide: """
        Wells score for pulmonary embolism. Check each criterion present.

        Interpretation: > 6 = high probability; 2-6 = moderate; < 2 = low. Also, a score ≤ 4 with a negative D-dimer makes PE unlikely.
        """,
        equation: "Score = DVT symptoms (3) + no better alternative dx (3) + tachycardia (1.5) + immobilization/surgery (1.5) + prior DVT/PE (1.5) + hemoptysis (1) + malignancy (1)",
        inputs: [
            MedCalcInput("dvt", "Symptoms of DVT (+3)", .yesNo),
            MedCalcInput("alt", "No alternative diagnosis better explains the illness (+3)", .yesNo),
            MedCalcInput("tachy", "Tachycardia with pulse > 100 (+1.5)", .yesNo),
            MedCalcInput("immob", "Immobilization (≥3 days) or surgery in the previous 4 weeks (+1.5)", .yesNo),
            MedCalcInput("prior", "Prior history of DVT or PE (+1.5)", .yesNo),
            MedCalcInput("hemo", "Presence of hemoptysis (+1)", .yesNo),
            MedCalcInput("malig", "Presence of malignancy (+1)", .yesNo)
        ],
        compute: { v in
            guard let dvt = v.selection("dvt"), let alt = v.selection("alt"), let tachy = v.selection("tachy"),
                  let immob = v.selection("immob"), let prior = v.selection("prior"),
                  let hemo = v.selection("hemo"), let malig = v.selection("malig") else { return "" }
            let score = 3.0 * Double(dvt) + 3.0 * Double(alt)
                + 1.5 * Double(tachy) + 1.5 * Double(immob) + 1.5 * Double(prior)
                + Double(hemo) + Double(malig)
            let interp = score > 6 ? "High probability" : score >= 2 ? "Moderate probability" : "Low probability"
            return "Wells PE Score: \(String(format: "%.1f", score)) — \(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "qtintervalcorrection.htm",
        guide: """
        Bazett correction of the QT interval for heart rate. Enter the QT interval in milliseconds and the heart rate in beats per minute.

        QTc ≥ 440 ms in men or ≥ 460 ms in women is prolonged; a QTc increase ≥ 60 ms or a prolonged QTc may be associated with drug-induced QT prolongation.
        """,
        equation: "QTc = QT ÷ √RR, where RR (min) = 60 ÷ HeartRate",
        inputs: [
            MedCalcInput("qt", "QT Interval", .number(unitHint: "ms (e.g. 380)")),
            MedCalcInput("hr", "Heart Rate", .number(unitHint: "beats/min (e.g. 75)"))
        ],
        compute: { v in
            guard let qt = v.number("qt"), let hr = v.number("hr"), hr > 0 else { return "" }
            let rr = 60.0 / hr
            let qtc = qt / sqrt(rr)
            return """
            RR Interval: \(String(format: "%.2f min", rr))
            QTc (Bazett): \(String(format: "%.0f ms", qtc))
            """
        }
    ),

    MedCalcSpec(
        fileName: "revisedgenevascore.htm",
        guide: """
        Revised Geneva score estimates the clinical probability of pulmonary embolism in adults. Check each risk factor, symptom, and sign present; select the heart-rate category.

        Interpretation: 0-3 points = low probability; 4-10 = intermediate; 11-22 = high.
        """,
        equation: """
        Score = age >65 (1) + prior DVT/PE (3) + surgery/leg fracture (2) + active cancer (2)
        + unilateral leg pain (3) + hemoptysis (2) + HR points (0/3/5) + leg tenderness/edema (4)
        """,
        inputs: [
            MedCalcInput("age", "Age >65 years (+1)", .yesNo),
            MedCalcInput("prior", "Previous DVT or PE (+3)", .yesNo),
            MedCalcInput("surg", "Surgery or lower limb fracture within 1 month (+2)", .yesNo),
            MedCalcInput("cancer", "Active malignant disease (+2)", .yesNo),
            MedCalcInput("legpain", "Unilateral lower limb pain (+3)", .yesNo),
            MedCalcInput("hemo", "Hemoptysis (+2)", .yesNo),
            MedCalcInput("hr", "Heart Rate", .choice(options: ["<75 beats/min (0)", "75 to 94 beats/min (+3)", "≥95 beats/min (+5)"])),
            MedCalcInput("tenderness", "Tenderness of deep venous structure with unilateral edema (+4)", .yesNo)
        ],
        compute: { v in
            guard let age = v.selection("age"), let prior = v.selection("prior"),
                  let surg = v.selection("surg"), let cancer = v.selection("cancer"),
                  let leg = v.selection("legpain"), let hemo = v.selection("hemo"),
                  let hr = v.selection("hr"), let tend = v.selection("tenderness") else { return "" }
            let score = age + prior + surg + cancer + leg + hemo + tend + [0, 3, 5][hr]
            let interp = score <= 3 ? "Low" : score <= 10 ? "Intermediate" : "High"
            return "Revised Geneva Score: \(String(format: "%.0f", Double(score))) — \(interp) probability of PE"
        }
    ),

    MedCalcSpec(
        fileName: "RomhiltEstes.htm",
        guide: """
        Romhilt-Estes modified criteria for ECG diagnosis of left ventricular hypertrophy. Check each ECG finding present and select the ST-T category.

        Interpretation: 5-13 points = LVH present; 4 = LVH likely; 0-3 = LVH unlikely.
        """,
        equation: """
        Score = amplitude criteria (3) + LA involvement (3) + left axis deviation (2)
        + QRS ≥ 0.09 s (1) + intrinsicoid ≥ 0.05 s (1) + ST-T changes (3, or 1 with digitalis)
        """,
        inputs: [
            MedCalcInput("amp", "Limb-lead R/S ≥ 20 mm, or S in V1/V2 ≥ 30 mm, or R in V5/V6 ≥ 30 mm (+3)", .yesNo),
            MedCalcInput("la", "Left atrial involvement: terminal P-wave deflection in V1 ≥ 1 box wide and deep (+3)", .yesNo),
            MedCalcInput("lad", "Left axis deviation: QRS axis ≤ −30° (+2)", .yesNo),
            MedCalcInput("qrs", "QRS duration ≥ 0.09 second (+1)", .yesNo),
            MedCalcInput("intr", "Intrinsicoid deflection in V5/V6 ≥ 0.05 second (+1)", .yesNo),
            MedCalcInput("stt", "ST-T segment changes ('LV strain')", .choice(options: ["None (0)", "Present, without digitalis (+3)", "Present, with digitalis (+1)"]))
        ],
        compute: { v in
            guard let amp = v.selection("amp"), let la = v.selection("la"), let lad = v.selection("lad"),
                  let qrs = v.selection("qrs"), let intr = v.selection("intr"),
                  let stt = v.selection("stt") else { return "" }
            let score = 3 * amp + 3 * la + 2 * lad + qrs + intr + [0, 3, 1][stt]
            let interp = score >= 5 ? "LVH present" : score == 4 ? "LVH likely" : "LVH unlikely"
            return "Romhilt-Estes Score: \(String(format: "%.0f", Double(score))) — \(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "TIMI_STEMI.htm",
        guide: """
        TIMI risk score for 30-day mortality after ST-elevation myocardial infarction (fibrinolytic-eligible patients). Check each criterion present and select the age band.
        """,
        equation: "Score = sum of criteria (max 14), mapped to 30-day mortality",
        inputs: [
            MedCalcInput("dm", "DM, history of HTN, or history of angina (+1)", .yesNo),
            MedCalcInput("sbp", "Systolic blood pressure < 100 mmHg (+3)", .yesNo),
            MedCalcInput("hr", "Heart rate > 100 bpm (+2)", .yesNo),
            MedCalcInput("killip", "Killip class II-IV (+2)", .yesNo),
            MedCalcInput("wgt", "Body weight < 150 lb (67 kg) (+1)", .yesNo),
            MedCalcInput("ant", "Anterior lead ST elevation or left BBB (+1)", .yesNo),
            MedCalcInput("time", "Time to treat > 4 hours (+1)", .yesNo),
            MedCalcInput("age", "Age", .choice(options: ["<65 years (0)", "65-74 years (+2)", "≥75 years (+3)"]))
        ],
        compute: { v in
            guard let dm = v.selection("dm"), let sbp = v.selection("sbp"), let hr = v.selection("hr"),
                  let killip = v.selection("killip"), let wgt = v.selection("wgt"),
                  let ant = v.selection("ant"), let time = v.selection("time"),
                  let ageIdx = v.selection("age") else { return "" }
            let score = dm + 3 * sbp + 2 * hr + 2 * killip + wgt + ant + time + [0, 2, 3][ageIdx]
            let mortality: String
            switch score {
            case 0: mortality = "0 points: 0.8%"
            case 1: mortality = "1 point: 1.6%"
            case 2: mortality = "2 points: 2.2%"
            case 3: mortality = "3 points: 4.4%"
            case 4: mortality = "4 points: 7.3%"
            case 5: mortality = "5 points: 12%"
            case 6: mortality = "6 points: 16%"
            case 7: mortality = "7 points: 23%"
            case 8: mortality = "8 points: 27%"
            default: mortality = "9+ points: 36%"
            }
            return "TIMI STEMI Score: \(String(format: "%.0f", Double(score)))\nPredicted 30-Day Mortality: \(mortality)"
        }
    ),

    MedCalcSpec(
        fileName: "TIMI_UA_NSTEMI.htm",
        guide: """
        TIMI risk score for unstable angina / NSTEMI (ischemic pain at rest within the past 24 hours with ST deviation or positive markers). Check each criterion present.

        The table shows 2-week death/MI risk and death/MI/urgent revascularization risk. CAD risk factors: hypertension, family history of CAD, elevated cholesterol, diabetes, smoking.
        """,
        equation: "Score = sum of 7 criteria (each 1 point), mapped to 2-week outcomes",
        inputs: [
            MedCalcInput("age", "Age ≥65 (+1)", .yesNo),
            MedCalcInput("riskf", "3 or more CAD risk factors (+1)", .yesNo),
            MedCalcInput("cad", "Known CAD with >50% stenosis (+1)", .yesNo),
            MedCalcInput("asa", "Aspirin use in the past 7 days (+1)", .yesNo),
            MedCalcInput("angina", "Severe angina (≥2 episodes in 24 h) (+1)", .yesNo),
            MedCalcInput("markers", "Elevated cardiac markers (+1)", .yesNo),
            MedCalcInput("st", "ST deviation > 0.5 mm (+1)", .yesNo)
        ],
        compute: { v in
            guard let age = v.selection("age"), let riskf = v.selection("riskf"), let cad = v.selection("cad"),
                  let asa = v.selection("asa"), let angina = v.selection("angina"),
                  let markers = v.selection("markers"), let st = v.selection("st") else { return "" }
            let score = age + riskf + cad + asa + angina + markers + st
            let risk: String
            switch score {
            case 0...1: risk = "0-1 points: 3% death/MI, 5% death/MI/urgent revascularization"
            case 2: risk = "2 points: 3% death/MI, 8% death/MI/urgent revascularization"
            case 3: risk = "3 points: 5% death/MI, 13% death/MI/urgent revascularization"
            case 4: risk = "4 points: 7% death/MI, 20% death/MI/urgent revascularization"
            case 5: risk = "5 points: 12% death/MI, 26% death/MI/urgent revascularization"
            default: risk = "6-7 points: 19% death/MI, 41% death/MI/urgent revascularization"
            }
            return "TIMI Score: \(String(format: "%.0f", Double(score)))\n2-Week Risk: \(risk)"
        }
    ),

    MedCalcSpec(
        fileName: "VeryLowDensityLipoprotein.htm",
        guide: """
        Friedewald-based estimate of VLDL cholesterol from triglycerides. Enter triglycerides in mg/dL.

        This approximation assumes a normal VLDL particle composition; it is less reliable in insulin resistance, cholestasis, or nephrotic syndrome.
        """,
        equation: "VLDL = Triglycerides ÷ 5",
        inputs: [
            MedCalcInput("tg", "Triglycerides", .number(unitHint: "mg/dL (e.g. 120)"))
        ],
        compute: { v in
            guard let tg = v.number("tg") else { return "" }
            return "Estimated VLDL: \(String(format: "%.0f mg/dL", tg / 5))"
        }
    )
]
