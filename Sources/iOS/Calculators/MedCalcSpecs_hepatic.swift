import Foundation

/// Calculator specs for the Hepatic category.
/// Sources: autoImmunehepatitis.htm, ChildTurPuScore.htm, cirrhosisprobability_mc.htm,
/// fib4_multidx.htm, GIPSS.htm, HepatitisCriteria.htm, meld3.htm, MELD.htm,
/// Milan.htm, peldcr.htm, TipsRisk.htm
let hepaticCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "autoImmunehepatitis.htm",
        guide: """
        Revised International Autoimmune Hepatitis Group (IAIHG) diagnostic criteria. For each item select the option that fits the patient — points (including negative points) are added to the total score.

        Titres refer to immunofluorescence on rodent tissues. Interpret the total score against the pre-treatment bands (definite 16–25, probable 10–15, less likely 0–9) or the post-treatment bands (definite 18–25, probable 12–17, less likely 0–11).
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female (2 pts)", "Male (0 pts)"])),
            MedCalcInput("apl", "Alkaline Phosphatase / Aminotransferase Ratio", .choice(options: [">3.0 (−2 pts)", "<3.0 (2 pts)"])),
            MedCalcInput("glob", "Serum Globulin, Gamma Globulin or IgG Ratio to Normal", .choice(options: [">2.0 (3 pts)", "1.5–2.0 (2 pts)", "1.0–1.5 (1 pt)", "<1.0 (0 pts)"])),
            MedCalcInput("ana", "ANA or LKM-1 Titre", .choice(options: [">1:80 (>1:20 in child) (3 pts)", "1:80 (1:10–1:20 in child) (2 pts)", "1:40 (1 pt)", "<1:40 (<1:10 in child) (0 pts)"])),
            MedCalcInput("sma", "SMA Titre", .choice(options: [">1:80 (>1:20 in child) (3 pts)", "1:80 (1:20 in child) (2 pts)", "1:40 (1 pt)", "<1:40 (<1:20 in child) (0 pts)"])),
            MedCalcInput("sla", "Positive SLA, ASGP-R, LSP, LC1, LP, HHPM or Sulfatide", .yesNo),
            MedCalcInput("ama", "Positive Antimitochondrial Antibody (AMA)", .yesNo),
            MedCalcInput("viral", "Viral Markers", .choice(options: [
                "IgM anti-HAV, HBsAg or IgM anti-HBc (−3 pts)",
                "Anti-HCV by ELISA or RIBA (−2 pts)",
                "Anti-HCV by PCR/RNA (−3 pts)",
                "Other test or active viral infection (−3 pts)",
                "Seronegative for viruses (3 pts)"
            ])),
            MedCalcInput("drug", "Recent Hepatotoxic Drug or Blood Product Exposure", .choice(options: ["Yes (−2 pts)", "No (1 pt)"])),
            MedCalcInput("alcohol", "Alcohol Consumption", .choice(options: [
                "Male <35 gm/day; female <25 gm/day (2 pts)",
                "Male 35–50 gm/day; female 25–40 gm/day (0 pts)",
                "Male 50–80 gm/day; female 40–60 gm/day (−2 pts)",
                "Male >80 gm/day; female >60 gm/day (−1 pt)"
            ])),
            MedCalcInput("autoimmune", "Other Autoimmune Disease in Patient or First-Degree Relatives", .yesNo),
            MedCalcInput("hla", "HLA B8-DR3 Haplotype or DR4 Allotype", .yesNo),
            MedCalcInput("histology", "Histology", .choice(options: [
                "CAH / piecemeal necrosis / lobular involvement / bridging necrosis (3 pts)",
                "Same without lobular involvement or bridging (2 pts)",
                "Rosetting (1 pt)",
                "Marked plasma cell infiltrate (1 pt)",
                "Biliary changes (−1 pt)",
                "Granuloma / siderosis / copper / other changes suggesting a different etiology (−3 pts)"
            ])),
            MedCalcInput("response", "Response to Therapy", .choice(options: [
                "Complete response (2 pts)",
                "Partial response or failure (0 pts)",
                "No response in terms of disease activity (−2 pts)",
                "Relapse during or after treatment withdrawal after complete initial response (3 pts)"
            ]))
        ],
        compute: { v in
            let points: [Int] = [
                v.selection("sex").map { $0 == 0 ? 2 : 0 } ?? 0,
                v.selection("apl").map { $0 == 0 ? -2 : 2 } ?? 0,
                v.selection("glob").map { [3, 2, 1, 0][$0 % 4] } ?? 0,
                v.selection("ana").map { [3, 2, 1, 0][$0 % 4] } ?? 0,
                v.selection("sma").map { [3, 2, 1, 0][$0 % 4] } ?? 0,
                v.selection("sla") ?? 0,
                (v.selection("ama") ?? 0) * -2,
                v.selection("viral").map { [-3, -2, -3, -3, 3][$0 % 5] } ?? 0,
                v.selection("drug").map { $0 == 0 ? -2 : 1 } ?? 0,
                v.selection("alcohol").map { [2, 0, -2, -1][$0 % 4] } ?? 0,
                v.selection("autoimmune") ?? 0,
                v.selection("hla") ?? 0,
                v.selection("histology").map { [3, 2, 1, 1, -1, -3][$0 % 6] } ?? 0,
                v.selection("response").map { [2, 0, -2, 3][$0 % 4] } ?? 0
            ]
            let score = points.reduce(0, +)
            let pre: String
            if (16...25).contains(score) { pre = "Definite Autoimmune Hepatitis" }
            else if (10...15).contains(score) { pre = "Probable AIH" }
            else if (0...9).contains(score) { pre = "Less likely AIH" }
            else { pre = "Outside the published scoring range" }
            let post: String
            if (18...25).contains(score) { post = "Definite Autoimmune Hepatitis" }
            else if (12...17).contains(score) { post = "Probable AIH" }
            else if (0...11).contains(score) { post = "Less likely AIH" }
            else { post = "Outside the published scoring range" }
            return """
            AIH Score: \(score) points
            Pre-treatment prediction (16–25 definite / 10–15 probable / 0–9 less likely): \(pre)
            Post-treatment prediction (18–25 definite / 12–17 probable / 0–11 less likely): \(post)
            """
        }
    ),

    MedCalcSpec(
        fileName: "ChildTurPuScore.htm",
        guide: """
        Child-Turcotte-Pugh (CTP) classification for severity of liver disease. For each of the five parameters select the band that fits the patient; each band contributes 1–3 points.

        In primary biliary cholangitis, bilirubin points are sometimes scored differently: 1–4 mg/dL → 1 point, 4–10 mg/dL → 2 points, >10 mg/dL → 3 points.
        """,
        inputs: [
            MedCalcInput("enceph", "Hepatic Encephalopathy", .choice(options: [
                "None (1 pt)",
                "Grade 1–2: altered mood/confusion, inappropriate behavior (2 pts)",
                "Grade 3–4: stuporous or comatose (3 pts)"
            ])),
            MedCalcInput("ascites", "Ascites", .choice(options: ["Absent (1 pt)", "Slight (2 pts)", "Moderate–severe (3 pts)"])),
            MedCalcInput("bili", "Serum Bilirubin", .choice(options: ["<2 mg/dL (1 pt)", "2–3 mg/dL (2 pts)", ">3 mg/dL (3 pts)"])),
            MedCalcInput("alb", "Serum Albumin", .choice(options: [">3.5 g/dL (1 pt)", "2.8–3.5 g/dL (2 pts)", "<2.8 g/dL (3 pts)"])),
            MedCalcInput("pt", "Prothrombin Time Prolongation", .choice(options: [
                "<4 s above control / INR <1.7 (1 pt)",
                "4–6 s above control / INR 1.7–2.3 (2 pts)",
                ">6 s above control / INR >2.3 (3 pts)"
            ]))
        ],
        compute: { v in
            let bands = [v.selection("enceph"), v.selection("ascites"), v.selection("bili"), v.selection("alb"), v.selection("pt")]
            let score = bands.reduce(0) { $0 + ($1 ?? 0) + 1 }
            let cls: String
            if (5...6).contains(score) { cls = "Child class A (mild)" }
            else if (7...9).contains(score) { cls = "Child class B (moderate)" }
            else if (10...15).contains(score) { cls = "Child class C (severe)" }
            else { cls = "Outside the published 5–15 range" }
            return "CTP Score: \(score) points — \(cls)"
        }
    ),

    MedCalcSpec(
        fileName: "cirrhosisprobability_mc.htm",
        guide: """
        Multi-index estimate of cirrhosis probability in hepatitis C, from a single set of labs. Enter age, platelet count, ALT, AST, the laboratory's top-normal AST value, and INR. The calculator reports five indexes, each with its own interpretation.

        Enter platelets as the count per liter divided by 1000 (i.e. per microliter; e.g. 150,000/µL = 150 = 150 ×10⁹/L) — the Lok, GUCI, APRI, and FIB-4 formulas all take this number.
        """,
        equation: """
        CDS = PlateletScore + ALT/AST RatioScore + INRScore
        Lok Index = e^(1.26×AST/ALT + 5.27×INR − 0.0089×Platelets − 5.56) / (1 + e^(same))
        GUCI = (AST/TopNormalAST) × INR × 100 / Platelets
        APRI = (AST/TopNormalAST) × 100 / Platelets
        FIB-4 = Age × AST / (Platelets × √ALT)
        """,
        inputs: [
            MedCalcInput("age", "Age", .number(unitHint: "years (e.g. 55)")),
            MedCalcInput("plt", "Platelet Count", .number(unitHint: "10³/µL = 10⁹/L (e.g. 150)")),
            MedCalcInput("alt", "ALT", .number(unitHint: "U/L (e.g. 40)")),
            MedCalcInput("ast", "AST", .number(unitHint: "U/L (e.g. 55)")),
            MedCalcInput("tnast", "Top Normal AST (lab reference)", .number(unitHint: "U/L (e.g. 40)")),
            MedCalcInput("inr", "INR", .number(unitHint: "ratio (e.g. 1.1)"))
        ],
        compute: { v in
            guard let age = v.number("age"), let plt = v.number("plt"),
                  let alt = v.number("alt"), let ast = v.number("ast"),
                  let tna = v.number("tnast"), let inr = v.number("inr"),
                  plt > 0, tna > 0, alt > 0 else { return "" }
            let plateletScore = cirrhosisPlateletScore(plt)
            let ratio = alt / ast
            let ratioScore = ratio > 1.7 ? 0 : (ratio >= 1.2 ? 1 : (ratio >= 0.6 ? 2 : 3))
            let inrScore = inr < 1.1 ? 0 : (inr <= 1.4 ? 1 : 2)
            let cds = plateletScore + ratioScore + inrScore
            let cdsI = cds <= 7 ? "cirrhosis less likely" : "cirrhosis more likely (CDS ≥8 has >90% specificity)"
            let lo = 1.26 * ast / alt + 5.27 * inr - 0.0089 * plt - 5.56
            let lok = exp(lo) / (1 + exp(lo))
            let lokI = lok < 0.2 ? "cirrhosis less likely" : (lok <= 0.5 ? "indeterminate" : "cirrhosis more likely")
            let guci = ast / tna * inr * 100 / plt
            let guciI = guci < 1 ? "cirrhosis less likely" : "cirrhosis more likely"
            let apri = ast / tna * 100 / plt
            let apriI: String
            if apri <= 0.5 { apriI = "significant fibrosis or cirrhosis less likely" }
            else if apri <= 1 { apriI = "significant fibrosis indeterminate, cirrhosis less likely" }
            else if apri <= 1.5 { apriI = "significant fibrosis more likely, cirrhosis indeterminate" }
            else if apri <= 2 { apriI = "significant fibrosis more likely, cirrhosis indeterminate" }
            else { apriI = "significant fibrosis and cirrhosis more likely" }
            let fib4 = age * ast / (plt * sqrt(alt))
            let fib4I = fib4 < 1.45 ? "cirrhosis less likely" : (fib4 <= 3.25 ? "indeterminate" : "cirrhosis more likely")
            return """
            CDS: \(cds) points — \(cdsI)
            Lok Index: \(String(format: "%.2f", lok)) — \(lokI)
            GUCI: \(String(format: "%.1f", guci)) — \(guciI)
            APRI: \(String(format: "%.2f", apri)) — \(apriI)
            FIB-4: \(String(format: "%.2f", fib4)) — \(fib4I)
            """
        }
    ),

    MedCalcSpec(
        fileName: "fib4_multidx.htm",
        guide: """
        FIB-4 index (2026 update), an inexpensive indirect marker of liver fibrosis in adults. Enter disease type, age, platelet count, AST, and ALT. Interpretation cutoffs depend on disease type and age.

        FIB-4 accuracy is low in patients under 35. Normal platelet count is 150–400 ×10⁹/L. Enter platelets as reported per liter divided by 1000 (e.g. 150).
        """,
        equation: "FIB-4 = Age × AST / (Platelets × √ALT)   (platelets in 10³/µL ≡ 10⁹/L; source uses 0.001 × platelets in cells/µL, numerically identical)",
        inputs: [
            MedCalcInput("type", "Type of Liver Disease", .choice(options: ["MASLD", "Non-MASLD"])),
            MedCalcInput("age", "Age", .number(unitHint: "years (18–120)")),
            MedCalcInput("plt", "Platelet Count", .number(unitHint: "10³/µL = 10⁹/L (e.g. 150)")),
            MedCalcInput("ast", "AST", .number(unitHint: "U/L (e.g. 35)")),
            MedCalcInput("alt", "ALT", .number(unitHint: "U/L (e.g. 45)"))
        ],
        compute: { v in
            guard let age = v.number("age"), let plt = v.number("plt"),
                  let ast = v.number("ast"), let alt = v.number("alt"),
                  let typeIdx = v.selection("type"),
                  plt > 0, alt > 0 else { return "" }
            let fib4 = age * ast / (plt * sqrt(alt))
            let (low, high) = typeIdx == 0 ? (age < 65 ? 1.3 : 2.0, 2.67) : (1.45, 3.25)
            let risk = fib4 > high ? "Advanced fibrosis/cirrhosis more likely" : (fib4 >= low ? "Indeterminate risk" : "Cirrhosis less likely")
            let typeLabel = typeIdx == 0 ? "MASLD" : "non-MASLD"
            let ageLabel = age < 65 ? "<65" : "≥65"
            let band = typeIdx == 0 ? (age < 65 ? "<1.3 / 1.3–2.67 / >2.67" : "<2 / 2–2.67 / >2.67") : "<1.45 / 1.45–3.25 / >3.25"
            return """
            FIB-4: \(String(format: "%.2f", fib4))
            Interpretation (\(typeLabel), age \(ageLabel); bands \(band)): \(risk)
            """
        }
    ),

    MedCalcSpec(
        fileName: "GIPSS.htm",
        guide: """
        GIPSS (Genetically Inspired International Prognostic Scoring System) for primary myelofibrosis in adults. Select the karyotype risk class and toggle each high-risk molecular feature present.

        Karyotype classes: VHR = single or multiple abnormalities of −7, i(17q), inv(3)/3q21, 12p-/12p11.2, 11q-/11q23, or other autosomal trisomies not including +8/+9; Favorable = normal karyotype or sole abnormalities of +9, 13q−, 20q−, chromosome 1 translocation/duplication, or sex chromosome abnormality including −Y; Unfavorable = all other abnormalities.
        """,
        inputs: [
            MedCalcInput("karyo", "Karyotype Classification", .choice(options: ["Very high risk (VHR) (2 pts)", "Unfavorable (1 pt)", "Favorable (0 pts)"])),
            MedCalcInput("calr", "Absence of Type 1-Like CALR Mutation", .yesNo),
            MedCalcInput("asxl1", "ASXL1 Mutation Present", .yesNo),
            MedCalcInput("srsf2", "SRSF2 Mutation Present", .yesNo),
            MedCalcInput("u2af1", "U2AF1 Q157 Mutation Present", .yesNo)
        ],
        compute: { v in
            let karyo = v.selection("karyo").map { [2, 1, 0][$0 % 3] } ?? 0
            let score = karyo + (v.selection("calr") ?? 0) + (v.selection("asxl1") ?? 0)
                + (v.selection("srsf2") ?? 0) + (v.selection("u2af1") ?? 0)
            let (group, s5, med): (String, Double, Double)
            if score == 0 { (group, s5, med) = ("Low risk", 94, 26.4) }
            else if score == 1 { (group, s5, med) = ("Intermediate risk - 1", 73, 10.3) }
            else if score == 2 { (group, s5, med) = ("Intermediate risk - 2", 40, 4.6) }
            else { (group, s5, med) = ("High risk", 14, 2.6) }
            return """
            GIPSS Score: \(score) points (reported band: \(score <= 2 ? "\(score)" : "3 to 6"))
            Risk group: \(group)
            5-year overall survival: \(Int(s5))%
            Median overall survival: \(String(format: "%.1f", med)) years
            """
        }
    ),

    MedCalcSpec(
        fileName: "HepatitisCriteria.htm",
        guide: """
        Maddrey discriminant function for severe alcoholic hepatitis: helps decide which patients may benefit from corticosteroid therapy. Enter the patient's prothrombin time, the laboratory control value (same units, seconds), and serum bilirubin.

        Patients with a score ≥32 may benefit from treatment with corticosteroids (also screen for contraindications such as uncontrolled infection or active GI bleeding).
        """,
        equation: "Discriminant Function Index = 4.6 × (ProthrombinTime − ControlProthrombinTime) + Bilirubin",
        inputs: [
            MedCalcInput("pt", "Patient Prothrombin Time", .number(unitHint: "seconds (e.g. 18)")),
            MedCalcInput("cpt", "Control Prothrombin Time", .number(unitHint: "seconds (e.g. 13)")),
            MedCalcInput("bili", "Serum Bilirubin", .number(unitHint: "mg/dL (µmol/L ÷ 17.1) (e.g. 6)"))
        ],
        compute: { v in
            guard let pt = v.number("pt"), let cpt = v.number("cpt"),
                  let bili = v.number("bili") else { return "" }
            let index = 4.6 * (pt - cpt) + bili
            let rounded = Int(index.rounded())
            let note = index >= 32 ? "Score ≥32: patient may benefit from corticosteroid therapy" : "Score <32: severe disease less likely; corticosteroids generally not indicated on this score alone"
            return """
            Discriminant Function Index: \(rounded)
            \(note)
            """
        }
    ),

    MedCalcSpec(
        fileName: "meld3.htm",
        guide: """
        MELD 3.0 score, the current allocation score for liver transplantation, which adds serum albumin to the classic MELD inputs and includes a sex correction (females add 1.33) to reduce the bias of lower creatinine in women.

        Values are capped as in the source: bilirubin and INR minimum 1, creatinine 1–3 mg/dL, sodium 125–137 mEq/L, albumin 1.5–3.5 g/dL. If a patient recently received intravenous albumin, consider the MELD 3.0 score excluding serum albumin.
        """,
        equation: """
        MELD 3.0 = round(Sex + 4.56·ln(Bili) + 0.82·(137−Na) − 0.24·(137−Na)·ln(Bili) + 9.09·ln(INR) + 11.14·ln(Creat) + 1.85·(3.5−Alb) − 1.83·(3.5−Alb)·ln(Creat) + 6)
        Survival = 100 × C^e^(0.17698×MELD3 − 3.56)   where C = 0.981 (30 days), 0.963 (60 days), 0.946 (90 days)
        """,
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female (+1.33)", "Male (0)"])),
            MedCalcInput("bili", "Total Bilirubin", .number(unitHint: "mg/dL (µmol/L ÷ 17.1) (e.g. 2.5)")),
            MedCalcInput("creat", "Serum Creatinine", .number(unitHint: "mg/dL (µmol/L ÷ 88.4) (e.g. 1.2)")),
            MedCalcInput("inr", "INR", .number(unitHint: "ratio (e.g. 1.4)")),
            MedCalcInput("na", "Serum Sodium", .number(unitHint: "mEq/L = mmol/L (e.g. 135)")),
            MedCalcInput("alb", "Serum Albumin", .number(unitHint: "g/dL (g/L ÷ 10) (e.g. 3.2)"))
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let bili0 = v.number("bili"),
                  let creat0 = v.number("creat"), let inr0 = v.number("inr"),
                  let na0 = v.number("na"), let alb0 = v.number("alb") else { return "" }
            let bili = max(1, bili0)
            let creat = min(3, max(1, creat0))
            let inr = max(1, inr0)
            let na = min(137, max(125, na0))
            let alb = min(3.5, max(1.5, alb0))
            let sex = sexIdx == 0 ? 1.33 : 0.0
            let meld3 = Int((sex + 4.56 * log(bili) + 0.82 * (137 - na) - 0.24 * (137 - na) * log(bili)
                + 9.09 * log(inr) + 11.14 * log(creat) + 1.85 * (3.5 - alb) - 1.83 * (3.5 - alb) * log(creat) + 6).rounded())
            let expTerm = exp(0.17698 * Double(meld3) - 3.56)
            let s90 = 100 * pow(0.946, expTerm)
            let s60 = 100 * pow(0.963, expTerm)
            let s30 = 100 * pow(0.981, expTerm)
            return """
            MELD 3.0 Score: \(meld3)
            30-Day Survival Estimate: \(String(format: "%.1f", s30))%
            60-Day Survival Estimate: \(String(format: "%.1f", s60))%
            90-Day Survival Estimate: \(String(format: "%.1f", s90))%
            """
        }
    ),

    MedCalcSpec(
        fileName: "MELD.htm",
        guide: """
        MELD (Model for End-Stage Liver Disease) score, for adults 12 and older, estimates relative disease severity and likely survival of patients awaiting liver transplantation. Children under 12 should be assessed with the PELD score.

        If the patient has had 2 or more hemodialysis treatments or 24 hours of CVVHD in the week prior to scoring, creatinine is automatically set to 4 mg/dL (the model maximum). For hepatocellular carcinoma patients the score is increased per the UNOS algorithm; for 12–17-year-olds with a urea cycle disorder, organic acidemia, or hepatoblastoma it is set at 30.
        """,
        equation: "MELD Score = 10 × (0.957·ln(Creatinine) + 0.378·ln(Bilirubin) + 1.12·ln(INR)) + 6.43",
        inputs: [
            MedCalcInput("creat", "Serum Creatinine", .number(unitHint: "mg/dL (µmol/L ÷ 88.4) (e.g. 1.2)")),
            MedCalcInput("bili", "Total Bilirubin", .number(unitHint: "mg/dL (µmol/L ÷ 17.1) (e.g. 2.5)")),
            MedCalcInput("inr", "INR", .number(unitHint: "ratio (e.g. 1.4)")),
            MedCalcInput("dialysis", "≥2 Hemodialysis Sessions or ≥24 h CVVHD in Prior Week", .yesNo)
        ],
        compute: { v in
            guard let bili0 = v.number("bili"), let inr0 = v.number("inr") else { return "" }
            let creat: Double
            if (v.selection("dialysis") ?? 0) == 1 {
                creat = 4
            } else {
                guard let c0 = v.number("creat") else { return "" }
                creat = min(4, max(1, c0))
            }
            let bili = min(200, max(1, bili0))
            let inr = min(100, max(1, inr0))
            let score = Int((10 * (0.957 * log(creat) + 0.378 * log(bili) + 1.12 * log(inr)) + 6.43).rounded())
            return "MELD Score: \(score)"
        }
    ),

    MedCalcSpec(
        fileName: "Milan.htm",
        guide: """
        Milan criteria for liver transplantation eligibility in hepatocellular carcinoma (HCC). Select the tumor burden pattern that fits, and whether there is lymph-node or vascular invasion.
        """,
        inputs: [
            MedCalcInput("tumor", "Number and Size of HCC Tumors in the Liver", .choice(options: [
                "One tumor ≤5 cm in diameter (0 pts)",
                "Up to three tumors, each ≤3 cm in diameter (0 pts)",
                "More than three tumors (1 pt)",
                "Any tumor >5 cm in diameter (1 pt)"
            ])),
            MedCalcInput("nodes", "Tumor Invasion of Lymph Nodes", .choice(options: ["No (0 pts)", "Yes (1 pt)"])),
            MedCalcInput("vessels", "Tumor Invasion of Blood Vessels", .choice(options: ["No (0 pts)", "Yes (1 pt)"]))
        ],
        compute: { v in
            let score = (v.selection("tumor").map { [0, 0, 1, 1][$0 % 4] } ?? 0)
                + (v.selection("nodes") ?? 0) + (v.selection("vessels") ?? 0)
            let verdict = score == 0
                ? "Meets Milan criteria — transplantation may be considered"
                : "Does not meet Milan criteria — transplantation may be futile"
            return """
            Milan Criteria Score: \(score) points
            \(verdict)
            """
        }
    ),

    MedCalcSpec(
        fileName: "peldcr.htm",
        guide: """
        PELD-Cr score (2023 update) for end-stage liver disease in patients under 12 years old. Enter birth sex, age in months at the time of the measurements, weight and height, the most recent lab values, and dialysis status.

        Height and weight are converted to LMS z-scores using the reference tables (0–144.5 months); the score uses the minimum z-score (capped at −2.1). Enter age in months (up to 144); a higher PELD-Cr score indicates a worse prognosis.
        """,
        equation: """
        Z-score = ((value/M)^L − 1) / (L×S) per LMS table row, interpolated by age
        PELD-Cr = 10 × (−0.1967×Age + −1.842×ln(Alb) + BiliFactor + INRFactor − 0.1807×MZS + 1.453×ln(Creat) + 1.5287) + 2.82
        BiliFactor = 0.7854·ln(min(Bili,4)) + 0.3434·ln(max(Bili,4)); INRFactor = 1.981·ln(min(INR,2)) + 0.7298·ln(max(INR,2))
        """,
        inputs: [
            MedCalcInput("sex", "Birth Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age (at measurements/labs)", .number(unitHint: "months (0–144) (e.g. 60)")),
            MedCalcInput("wgt", "Weight", .number(unitHint: "kg (e.g. 18)")),
            MedCalcInput("hgt", "Height", .number(unitHint: "cm (e.g. 125)")),
            MedCalcInput("alb", "Serum Albumin", .number(unitHint: "g/dL (g/L ÷ 10) (e.g. 3.0)")),
            MedCalcInput("bili", "Total Bilirubin", .number(unitHint: "mg/dL (µmol/L ÷ 17.1) (e.g. 3)")),
            MedCalcInput("inr", "INR", .number(unitHint: "ratio (e.g. 1.8)")),
            MedCalcInput("creat", "Serum Creatinine", .number(unitHint: "mg/dL (µmol/L ÷ 88.4) (e.g. 0.5)")),
            MedCalcInput("hd", "Hemodialysis ×2 or ≥24 h CVVHD in Prior Week", .yesNo)
        ],
        compute: { v in
            guard let sexIdx = v.selection("sex"), let ageM = v.number("age"),
                  let wgt = v.number("wgt"), let hgt = v.number("hgt"),
                  let alb0 = v.number("alb"), let bili0 = v.number("bili"),
                  let inr0 = v.number("inr"), let creat0 = v.number("creat") else { return "" }
            guard ageM > 0, ageM <= 144 else { return "" }
            let female = sexIdx == 0
            let zH = MedCalcPeldcrData.zScore(table: female ? MedCalcPeldcrData.femaleHeight : MedCalcPeldcrData.maleHeight, ageMonths: ageM, value: hgt)
            let zW = MedCalcPeldcrData.zScore(table: female ? MedCalcPeldcrData.femaleWeight : MedCalcPeldcrData.maleWeight, ageMonths: ageM, value: wgt)
            let mzs = min(zH, zW)
            let age = min(5.5, max(1, ageM / 12))
            let alb = min(1.9, max(1, alb0))
            let bili = min(40, max(1, bili0))
            let inr = min(10, max(1, inr0))
            let creat: Double
            if (v.selection("hd") ?? 0) == 1 || creat0 > 1.3 { creat = 1.3 }
            else { creat = max(0.2, min(1.3, creat0)) }
            let mzsU = min(-2.1, max(-5, mzs))
            let biliFactor = 0.7854 * log(min(bili, 4)) + 0.3434 * log(max(bili, 4))
            let inrFactor = 1.981 * log(min(inr, 2)) + 0.7298 * log(max(inr, 2))
            let raw = 10 * (-0.1967 * age - 1.842 * log(alb) + biliFactor + inrFactor - 0.1807 * mzsU + 1.453 * log(creat) + 1.5287) + 2.82
            let score = max(6, Int(raw.rounded()))
            return """
            Height Z-score: \(String(format: "%.2f", zH))
            Weight Z-score: \(String(format: "%.2f", zW))
            PELD-Cr Score: \(score) (minimum 6; higher = worse prognosis)
            """
        }
    ),

    MedCalcSpec(
        fileName: "TipsRisk.htm",
        guide: """
        TIPS risk/survival predictor for patients undergoing transjugular intrahepatic portosystemic shunt (TIPS). Enter creatinine, total bilirubin, INR, the cause of liver disease, and the survival time point to estimate.
        """,
        equation: """
        RiskScore = 0.957·ln(Creat) + 0.378·ln(Bili) + 1.12·ln(INR) + 0.643·Cause
        Survival = DaysFactor ^ e^(RiskScore − 1.127)
        """,
        inputs: [
            MedCalcInput("creat", "Serum Creatinine", .number(unitHint: "mg/dL (µmol/L ÷ 88.4) (e.g. 1.4)")),
            MedCalcInput("bili", "Total Bilirubin", .number(unitHint: "mg/dL (µmol/L ÷ 17.1) (e.g. 4)")),
            MedCalcInput("inr", "INR", .number(unitHint: "ratio (e.g. 1.6)")),
            MedCalcInput("cause", "Cause of Liver Disease", .choice(options: ["Alcoholic or cholestatic (0)", "Viral or other liver disease (1)"])),
            MedCalcInput("days", "Estimate Survival At", .choice(options: [
                "1 day", "7 days", "30 days", "90 days", "6 months (183 d)", "1 year (365 d)", "2 years (730 d)"
            ]))
        ],
        compute: { v in
            guard let creat = v.number("creat"), let bili = v.number("bili"),
                  let inr = v.number("inr"), let causeIdx = v.selection("cause"),
                  let daysIdx = v.selection("days"),
                  creat > 0, bili > 0, inr > 0 else { return "" }
            let cause = causeIdx == 0 ? 0.0 : 1.0
            let daysFactors: [Double] = [0.990, 0.966, 0.860, 0.707, 0.621, 0.551, 0.428]
            let labels = ["1 day", "7 days", "30 days", "90 days", "6 months", "1 year", "2 years"]
            let daysIdxC = min(6, max(0, daysIdx))
            let risk = 0.957 * log(creat) + 0.378 * log(bili) + 1.12 * log(inr) + 0.643 * cause
            let survival = 100 * pow(daysFactors[daysIdxC], exp(risk - 1.127))
            return """
            TIPS Risk Score: \(String(format: "%.2f", risk))
            Estimated \(labels[daysIdxC]) survival: \(String(format: "%.1f", survival))%
            """
        }
    )
]

/// Platelet banding for the CDS platelet score (platelets in 10³/µL ≡ 10⁹/L).
private func cirrhosisPlateletScore(_ plt: Double) -> Int {
    if plt > 340 { return 0 }
    if plt >= 280 { return 1 }
    if plt >= 220 { return 2 }
    if plt >= 160 { return 3 }
    if plt >= 100 { return 4 }
    if plt >= 40 { return 5 }
    return 6
}
