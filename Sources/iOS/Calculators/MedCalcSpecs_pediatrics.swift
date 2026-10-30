import Foundation

/// Calculator specs for the Pediatrics category.
/// Sources: BloodPressurePercent{Boys,Girls,2017}.htm, CDCWeightFor{Age,Height}{Boys,Girls}.htm,
/// PediatricETTubeSize.htm, HeightPotential.htm, MaintenanceFluidChildren.htm,
/// WHOInfant{HeadCirc,Length,Weight}ForAge.htm, WHOInfantWeightForLength.htm
///
/// Growth tables live in MedCalcData_Pediatrics.swift; percentile = normal CDF of the LMS z-score.

// MARK: - Shared helpers for the pre-2017 (Fourth Report) BP percentiles

/// Regression model for mean systolic/diastolic BP from age and height-for-age z-score.
private struct BPFourthReportModel {
    let height: [MedCalcPedsData.LMS]
    /// Coefficients [const, age, age², age³, age⁴, hz, hz², hz³, hz⁴] for the mean-BP polynomials.
    let sbp: [Double]
    let dbp: [Double]
    let sbpSD: Double
    let dbpSD: Double
}

private let boysBPModel = BPFourthReportModel(
    height: MedCalcPedsData.bpBoysHeight,
    sbp: [102.19768, 1.82416, 0.12776, 0.00249, -0.00135, 2.73157, -0.19618, -0.04659, 0.00947],
    dbp: [61.01217, 0.68314, -0.09835, 0.01711, 0.00045, 1.46993, -0.07849, -0.03144, 0.00967],
    sbpSD: 10.7128,
    dbpSD: 11.6032
)

private let girlsBPModel = BPFourthReportModel(
    height: MedCalcPedsData.bpGirlsHeight,
    sbp: [102.01027, 1.94397, 0.00598, -0.00789, -0.00059, 2.03526, 0.02534, -0.01884, 0.00121],
    dbp: [60.50510, 1.01301, 0.01157, 0.00424, -0.00137, 1.16641, 0.12795, -0.03869, -0.00079],
    sbpSD: 10.4855,
    dbpSD: 10.9573
)

/// Mean BP polynomial: c0 + c1·a + … + c4·a⁴ + c5·h + … + c8·h⁴.
private func bpMean(_ c: [Double], ageFactor: Double, heightZ: Double) -> Double {
    let a2 = ageFactor * ageFactor, a3 = a2 * ageFactor, a4 = a3 * ageFactor
    let h2 = heightZ * heightZ, h3 = h2 * heightZ, h4 = h3 * heightZ
    return c[0] + c[1] * ageFactor + c[2] * a2 + c[3] * a3 + c[4] * a4
        + c[5] * heightZ + c[6] * h2 + c[7] * h3 + c[8] * h4
}

private func bpBand(_ percentile: Double) -> String {
    if percentile < 90 { return "Normal" }
    if percentile < 95 { return "Prehypertensive" }
    return "Hypertensive"
}

/// Shared compute for the two pre-2017 sex-specific BP percentile calculators.
private func fourthReportBP(_ model: BPFourthReportModel, _ v: MedCalcValues) -> String {
    guard let age = v.number("age"), let height = v.number("height"),
          let sbp = v.number("sbp"), let dbp = v.number("dbp") else { return "" }
    let lms = MedCalcPedsData.row(model.height, age * 12)
    let heightZ = MedCalcPedsData.zScore(lms: lms, value: height)
    let ageFactor = age - 10
    let sbpAvg = bpMean(model.sbp, ageFactor: ageFactor, heightZ: heightZ)
    let dbpAvg = bpMean(model.dbp, ageFactor: ageFactor, heightZ: heightZ)
    let sbpP = MedCalcPedsData.percentile(z: (sbp - sbpAvg) / model.sbpSD)
    let dbpP = MedCalcPedsData.percentile(z: (dbp - dbpAvg) / model.dbpSD)
    let sbpStageII = 2.326348 * model.sbpSD + sbpAvg + 5
    let dbpStageII = 2.326348 * model.dbpSD + dbpAvg + 5
    return """
    Height percentile: \(String(format: "%.1f%%", MedCalcPedsData.percentile(z: heightZ)))
    Systolic BP percentile: \(String(format: "%.1f%%", sbpP)) — \(bpBand(sbpP))
    Diastolic BP percentile: \(String(format: "%.1f%%", dbpP)) — \(bpBand(dbpP))
    Stage II hypertension threshold (99th percentile + 5 mmHg): SBP ≥ \(String(format: "%.1f", sbpStageII)), DBP ≥ \(String(format: "%.1f", dbpStageII)) mmHg
    """
}

let pediatricsCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "BloodPressurePercentBoys.htm",
        guide: """
        Blood pressure percentiles for boys aged 2–17 years (pre-2017, Fourth Report criteria). Enter age in years, height in cm, and the measured blood pressure in mmHg.

        The child's age and height-for-age Z-score (CDC LMS reference) set the expected mean and SD for systolic and diastolic BP; the measured values are converted to percentiles. Interpretation: <90th percentile normal, 90th to <95th prehypertensive, ≥95th hypertensive (stage 1). Above the 99th percentile + 5 mmHg is stage 2 hypertension. Children and adolescents whose BP exceeds 120/80 mmHg are also considered prehypertensive.
        """,
        equation: "HeightZ = ((Height/M)^L − 1)/(L·S); SBPz = (SBP − MeanSBP(age, HeightZ))/10.7128; DBPz = (DBP − MeanDBP(age, HeightZ))/11.6032; Percentile = NormalCDF(z)",
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (2–18, e.g. 10)")),
            MedCalcInput("height", "Height", .number(unitHint: "cm (e.g. 140)")),
            MedCalcInput("sbp", "Systolic BP", .number(unitHint: "mmHg (e.g. 110)")),
            MedCalcInput("dbp", "Diastolic BP", .number(unitHint: "mmHg (e.g. 70)"))
        ],
        compute: { v in fourthReportBP(boysBPModel, v) }
    ),

    MedCalcSpec(
        fileName: "BloodPressurePercentGirls.htm",
        guide: """
        Blood pressure percentiles for girls aged 2–17 years (pre-2017, Fourth Report criteria). Enter age in years, height in cm, and the measured blood pressure in mmHg.

        The child's age and height-for-age Z-score (CDC LMS reference) set the expected mean and SD for systolic and diastolic BP; the measured values are converted to percentiles. Interpretation: <90th percentile normal, 90th to <95th prehypertensive, ≥95th hypertensive (stage 1). Above the 99th percentile + 5 mmHg is stage 2 hypertension. Children and adolescents whose BP exceeds 120/80 mmHg are also considered prehypertensive.
        """,
        equation: "HeightZ = ((Height/M)^L − 1)/(L·S); SBPz = (SBP − MeanSBP(age, HeightZ))/10.4855; DBPz = (DBP − MeanDBP(age, HeightZ))/10.9573; Percentile = NormalCDF(z)",
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (2–18, e.g. 10)")),
            MedCalcInput("height", "Height", .number(unitHint: "cm (e.g. 140)")),
            MedCalcInput("sbp", "Systolic BP", .number(unitHint: "mmHg (e.g. 110)")),
            MedCalcInput("dbp", "Diastolic BP", .number(unitHint: "mmHg (e.g. 70)"))
        ],
        compute: { v in fourthReportBP(girlsBPModel, v) }
    ),

    MedCalcSpec(
        fileName: "BloodPressurePercent2017.htm",
        guide: """
        BP percentiles for children aged 0–17 years using the 2017 AAP/4th-report standard: sex, age, and height (CDC height-for-age LMS reference). Enter age in years — fractional ages (e.g. 6.25) give the most accurate percentiles — plus height in cm and blood pressure in mmHg.

        For children <13 years classification follows the 2017 AAP guidelines (elevated: ≥90th percentile or 120/80, whichever is lower; stage 1: ≥95th percentile or 130/80; stage 2: ≥95th +12 mmHg or ≥140/90). For adolescents ≥13 years, adult definitions apply (elevated 120–129/<80; stage 1 130/80–139/89; stage 2 ≥140/90). The height Z-score must be within −3.09…+3.09 for the calculation to be valid.
        """,
        equation: "HeightZ = interpolated LMS z-score; BP percentile from 99 fitted percentiles (natural-cubic regression on age, height, and their interaction); classification per AAP 2017",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (0–18, fractional e.g. 6.25)")),
            MedCalcInput("height", "Height", .number(unitHint: "cm (e.g. 120)")),
            MedCalcInput("sbp", "Systolic BP", .number(unitHint: "mmHg (e.g. 100)")),
            MedCalcInput("dbp", "Diastolic BP", .number(unitHint: "mmHg (e.g. 65)"))
        ],
        compute: { v in bp2017Result(v) }
    ),

    MedCalcSpec(
        fileName: "CDCWeightForAgeBoys.htm",
        guide: """
        CDC (NHANES) weight-for-age percentiles for boys aged 2–20 years. Enter age in years and weight in kg.

        Weight percentiles are best interpreted with reference to height (see the weight-for-height and BMI percentile calculators). At the extremes (>97th or <3rd percentile) the Z-score is a more precise measure of deviation than the percentile.
        """,
        equation: "Z = ((Weight/M)^L − 1)/(L·S) using CDC LMS values at the child's age; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (2–20, e.g. 8)")),
            MedCalcInput("weight", "Weight", .number(unitHint: "kg (e.g. 25)"))
        ],
        compute: { v in
            guard let age = v.number("age"), let weight = v.number("weight") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.cdcWeightForAgeBoys, age * 12)
            let z = MedCalcPedsData.zScore(lms: lms, value: weight)
            return """
            Weight-for-age Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", MedCalcPedsData.percentile(z: z)))

            Weight percentiles are best interpreted with reference to height (see weight-for-height / BMI percentiles).
            """
        }
    ),

    MedCalcSpec(
        fileName: "CDCWeightForAgeGirls.htm",
        guide: """
        CDC (NHANES) weight-for-age percentiles for girls aged 2–20 years. Enter age in years and weight in kg.

        Weight percentiles are best interpreted with reference to height (see the weight-for-height and BMI percentile calculators). At the extremes (>97th or <3rd percentile) the Z-score is a more precise measure of deviation than the percentile.
        """,
        equation: "Z = ((Weight/M)^L − 1)/(L·S) using CDC LMS values at the child's age; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (2–20, e.g. 8)")),
            MedCalcInput("weight", "Weight", .number(unitHint: "kg (e.g. 25)"))
        ],
        compute: { v in
            guard let age = v.number("age"), let weight = v.number("weight") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.cdcWeightForAgeGirls, age * 12)
            let z = MedCalcPedsData.zScore(lms: lms, value: weight)
            return """
            Weight-for-age Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", MedCalcPedsData.percentile(z: z)))

            Weight percentiles are best interpreted with reference to height (see weight-for-height / BMI percentiles).
            """
        }
    ),

    MedCalcSpec(
        fileName: "CDCWeightForHeightBoys.htm",
        guide: """
        CDC (NHANES) weight-for-height percentiles for boys 77–122 cm tall (about 2–5 years). Enter standing height in cm and weight in kg. An alternative to BMI for assessing over- or undernutrition in this age group; not valid for recumbent length.

        Interpretation: <5th underweight, 5th–85th healthy weight, 85th–95th at risk of overweight, ≥95th overweight.
        """,
        equation: "Z = ((Weight/M)^L − 1)/(L·S) using CDC LMS values at the child's height; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("height", "Height (standing)", .number(unitHint: "cm (77–122, e.g. 100)")),
            MedCalcInput("weight", "Weight", .number(unitHint: "kg (e.g. 15)"))
        ],
        compute: { v in
            guard let height = v.number("height"), let weight = v.number("weight") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.cdcWeightForHeightBoys, height)
            let z = MedCalcPedsData.zScore(lms: lms, value: weight)
            let p = MedCalcPedsData.percentile(z: z)
            let band = p < 5 ? "Underweight" : p < 85 ? "Healthy weight" : p < 95 ? "At risk of overweight" : "Overweight"
            return """
            Weight-for-height Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", p)) — \(band)
            """
        }
    ),

    MedCalcSpec(
        fileName: "CDCWeightForHeightGirls.htm",
        guide: """
        CDC (NHANES) weight-for-height percentiles for girls 77–122 cm tall (about 2–5 years). Enter standing height in cm and weight in kg. An alternative to BMI for assessing over- or undernutrition in this age group; not valid for recumbent length.

        Interpretation: <5th underweight, 5th–85th healthy weight, 85th–95th at risk of overweight, ≥95th overweight.
        """,
        equation: "Z = ((Weight/M)^L − 1)/(L·S) using CDC LMS values at the child's height; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("height", "Height (standing)", .number(unitHint: "cm (77–122, e.g. 100)")),
            MedCalcInput("weight", "Weight", .number(unitHint: "kg (e.g. 15)"))
        ],
        compute: { v in
            guard let height = v.number("height"), let weight = v.number("weight") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.cdcWeightForHeightGirls, height)
            let z = MedCalcPedsData.zScore(lms: lms, value: weight)
            let p = MedCalcPedsData.percentile(z: z)
            let band = p < 5 ? "Underweight" : p < 85 ? "Healthy weight" : p < 95 ? "At risk of overweight" : "Overweight"
            return """
            Weight-for-height Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", p)) — \(band)
            """
        }
    ),

    MedCalcSpec(
        fileName: "PediatricETTubeSize.htm",
        guide: """
        Endotracheal tube (ETT) size for children aged 1–8 years. Enter the child's age in years (fractions allowed, e.g. 4.5); the age is rounded to the nearest whole year and mapped to the standard tube sizes.

        For infants up to 1 year, use a 3.5 mm uncuffed tube (a 3.0 mm cuffed tube may be used for infants >3.5 kg and <1 year). The cuffed formula applies to low-profile, thin-walled cuffed tubes; with a regular cuffed tube, select one FULL size smaller than the uncuffed size. Have tubes one half-size larger and smaller available during intubation attempts.
        """,
        equation: "Uncuffed ID = 4 + Age/4; cuffed (thin-walled) ID = 3.5 + Age/4 (age rounded to nearest year)",
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (1–8, e.g. 5)"))
        ],
        compute: { v in
            guard let age = v.number("age"), age >= 1, age <= 8 else { return "" }
            let roundAge = min(8, max(1, Int(floor(age + 0.5))))
            let uncuffed = [4.0, 4.5, 5.0, 5.0, 5.0, 5.5, 6.0, 6.0][roundAge - 1]
            let cuffed = age < 2 ? 3.5 : [4.0, 4.0, 4.5, 4.5, 5.0, 5.0, 5.5][roundAge - 2]
            return """
            Uncuffed tube: \(String(format: "%.1f", uncuffed)) mm ID
            Cuffed tube (low-profile, thin-walled): \(String(format: "%.1f", cuffed)) mm ID

            With a regular (standard) cuffed tube, choose one FULL size smaller than the uncuffed size. Have tubes ± 0.5 size available.
            """
        }
    ),

    MedCalcSpec(
        fileName: "HeightPotential.htm",
        guide: """
        A child's target (adult) height from midparental height. Select sex and enter the mother's and father's heights in cm.

        For girls: subtract 13 cm from the father's height, then average with the mother's. For boys: add 13 cm to the mother's height, then average with the father's (13 cm ≈ average male–female height difference). About 8.5 cm on either side of the target represents the likely range (±2 SD).
        """,
        equation: "Target (female) = ((Father − 13) + Mother)/2; Target (male) = ((Mother + 13) + Father)/2; Z = ((Target/M)^L − 1)/(L·S); Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("sex", "Sex (child)", .choice(options: ["Female", "Male"])),
            MedCalcInput("mother", "Mother's Height", .number(unitHint: "cm (e.g. 160)")),
            MedCalcInput("father", "Father's Height", .number(unitHint: "cm (e.g. 178)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let mother = v.number("mother"),
                  let father = v.number("father") else { return "" }
            let female = sexIdx == 0
            let target = female ? (father - 13 + mother) / 2 : (mother + 13 + father) / 2
            let lms = female
                ? MedCalcPedsData.LMS(key: 1, l: 1.107132561, m: 163.3354491, s: 0.039637105)
                : MedCalcPedsData.LMS(key: 1, l: 1.16863827, m: 176.8414914, s: 0.04036818)
            let z = MedCalcPedsData.zScore(lms: lms, value: target)
            return """
            Target height: \(String(format: "%.1f cm", target))
            Likely adult height range (±2 SD): \(String(format: "%.1f – %.1f cm", target - 8.5, target + 8.5))
            Height potential Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", MedCalcPedsData.percentile(z: z)))
            """
        }
    ),

    MedCalcSpec(
        fileName: "MaintenanceFluidChildren.htm",
        guide: """
        Daily maintenance fluid requirement for children aged ~3.5–200 kg (Holliday–Segar). Enter weight in kg. Not applicable to newborn infants (0–28 days after full-term delivery).

        100 mL/kg for the first 10 kg, +50 mL/kg for 11–20 kg, +20 mL/kg for each kg over 20, capped at 2400 mL/day. The hourly rate is the daily volume divided by 24.
        """,
        equation: "DailyVol = 100·W (W≤10) or 1000 + 50·(W−10) (W≤20) or 1500 + 20·(W−20), max 2400 mL; Rate = DailyVol/24",
        inputs: [
            MedCalcInput("weight", "Weight", .number(unitHint: "kg (3.5–200, e.g. 15)"))
        ],
        compute: { v in
            guard let weight = v.number("weight") else { return "" }
            var daily: Double
            if weight < 10 {
                daily = 100 * weight
            } else if weight < 20 {
                daily = 1000 + 50 * (weight - 10)
            } else {
                daily = 1500 + 20 * (weight - 20)
            }
            if daily > 2400 { daily = 2400 }
            let rate = daily / 24
            return """
            Daily volume: \(String(format: "%.0f mL", daily))
            Maintenance rate: \(String(format: "%.1f mL/hr", rate)) (\(String(format: "%.3f", rate / 1000)) L/hr; \(String(format: "%.2f", rate / 60)) mL/min)
            """
        }
    ),

    MedCalcSpec(
        fileName: "WHOInfantHeadCircForAge.htm",
        guide: """
        WHO head-circumference-for-age percentiles for infants <24 months. Select sex, enter age in months and head circumference in cm (measured around the widest part, just above the eyebrows and ears).

        Interpretation: <2nd percentile microcephaly, 2nd–98th normal, ≥98th macrocephaly (i.e. >2 SD from the mean).
        """,
        equation: "Z = ((HeadCirc/M)^L − 1)/(L·S) using WHO LMS values at the child's age and sex; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "months (0–24, e.g. 12)")),
            MedCalcInput("circ", "Head Circumference", .number(unitHint: "cm (e.g. 47)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let age = v.number("age"),
                  let circ = v.number("circ") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.whoHeadCircForAge, age, female: sexIdx == 0)
            let z = MedCalcPedsData.zScore(lms: lms, value: circ)
            let p = MedCalcPedsData.percentile(z: z)
            let band = p < 2 ? "Microcephaly" : p < 98 ? "Normal head circumference" : "Macrocephaly"
            return """
            Head-circumference-for-age Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", p)) — \(band)
            """
        }
    ),

    MedCalcSpec(
        fileName: "WHOInfantLengthForAge.htm",
        guide: """
        WHO length-for-age percentiles for infants and toddlers from birth through 24 months. Select sex, enter age in months and measured RECUMBENT length in cm — not valid for standing height.

        At the extremes (>97th or <3rd percentile) the Z-score is a more precise measure of deviation than the percentile and is useful for tracking growth over time.
        """,
        equation: "Z = ((Length/M)^L − 1)/(L·S) using WHO LMS values at the child's age and sex; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "months (0–24, e.g. 12)")),
            MedCalcInput("length", "Length (recumbent)", .number(unitHint: "cm (e.g. 75)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let age = v.number("age"),
                  let length = v.number("length") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.whoLengthForAge, age, female: sexIdx == 0)
            let z = MedCalcPedsData.zScore(lms: lms, value: length)
            return """
            Length-for-age Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", MedCalcPedsData.percentile(z: z)))
            """
        }
    ),

    MedCalcSpec(
        fileName: "WHOInfantWeightForAge.htm",
        guide: """
        WHO weight-for-age percentiles for infants <24 months. Select sex, enter age in months and weight in kg.

        Weight percentiles are best interpreted with reference to length (see the weight-for-length calculator). At the extremes (>97th or <3rd percentile) the Z-score is a more precise measure of deviation.
        """,
        equation: "Z = ((Weight/M)^L − 1)/(L·S) using WHO LMS values at the child's age and sex; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "months (0–24, e.g. 12)")),
            MedCalcInput("weight", "Weight", .number(unitHint: "kg (e.g. 9)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let age = v.number("age"),
                  let weight = v.number("weight") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.whoWeightForAge, age, female: sexIdx == 0)
            let z = MedCalcPedsData.zScore(lms: lms, value: weight)
            return """
            Weight-for-age Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", MedCalcPedsData.percentile(z: z)))

            Weight percentiles are best interpreted with reference to length (see weight for length).
            """
        }
    ),

    MedCalcSpec(
        fileName: "WHOInfantWeightForLength.htm",
        guide: """
        WHO weight-for-length percentiles for infants and toddlers <24 months. Select sex, enter measured RECUMBENT length in cm (not standing height) and weight in kg.

        Interpretation: <2nd percentile underweight for length, 2nd–98th healthy weight, ≥98th overweight for length.
        """,
        equation: "Z = ((Weight/M)^L − 1)/(L·S) using WHO LMS values at the child's length and sex; Percentile = NormalCDF(Z)",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("length", "Length (recumbent)", .number(unitHint: "cm (45–110, e.g. 70)")),
            MedCalcInput("weight", "Weight", .number(unitHint: "kg (e.g. 8)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let length = v.number("length"),
                  let weight = v.number("weight") else { return "" }
            let lms = MedCalcPedsData.row(MedCalcPedsData.whoWeightForLength, length, female: sexIdx == 0)
            let z = MedCalcPedsData.zScore(lms: lms, value: weight)
            let p = MedCalcPedsData.percentile(z: z)
            let band = p < 2 ? "Underweight for length" : p < 98 ? "Healthy weight" : "Overweight for length"
            return """
            Weight-for-length Z-score: \(String(format: "%.2f", z))
            Percentile: \(String(format: "%.1f%%", p)) — \(band)
            """
        }
    )
]

// MARK: - 2017 BP percentile calculator (computed via fitted percentile regressions)

/// One set of the 13 regression coefficient arrays for one BP/sex combination.
private struct BP2017Coeffs {
    let b0, ba1, ba2, ba3, ba4, b1, b2, b3, b4, bb1, bb2, bb3, bb4: [Double]
}

/// Natural-cubic-style spline basis: max(0, x−k)³ terms with knot compensation (source `calcVars`).
private func cubicBasis(_ x: Double, _ k1: Double, _ k4: Double, _ k5: Double) -> (a: Double, b: Double, c: Double) {
    let a = max(0, x - k1)
    let b = max(0, x - k4)
    let c = max(0, x - k5)
    return (a * a * a, b * b * b, c * c * c)
}

private func bp2017Result(_ v: MedCalcValues) -> String {
    guard let sexIdx = v.selection("sex"), let age = v.number("age"),
          let height = v.number("height"), let sbp = v.number("sbp"),
          let dbp = v.number("dbp") else { return "" }

    let heightTable = sexIdx == 0 ? MedCalcPedsData.bp2017HeightFemale : MedCalcPedsData.bp2017HeightMale
    let heightZ = MedCalcPedsData.interpolatedZScore(heightTable, 12 * age, height)
    if abs(heightZ) > 3.09 {
        return "Height-for-age Z-score \(String(format: "%.2f", heightZ)) is outside the valid range (−3.09 to 3.09). BP percentiles cannot be calculated — check the age and height entries."
    }

    // Knots: [t1 t2 t3 t4 t5 | ta1 ta2 ta3 ta4 ta5 | tb1 tb2 tb3 tb4 tb5 | heightFactor]
    let k: [Double] = sexIdx == 0
        ? [106.7, 140.7, 154.0, 160.5, 168.9, 5.00, 10.70, 13.16, 14.51, 17.33, 6.701, 16.438, 46.80, 84.46, 203.608, 147]
        : [107.8, 140.0, 154.5, 166.4, 179.1, 5.06, 10.79, 13.22, 14.51, 17.30, -15, 8.9, 50.375, 112.684, 250.04, 150]

    // Height basis (÷100), age basis (÷100), interaction w = (Age−10)(Height−HF) (÷10000) — source calcVars.
    let h2 = cubicBasis(height, k[0], k[3], k[4])
    let h3a = max(0, height - k[1]); let h3 = h3a * h3a * h3a
    let h4a = max(0, height - k[2]); let h4 = h4a * h4a * h4a
    let x2 = (h2.a - h2.b * (k[4] - k[0]) / (k[4] - k[3]) + h2.c * (k[3] - k[0]) / (k[4] - k[3])) / 100
    let x3 = (h3 - h2.b * (k[4] - k[1]) / (k[4] - k[3]) + h2.c * (k[3] - k[1]) / (k[4] - k[3])) / 100
    let x4 = (h4 - h2.b * (k[4] - k[2]) / (k[4] - k[3]) + h2.c * (k[3] - k[2]) / (k[4] - k[3])) / 100

    let a2 = cubicBasis(age, k[5], k[8], k[9])
    let a3a = max(0, age - k[6]); let a3 = a3a * a3a * a3a
    let a4a = max(0, age - k[7]); let a4 = a4a * a4a * a4a
    let y2 = (a2.a - a2.b * (k[9] - k[5]) / (k[9] - k[8]) + a2.c * (k[8] - k[5]) / (k[9] - k[8])) / 100
    let y3 = (a3 - a2.b * (k[9] - k[6]) / (k[9] - k[8]) + a2.c * (k[8] - k[6]) / (k[9] - k[8])) / 100
    let y4 = (a4 - a2.b * (k[9] - k[7]) / (k[9] - k[8]) + a2.c * (k[8] - k[7]) / (k[9] - k[8])) / 100

    let w = (age - 10) * (height - k[15])
    let w2 = cubicBasis(w, k[10], k[13], k[14])
    let w3a = max(0, w - k[11]); let w3 = w3a * w3a * w3a
    let w4a = max(0, w - k[12]); let w4 = w4a * w4a * w4a
    let w2s = (w2.a - w2.b * (k[14] - k[10]) / (k[14] - k[13]) + w2.c * (k[13] - k[10]) / (k[14] - k[13])) / 10000
    let w3s = (w3 - w2.b * (k[14] - k[11]) / (k[14] - k[13]) + w2.c * (k[13] - k[11]) / (k[14] - k[13])) / 10000
    let w4s = (w4 - w2.b * (k[14] - k[12]) / (k[14] - k[13]) + w2.c * (k[13] - k[12]) / (k[14] - k[13])) / 10000

    let sys = sexIdx == 0
        ? BP2017Coeffs(b0: MedCalcPedsData.b0sysFS, ba1: MedCalcPedsData.ba1sysFS, ba2: MedCalcPedsData.ba2sysFS, ba3: MedCalcPedsData.ba3sysFS, ba4: MedCalcPedsData.ba4sysFS, b1: MedCalcPedsData.b1sysFS, b2: MedCalcPedsData.b2sysFS, b3: MedCalcPedsData.b3sysFS, b4: MedCalcPedsData.b4sysFS, bb1: MedCalcPedsData.bb1sysFS, bb2: MedCalcPedsData.bb2sysFS, bb3: MedCalcPedsData.bb3sysFS, bb4: MedCalcPedsData.bb4sysFS)
        : BP2017Coeffs(b0: MedCalcPedsData.b0sysMS, ba1: MedCalcPedsData.ba1sysMS, ba2: MedCalcPedsData.ba2sysMS, ba3: MedCalcPedsData.ba3sysMS, ba4: MedCalcPedsData.ba4sysMS, b1: MedCalcPedsData.b1sysMS, b2: MedCalcPedsData.b2sysMS, b3: MedCalcPedsData.b3sysMS, b4: MedCalcPedsData.b4sysMS, bb1: MedCalcPedsData.bb1sysMS, bb2: MedCalcPedsData.bb2sysMS, bb3: MedCalcPedsData.bb3sysMS, bb4: MedCalcPedsData.bb4sysMS)
    let dia = sexIdx == 0
        ? BP2017Coeffs(b0: MedCalcPedsData.b0sysFD, ba1: MedCalcPedsData.ba1sysFD, ba2: MedCalcPedsData.ba2sysFD, ba3: MedCalcPedsData.ba3sysFD, ba4: MedCalcPedsData.ba4sysFD, b1: MedCalcPedsData.b1sysFD, b2: MedCalcPedsData.b2sysFD, b3: MedCalcPedsData.b3sysFD, b4: MedCalcPedsData.b4sysFD, bb1: MedCalcPedsData.bb1sysFD, bb2: MedCalcPedsData.bb2sysFD, bb3: MedCalcPedsData.bb3sysFD, bb4: MedCalcPedsData.bb4sysFD)
        : BP2017Coeffs(b0: MedCalcPedsData.b0sysMD, ba1: MedCalcPedsData.ba1sysMD, ba2: MedCalcPedsData.ba2sysMD, ba3: MedCalcPedsData.ba3sysMD, ba4: MedCalcPedsData.ba4sysMD, b1: MedCalcPedsData.b1sysMD, b2: MedCalcPedsData.b2sysMD, b3: MedCalcPedsData.b3sysMD, b4: MedCalcPedsData.b4sysMD, bb1: MedCalcPedsData.bb1sysMD, bb2: MedCalcPedsData.bb2sysMD, bb3: MedCalcPedsData.bb3sysMD, bb4: MedCalcPedsData.bb4sysMD)

    let fitted = { (i: Int, c: BP2017Coeffs) in
        Int(floor(c.b0[i] + c.b1[i] * height + c.b2[i] * x2 + c.b3[i] * x3 + c.b4[i] * x4
            + c.ba1[i] * age + c.ba2[i] * y2 + c.ba3[i] * y3 + c.ba4[i] * y4
            + c.bb1[i] * w + c.bb2[i] * w2s + c.bb3[i] * w3s + c.bb4[i] * w4s))
    }
    let sysP = (1...99).map { fitted($0 - 1, sys) }
    let diaP = (1...99).map { fitted($0 - 1, dia) }

    func patientPercentile(_ bp: Double, _ p: [Int]) -> Int {
        var result = 0
        for pp in stride(from: 99, through: 1, by: -1) where bp >= Double(p[pp - 1]) {
            result = pp
            break
        }
        if bp <= Double(p[0]) { return 1 }
        if bp == Double(p[49]) { return 50 }
        if bp == Double(p[89]) { return 90 }
        if bp == Double(p[94]) { return 95 }
        return result
    }

    let adolescent = age >= 13
    let sbpClass: String
    let dbpClass: String
    if adolescent {
        sbpClass = sbp >= 140 ? "Stage 2 HTN" : sbp >= 130 ? "Stage 1 HTN" : sbp >= 120 ? "Elevated BP" : "Not elevated"
        dbpClass = dbp >= 90 ? "Stage 2 HTN" : dbp >= 80 ? "Stage 1 HTN" : "Not elevated"
    } else {
        sbpClass = (sbp >= 140 || sbp >= Double(sysP[94]) + 12) ? "Stage 2 HTN"
            : (sbp >= 130 || sbp >= Double(sysP[94])) ? "Stage 1 HTN"
            : (sbp >= 120 || sbp >= Double(sysP[89])) ? "Elevated BP" : "Not elevated"
        dbpClass = (dbp >= 90 || dbp >= Double(diaP[94]) + 12) ? "Stage 2 HTN"
            : (dbp >= 80 || dbp >= Double(diaP[94])) ? "Stage 1 HTN"
            : (dbp >= Double(diaP[89])) ? "Elevated BP" : "Not elevated"
    }

    let sbpStage1 = adolescent ? 130 : sysP[94]
    let sbpStage2 = adolescent ? 140 : sysP[94] + 12
    let dbpStage1 = adolescent ? 80 : diaP[94]
    let dbpStage2 = adolescent ? 90 : diaP[94] + 12

    var result = """
    \(adolescent ? "Adolescent (≥13 y): classification uses adult BP definitions." : "Child (<13 y): classification uses 2017 AAP percentile/absolute definitions.")
    Systolic BP: \(Int(sbp)) mmHg — \(sbpClass) (percentile \(patientPercentile(sbp, sysP))th)
    Diastolic BP: \(Int(dbp)) mmHg — \(dbpClass) (percentile \(patientPercentile(dbp, diaP))th)
    Population thresholds for this age/sex/height:
      SBP — 50th: \(sysP[49]) mmHg, 90th: \(sysP[89]) mmHg, stage 1: \(sbpStage1) mmHg, stage 2: \(sbpStage2) mmHg
      DBP — 50th: \(diaP[49]) mmHg, 90th: \(diaP[89]) mmHg, stage 1: \(dbpStage1) mmHg, stage 2: \(dbpStage2) mmHg
    """
    if age >= 2 {
        result += "\nHeight-for-age: Z \(String(format: "%.2f", heightZ)) (\(String(format: "%.1f%%", MedCalcPedsData.percentile(z: heightZ))) percentile)"
    }
    return result
}
