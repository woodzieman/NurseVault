import Foundation

/// Calculator specs for the Renal category.
/// Sources: CreatinineCl(_SI/_CG_SI/_Sanaka).htm, GFR_CKD_EPI*.htm,
/// Kt_V_Formulae_Multi.htm, UreaReducPercent.htm, UrinaryProteinExcretion.htm,
/// VolumeDistUrea.htm
let renalCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "CreatinineCl_SI.htm",
        guide: """
        Measured creatinine clearance from a 24-hour urine collection, in SI units. Enter urine creatinine and serum creatinine in µmol/L (µmcmol/L = 1/1000 mmol/L as published in the source) and the total collected urine volume in liters.

        A measured clearance requires a complete, timed collection and a simultaneous serum creatinine; it is the reference method for comparing against estimated equations.
        """,
        equation: "CreatClear (L/min) = UrineCreat × UrineVolume / SerumCreat / 86400",
        inputs: [
            MedCalcInput("ucr", "Urine Creatinine", .number(unitHint: "µmol/L (e.g. 200)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "µmol/L (e.g. 110)")),
            MedCalcInput("vol", "Urine Volume (24-h)", .number(unitHint: "L (e.g. 1.5)"))
        ],
        compute: { v in
            guard let ucr = v.number("ucr"), let scr = v.number("scr"),
                  let vol = v.number("vol"), scr > 0 else { return "" }
            let lPerMin = ucr * vol / scr / 86400
            return """
            Creatinine Clearance: \(String(format: "%.1f mL/min", lPerMin * 1000))
            \(String(format: "%.0f mL/hr", lPerMin * 1000 * 60))
            """
        }
    ),

    MedCalcSpec(
        fileName: "CreatinineCl.htm",
        guide: """
        Measured creatinine clearance from a 24-hour urine collection, US units. Enter urine creatinine and serum creatinine in mg/dL and the total collected urine volume in liters.

        A measured clearance requires a complete, timed collection and a simultaneous serum creatinine; it is the reference method for comparing against estimated equations.
        """,
        equation: "CreatClear (mL/min) = UrineCreat × UrineVolume / SerumCreat / 1440",
        inputs: [
            MedCalcInput("ucr", "Urine Creatinine", .number(unitHint: "mg/dL (e.g. 20)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.1)")),
            MedCalcInput("vol", "Urine Volume (24-h)", .number(unitHint: "L (e.g. 1.5)"))
        ],
        compute: { v in
            guard let ucr = v.number("ucr"), let scr = v.number("scr"),
                  let vol = v.number("vol"), scr > 0 else { return "" }
            let mlPerMin = ucr * vol / scr / 1440
            return "Creatinine Clearance: \(String(format: "%.1f mL/min", mlPerMin))"
        }
    ),

    MedCalcSpec(
        fileName: "CreatinineCl_CG_SI.htm",
        guide: """
        Cockcroft-Gault equation estimates creatinine clearance from age, weight, and serum creatinine. Select sex (females multiply by 0.85), enter age in years, weight in kg (ideal or lean body weight), and serum creatinine in mg/dL.

        This equation provides an estimate only if the serum creatinine is stable. It remains the standard for many drug-dosing adjustments.
        """,
        equation: "CreatClear = 0.0205 × SexFactor × (140 − Age) × Weight / SerumCreat",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female (0.85)", "Male (1)"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 60)")),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 70)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.2)"))
        ],
        compute: { v in
            guard let scr = v.number("scr"), let age = v.number("age"),
                  let wgt = v.number("wgt"), let sexIdx = v.selection("sex") else { return "" }
            guard scr > 0 else { return "" }
            let sex = sexIdx == 0 ? 0.85 : 1.0
            let crcl = 0.0205 * sex * (140 - age) * wgt / scr
            return "Creatinine Clearance: \(String(format: "%.1f mL/min", crcl))"
        }
    ),

    MedCalcSpec(
        fileName: "CreatinineCl_Sanaka.htm",
        guide: """
        Sanaka formula estimates creatinine clearance in older subjects (age 60–92) with low muscle mass (24–61 kg), using serum albumin instead of assuming constant muscle mass.

        For females the multipliers are 13/29; for males 19/32. Enter sex, weight (kg), plasma albumin (g/dL), and serum creatinine (mg/dL). This may not be appropriate in protein-wasting states such as nephrotic syndrome.
        """,
        equation: "CrCl = (Weight × (MultFactor × Albumin + AddFactor)) / (100 × SerumCreat)",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female (×13, +29)", "Male (×19, +32)"])),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 50)")),
            MedCalcInput("alb", "Plasma Albumin", .number(unitHint: "g/dL (e.g. 3.5)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.0)"))
        ],
        compute: { v in
            guard let wgt = v.number("wgt"), let alb = v.number("alb"),
                  let scr = v.number("scr"), let sexIdx = v.selection("sex") else { return "" }
            guard scr > 0 else { return "" }
            let (mult, add): (Double, Double) = sexIdx == 0 ? (13, 29) : (19, 32)
            let crcl = (wgt * (mult * alb + add)) / (100 * scr)
            return "Creatinine Clearance: \(String(format: "%.1f mL/min", crcl))"
        }
    ),

    MedCalcSpec(
        fileName: "GFR_CKD_EPI.htm",
        guide: """
        CKD-EPI (2009) equation estimates GFR from serum creatinine. Select sex, race (Black patients multiply by 1.159), enter age in years and serum creatinine in mg/dL.

        GFR is expressed per 1.73 m² body surface area. Values are interpreted as GFR categories for staging chronic kidney disease.
        """,
        equation: """
        GFR = 141 × min(Scr/κ, 1)^α × max(Scr/κ, 1)^-1.209 × 0.993^Age × Sex × Race
        (Females: Sex=1.018, α=-0.329, κ=0.7; Males: Sex=1, α=-0.411, κ=0.9)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("race", "Race", .choice(options: ["White or Other (1)", "Black (1.159)"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 60)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.2)"))
        ],
        compute: { v in
            guard let scr = v.number("scr"), let age = v.number("age"),
                  let sexIdx = v.selection("sex"), let raceIdx = v.selection("race") else { return "" }
            guard scr > 0, age > 0 else { return "" }
            let (sex, alpha, kappa): (Double, Double, Double) = sexIdx == 0 ? (1.018, -0.329, 0.7) : (1.0, -0.411, 0.9)
            let race = raceIdx == 0 ? 1.0 : 1.159
            let ratio = scr / kappa
            let gfr = 141 * pow(min(ratio, 1), alpha) * pow(max(ratio, 1), -1.209) * pow(0.993, age) * sex * race
            return "eGFR: \(String(format: "%.0f mL/min/1.73 m²", gfr))"
        }
    ),

    MedCalcSpec(
        fileName: "GFR_MDRD_Full.htm",
        guide: """
        MDRD (Modification of Diet in Renal Disease) study equation estimates GFR using the full set of covariates. Enter serum creatinine (mg/dL), age (years), sex, race, BUN (mg/dL), and albumin (g/dL).
        """,
        equation: """
        GFR = 170 × SerumCreat^-0.999 × Age^-0.176 × Sex × Race × BUN^-0.170 × Albumin^0.318
        (Female: 0.762; Black: 1.18)
        """,
        inputs: [
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.2)")),
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 60)")),
            MedCalcInput("sex", "Sex", .choice(options: ["Female (0.762)", "Male (1)"])),
            MedCalcInput("race", "Race", .choice(options: ["Black (1.18)", "Non-Black (1)"])),
            MedCalcInput("bun", "BUN", .number(unitHint: "mg/dL (e.g. 18)")),
            MedCalcInput("alb", "Albumin", .number(unitHint: "g/dL (e.g. 4.0)"))
        ],
        compute: { v in
            guard let scr = v.number("scr"), let age = v.number("age"),
                  let bun = v.number("bun"), let alb = v.number("alb"),
                  let sexIdx = v.selection("sex"), let raceIdx = v.selection("race") else { return "" }
            guard scr > 0, age > 0, bun > 0, alb > 0 else { return "" }
            let sex = sexIdx == 0 ? 0.762 : 1.0
            let race = raceIdx == 0 ? 1.18 : 1.0
            let gfr = 170 * pow(scr, -0.999) * pow(age, -0.176) * sex * race * pow(bun, -0.170) * pow(alb, 0.318)
            return "GFR: \(String(format: "%.1f mL/min/1.73 m²", gfr))"
        }
    ),

    MedCalcSpec(
        fileName: "gfr_ckd_epi_with_cystatin_2021.htm",
        guide: """
        CKD-EPI (2021) creatinine–cystatin C equation, without a race term. Select sex, enter age (years), serum creatinine (mg/dL), and cystatin C (mg/L). Results are rounded to the nearest whole mL/min/1.73 m².

        The creatinine–cystatin C combination is the preferred GFR estimate in CKD. There may be significant differences between estimated and measured GFR in individual patients; non-normalized eGFR may be used for medication dosing adjustments.
        """,
        equation: """
        eGFR = 135 × min(Scr/κ,1)^α × max(Scr/κ,1)^-0.544 × min(Cys/0.8,1)^-0.323 × max(Cys/0.8,1)^-0.778 × 0.9961^Age × SexFactor
        (Females: 0.963, α=-0.219, κ=0.7; Males: 1, α=-0.144, κ=0.9)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 55)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.1)")),
            MedCalcInput("cys", "Cystatin C", .number(unitHint: "mg/L (e.g. 1.0)"))
        ],
        compute: { v in
            guard let scr = v.number("scr"), let cys = v.number("cys"), let age = v.number("age"),
                  let sexIdx = v.selection("sex") else { return "" }
            guard scr > 0, cys > 0, age > 0 else { return "" }
            let (sex, alpha, kappa): (Double, Double, Double) = sexIdx == 0 ? (0.963, -0.219, 0.7) : (1.0, -0.144, 0.9)
            let r = scr / kappa
            let c = cys / 0.8
            let egfr = 135 * pow(min(r, 1), alpha) * pow(max(r, 1), -0.544)
                * pow(min(c, 1), -0.323) * pow(max(c, 1), -0.778) * pow(0.9961, age) * sex
            return "eGFR: \(String(format: "%.0f mL/min/1.73 m²", egfr))"
        }
    ),

    MedCalcSpec(
        fileName: "GFR_CKD_EPI_2021.htm",
        guide: """
        CKD-EPI (2021) creatinine-only equation, without a race term. Select sex, enter age (years) and serum creatinine (mg/dL). Results are rounded to the nearest whole mL/min/1.73 m².

        There may be significant differences between estimated and measured GFR in individual patients; non-normalized eGFR may be used for medication dosing adjustments.
        """,
        equation: """
        eGFR = 142 × min(Scr/κ,1)^α × max(Scr/κ,1)^-1.2 × 0.9938^Age × SexFactor
        (Females: 1.012, α=-0.241, κ=0.7; Males: 1, α=-0.302, κ=0.9)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 55)")),
            MedCalcInput("scr", "Serum Creatinine", .number(unitHint: "mg/dL (e.g. 1.1)"))
        ],
        compute: { v in
            guard let scr = v.number("scr"), let age = v.number("age"),
                  let sexIdx = v.selection("sex") else { return "" }
            guard scr > 0, age > 0 else { return "" }
            let (sex, alpha, kappa): (Double, Double, Double) = sexIdx == 0 ? (1.012, -0.241, 0.7) : (1.0, -0.302, 0.9)
            let r = scr / kappa
            let egfr = 142 * pow(min(r, 1), alpha) * pow(max(r, 1), -1.2) * pow(0.9938, age) * sex
            return "eGFR: \(String(format: "%.0f mL/min/1.73 m²", egfr))"
        }
    ),

    MedCalcSpec(
        fileName: "GFR_CKD_EPI_by_Cystatin_2012.htm",
        guide: """
        CKD-EPI (2012) cystatin C-only equation, without a race term. Select sex, enter age (years) and cystatin C (mg/L). Results are rounded to the nearest whole mL/min/1.73 m².
        """,
        equation: """
        eGFR = 133 × min(Cys/0.8,1)^-0.499 × max(Cys/0.8,1)^-1.328 × 0.996^Age × SexFactor
        (Females: 0.932; Males: 1)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 55)")),
            MedCalcInput("cys", "Cystatin C", .number(unitHint: "mg/L (e.g. 1.0)"))
        ],
        compute: { v in
            guard let cys = v.number("cys"), let age = v.number("age"),
                  let sexIdx = v.selection("sex") else { return "" }
            guard cys > 0, age > 0 else { return "" }
            let sex = sexIdx == 0 ? 0.932 : 1.0
            let c = cys / 0.8
            let egfr = 133 * pow(min(c, 1), -0.499) * pow(max(c, 1), -1.328) * pow(0.996, age) * sex
            return "eGFR: \(String(format: "%.0f mL/min/1.73 m²", egfr))"
        }
    ),

    MedCalcSpec(
        fileName: "Kt_V_Formulae_Multi.htm",
        guide: """
        Compares the common single-pool Kt/V equations for a hemodialysis session. Enter pre- and post-dialysis BUN (mg/dL), dialysis time (hours), ultrafiltration volume (L), and post-dialysis weight (kg).

        A Kt/V of at least about 1.2 (single pool) is generally the adequacy threshold; the Daugirdas formula accounts for intradialytic urea generation and reabsorption.
        """,
        equation: """
        Daugirdas = −ln(Post/Pre − 0.008×Hrs) + ((4 − 3.5×Post/Pre) × UF/Weight)
        Lowrie = ln(Pre/Post)  •  Keshaviah = 1.162×ln(Pre/Post)
        Barth = 3.1×(Pre−Post)/Pre − 0.66  •  Basile = 2.3×(Pre−Post)/Pre − 0.284
        Jindal = 4×(Pre−Post)/Pre − 1.2  •  Kerr = 4.2×(Pre−Post)/Pre − 1.48
        """,
        inputs: [
            MedCalcInput("pre", "BUN Pre-Dialysis", .number(unitHint: "mg/dL (e.g. 80)")),
            MedCalcInput("post", "BUN Post-Dialysis", .number(unitHint: "mg/dL (e.g. 30)")),
            MedCalcInput("hours", "Dialysis Time", .number(unitHint: "hours (e.g. 4)")),
            MedCalcInput("uf", "Ultrafiltration Volume", .number(unitHint: "L (e.g. 2)")),
            MedCalcInput("wgt", "Post-Dialysis Weight", .number(unitHint: "kg (e.g. 70)"))
        ],
        compute: { v in
            guard let pre = v.number("pre"), let post = v.number("post"),
                  let hours = v.number("hours"), let uf = v.number("uf"),
                  let wgt = v.number("wgt") else { return "" }
            guard pre > 0, post > 0, wgt > 0 else { return "" }
            let daugiArg = post / pre - 0.008 * hours
            guard daugiArg > 0 else { return "" }
            let daugirdas = -log(daugiArg) + (4 - 3.5 * post / pre) * uf / wgt
            let lowrie = log(pre / post)
            let keshaviah = 1.162 * lowrie
            let reduction = (pre - post) / pre
            let barth = 3.1 * reduction - 0.66
            let basile = 2.3 * reduction - 0.284
            let jindal = 4 * reduction - 1.2
            let kerr = 4.2 * reduction - 1.48
            return """
            Kt/V Daugirdas: \(String(format: "%.3f", daugirdas))
            Kt/V Lowrie: \(String(format: "%.3f", lowrie))
            Kt/V Keshaviah: \(String(format: "%.3f", keshaviah))
            Kt/V Barth: \(String(format: "%.3f", barth))
            Kt/V Basile: \(String(format: "%.3f", basile))
            Kt/V Jindal: \(String(format: "%.3f", jindal))
            Kt/V Kerr: \(String(format: "%.3f", kerr))
            """
        }
    ),

    MedCalcSpec(
        fileName: "UreaReducPercent.htm",
        guide: """
        The urea reduction percentage (PRU) describes the fraction of urea removed during a single hemodialysis session. Enter pre- and post-dialysis urea or BUN in the same units (mg/dL).

        A PRU of at least about 65% (with adequate dialysis dose) is commonly used as a dialysis adequacy target; it must be paired with Kt/V.
        """,
        equation: "PRU = 100 × (Pre − Post) / Pre",
        inputs: [
            MedCalcInput("pre", "Urea Pre-Dialysis", .number(unitHint: "mg/dL (e.g. 80)")),
            MedCalcInput("post", "Urea Post-Dialysis", .number(unitHint: "mg/dL (e.g. 30)"))
        ],
        compute: { v in
            guard let pre = v.number("pre"), let post = v.number("post"), pre > 0 else { return "" }
            let pru = 100 * (pre - post) / pre
            return "PRU: \(String(format: "%.1f%%", pru))"
        }
    ),

    MedCalcSpec(
        fileName: "UrinaryProteinExcretion.htm",
        guide: """
        A single random (spot) urine sample can estimate daily protein excretion: the protein-to-creatinine ratio numerically equals grams excreted per day when both are in mg/dL. Enter spot urine protein and creatinine in mg/dL.

        About 0.8 g/day or more suggests significant proteinuria; 3.5 g/day or more is nephrotic-range.
        """,
        equation: "ProteinExcreted (g/day) = SpotUrineProtein / SpotUrineCreat",
        inputs: [
            MedCalcInput("prot", "Spot Urine Protein", .number(unitHint: "mg/dL (e.g. 100)")),
            MedCalcInput("creat", "Spot Urine Creatinine", .number(unitHint: "mg/dL (e.g. 120)"))
        ],
        compute: { v in
            guard let prot = v.number("prot"), let creat = v.number("creat"), creat > 0 else { return "" }
            let gPerDay = prot / creat
            let interp = gPerDay >= 3.5 ? "Nephrotic-range proteinuria"
                : gPerDay >= 0.8 ? "Significant proteinuria"
                : "Below the significant-proteinuria threshold"
            return "Protein Excreted: \(String(format: "%.2f g/day", gPerDay)) — \(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "VolumeDistUrea.htm",
        guide: """
        The volume of distribution of urea (VdU) approximates total body water and is used in dialysis modeling. Select sex and enter age (years), height (cm), and weight (kg).
        """,
        equation: """
        Females: VDU = (0.1069 × Height) + (0.2466 × Weight) − 2.097
        Males: VDU = 2.447 − (0.09516 × Age) + (0.1074 × Height) + (0.3362 × Weight)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 60)")),
            MedCalcInput("hgt", "Height", .number(unitHint: "cm (e.g. 165)")),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 65)"))
        ],
        compute: { v in
            guard let age = v.number("age"), let hgt = v.number("hgt"),
                  let wgt = v.number("wgt"), let sexIdx = v.selection("sex") else { return "" }
            let vdu = sexIdx == 0
                ? (0.1069 * hgt) + (0.2466 * wgt) - 2.097
                : 2.447 - (0.09516 * age) + (0.1074 * hgt) + (0.3362 * wgt)
            return "Volume of Distribution of Urea: \(String(format: "%.1f L", vdu))"
        }
    )
]
