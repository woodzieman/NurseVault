import Foundation

// Hematology calculator specs — formulas from the Merck Manual clinical-calculator sources.

let hematologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "AbsEoCount.htm",
        guide: """
        The absolute eosinophil count (AEC) converts the eosinophil percentage from a differential white blood cell (WBC) count into an absolute number.

        • WBC in ×10³/µL; eosinophils as a percent of the differential.
        • A normal AEC is roughly 0–0.4 ×10³/µL; higher values suggest eosinophilia (allergy, parasitic infection, hypereosinophilic syndrome).
        """,
        equation: "AEC = WBC × Eosinophils / 100",
        inputs: [
            MedCalcInput("wbc", "WBC count (×10³/µL)", .number(unitHint: "×10³/µL")),
            MedCalcInput("eos", "Eosinophil percentage (%)", .number(unitHint: "%"))
        ],
        compute: { v in
            guard let wbc = v.number("wbc"), let eos = v.number("eos") else { return "" }
            return String(format: "Absolute Eosinophil Count (AEC): %.2f ×10³/µL", wbc * eos / 100)
        }
    ),
    MedCalcSpec(
        fileName: "AbsLymphocyteCnt.htm",
        guide: """
        The absolute lymphocyte count (ALC) converts the lymphocyte percentage from a differential WBC count into an absolute number.

        • WBC in ×10³/µL; lymphocytes as a percent of the differential.
        • A normal ALC is roughly 1–4 ×10³/µL. Low values (lymphopenia) occur with immunosuppression, HIV, and severe infection; high values suggest viral infections or lymphoproliferative disorders.
        """,
        equation: "ALC = WBC × Lymphocytes / 100",
        inputs: [
            MedCalcInput("wbc", "WBC count (×10³/µL)", .number(unitHint: "×10³/µL")),
            MedCalcInput("lymphs", "Lymphocyte percentage (%)", .number(unitHint: "%"))
        ],
        compute: { v in
            guard let wbc = v.number("wbc"), let lymphs = v.number("lymphs") else { return "" }
            return String(format: "Absolute Lymphocyte Count (ALC): %.2f ×10³/µL", wbc * lymphs / 100)
        }
    ),
    MedCalcSpec(
        fileName: "AbsNeutrophileCnt.htm",
        guide: """
        The absolute neutrophil count (ANC) combines segmented neutrophils and bands from a differential WBC count.

        • WBC in ×10³/µL; enter the segment and band percentages separately.
        • ANC <1.5 ×10³/µL = neutropenia; <0.5 ×10³/µL = severe (agranulocytosis) — high infection risk, often requires urgent management.
        """,
        equation: "ANC = WBC × ((Segs + Bands) / 100)",
        inputs: [
            MedCalcInput("wbc", "WBC count (×10³/µL)", .number(unitHint: "×10³/µL")),
            MedCalcInput("segs", "Segmented neutrophils (%)", .number(unitHint: "%")),
            MedCalcInput("bands", "Bands (%)", .number(unitHint: "%"))
        ],
        compute: { v in
            guard let wbc = v.number("wbc"), let segs = v.number("segs"), let bands = v.number("bands") else { return "" }
            return String(format: "Absolute Neutrophil Count (ANC): %.2f ×10³/µL", wbc * (segs + bands) / 100)
        }
    ),
    MedCalcSpec(
        fileName: "AbsReticCnt.htm",
        guide: """
        The absolute reticulocyte count (ARC) estimates marrow red-cell output.

        • Reticulocyte percentage from the CBC; hematocrit in %.
        • A normal ARC is roughly 0.02–0.1 ×10⁶/µL. Compare with the reticulocyte production index to judge whether the response is adequate for the degree of anemia.
        """,
        equation: "ARC = Reticulocytes (%) × Hct / 45",
        inputs: [
            MedCalcInput("reticPct", "Reticulocyte percentage (%)", .number(unitHint: "%")),
            MedCalcInput("hct", "Hematocrit (%)", .number(unitHint: "%"))
        ],
        compute: { v in
            guard let retic = v.number("reticPct"), let hct = v.number("hct") else { return "" }
            return String(format: "Absolute Reticulocyte Count (ARC): %.4f ×10⁶/µL", retic * hct / 45)
        }
    ),
    MedCalcSpec(
        fileName: "plasmic.htm",
        guide: """
        The PLASMIC score estimates the likelihood of severe ADAMTS13 deficiency (the cause of thrombotic thrombocytopenic purpura, TTP) in adults with suspected TTP. Check each criterion that applies — 1 point per box.

        • Platelet count <30,000/µL
        • One or more indicators of hemolysis: reticulocyte count >2.5%, undetectable haptoglobin, or indirect bilirubin >2.0 mg/dL
        • No active cancer in the preceding year
        • No history of solid organ or hematopoietic stem cell transplant
        • Mean corpuscular volume (MCV) <90 fL
        • International normalized ratio (INR) <1.5
        • Creatinine <2.0 mg/dL

        Interpretation: 0–4 low risk; 5 intermediate risk; 6–7 high risk of severe ADAMTS13 deficiency. A high score supports urgent plasma exchange while confirmatory testing is pending.
        """,
        inputs: [
            MedCalcInput("plateletsLow", "Platelet count <30,000/µL", .yesNo),
            MedCalcInput("hemolysis", "One or more indicators of hemolysis (reticulocytes >2.5%, undetectable haptoglobin, or indirect bilirubin >2.0 mg/dL)", .yesNo),
            MedCalcInput("noCancer", "No active cancer in the preceding year", .yesNo),
            MedCalcInput("noTransplant", "No history of solid organ or hematopoietic stem cell transplant", .yesNo),
            MedCalcInput("mcvLow", "Mean corpuscular volume (MCV) <90 fL", .yesNo),
            MedCalcInput("inrLow", "International normalized ratio (INR) <1.5", .yesNo),
            MedCalcInput("creatinineLow", "Creatinine <2.0 mg/dL (<177 µmol/L)", .yesNo)
        ],
        compute: { v in
            let score = ["plateletsLow", "hemolysis", "noCancer", "noTransplant", "mcvLow", "inrLow", "creatinineLow"]
                .compactMap { v.selection($0) }.reduce(0, +)
            let risk: String
            switch score {
            case 0...4: risk = "Low risk"
            case 5: risk = "Intermediate risk"
            default: risk = "High risk"
            }
            return "PLASMIC Score: \(score)/7 — Risk of severe ADAMTS13 deficiency: \(risk)"
        }
    ),
    MedCalcSpec(
        fileName: "HIT.htm",
        guide: """
        The 4 T's score estimates the pretest probability of heparin-induced thrombocytopenia (HIT). Score each category, then sum.

        • Thrombocytopenia — size and timing of the platelet fall
        • Timing — when the fall began relative to heparin exposure
        • Thrombosis or other sequelae — new clotting, skin necrosis, or systemic reaction
        • Other causes for thrombocytopenia — how likely an alternative explanation is

        Interpretation: 0–3 low probability; 4–5 intermediate probability; 6–8 high probability. In a high-probability patient, stop heparin and send HIT antibody testing (PF4/heparin ELISA ± serotonin release assay).
        """,
        inputs: [
            MedCalcInput("thrombocytopenia", "Thrombocytopenia", .score(options: [
                ">50% fall AND nadir ≥20,000/µL (2 pts)",
                "30–50% fall OR nadir 10,000–19,000/µL (1 pt)",
                "<30% fall OR nadir <10,000/µL (0 pts)"
            ])),
            MedCalcInput("timing", "Timing of platelet count fall", .score(options: [
                "Clear onset days 5–10 after heparin start, or ≤1 day with prior heparin exposure <30 days ago (2 pts)",
                "Onset consistent with days 5–10 but unclear, or >10 days, or ≤1 day with prior heparin 30–100 days ago (1 pt)",
                "<4 days after start without recent heparin exposure (0 pts)"
            ])),
            MedCalcInput("thrombosis", "Thrombosis or other sequelae", .score(options: [
                "Confirmed new thrombosis, skin necrosis at injection sites, or acute systemic reaction after a platelet transfusion (2 pts)",
                "Progressive/recurrent thrombosis or non-necrotizing skin lesions (1 pt)",
                "None of these (0 pts)"
            ])),
            MedCalcInput("otherCauses", "Other causes for thrombocytopenia present", .score(options: [
                "No other cause apparent (2 pts)",
                "Possible alternative cause (1 pt)",
                "Definite alternative cause (0 pts)"
            ]))
        ],
        compute: { v in
            guard let t = v.selection("thrombocytopenia"),
                  let ti = v.selection("timing"),
                  let th = v.selection("thrombosis"),
                  let o = v.selection("otherCauses") else { return "" }
            // Options are ordered 2 pts, 1 pt, 0 pts.
            let score = (2 - t) + (2 - ti) + (2 - th) + (2 - o)
            let probability: String
            switch score {
            case 0...3: probability = "Low probability"
            case 4...5: probability = "Intermediate probability"
            default: probability = "High probability"
            }
            return "HIT 4 T's Score: \(score)/8 — \(probability)"
        }
    ),
    MedCalcSpec(
        fileName: "ReticProdIndex.htm",
        guide: """
        The reticulocyte production index (RPI) corrects the reticulocyte percentage for the degree of anemia and the extra time immature reticulocytes spend in circulation.

        • Hematocrit in %; reticulocyte percentage from the CBC.
        • Maturation factor by hematocrit: ≥40 → 1.0; 30–39 → 1.5; 20–29 → 2.0; <20 → 2.5.
        • RPI >3 indicates an appropriate marrow response to anemia (hemolysis or blood loss); ≤2 suggests inadequate production (e.g., aplastic crisis, marrow failure).
        """,
        equation: "RPI = (Hct / 45) × Reticulocytes (%) / Maturation factor",
        inputs: [
            MedCalcInput("hct", "Hematocrit (%)", .number(unitHint: "%")),
            MedCalcInput("retic", "Reticulocyte percentage (%)", .number(unitHint: "%"))
        ],
        compute: { v in
            guard let hct = v.number("hct"), let retic = v.number("retic") else { return "" }
            let maturation: Double
            switch hct {
            case 40...: maturation = 1.0
            case 30..<40: maturation = 1.5
            case 20..<30: maturation = 2.0
            default: maturation = 2.5
            }
            return String(format: "Reticulocyte Production Index (RPI): %.2f (maturation factor %.1f)", hct / 45 * retic / maturation, maturation)
        }
    )
]
