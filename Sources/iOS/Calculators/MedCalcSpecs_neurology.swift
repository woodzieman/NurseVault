import Foundation

/// Calculator specs for the neurology category.
let neurologyCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "GlasgowComaScale.htm",
        guide: """
        The Glasgow Coma Scale (GCS) grades consciousness after brain injury or altered mental status. Assess the three components and select the BEST response in each — do not sum all responses seen, only the best of each category.

        Interpretation — total out of 15:
        • 15: Normal
        • 3–14: Abnormal (≤8 is severe traumatic brain injury; a GCS ≤8 generally indicates need for airway protection)
        """,
        inputs: [
            MedCalcInput("eye", "Eye Opening", .score(options: ["Spontaneous (4)", "To verbal command (3)", "To pain (2)", "None (1)"])),
            MedCalcInput("motor", "Best Motor Response", .score(options: ["Obeys verbal command (6)", "Localizes painful stimuli (5)", "Flexion withdrawal from painful stimuli (4)", "Decorticate response to painful stimuli (3)", "Decerebrate response to painful stimuli (2)", "None (1)"])),
            MedCalcInput("verbal", "Best Verbal Response", .score(options: ["Oriented conversation (5)", "Disoriented conversation (4)", "Inappropriate words (3)", "Incomprehensible words (3)", "Incomprehensible sounds (2)", "None (1)"]))
        ],
        compute: { v in
            guard let eye = v.selection("eye"), let motor = v.selection("motor"), let verbal = v.selection("verbal") else { return "" }
            let points = [4, 3, 2, 1]
            let mPoints = [6, 5, 4, 3, 2, 1]
            let vPoints = [5, 4, 3, 3, 2, 1]
            let total = points[eye] + mPoints[motor] + vPoints[verbal]
            let interpretation = total == 15 ? "Normal" : "Abnormal"
            return String(format: "GCS: %d/15 (E%d V%d M%d)\n%@", total, points[eye], vPoints[verbal], mPoints[motor], interpretation)
        }
    ),

    MedCalcSpec(
        fileName: "clockdrawing.htm",
        guide: """
        The Clock Drawing Test screens for cognitive impairment. Ask the patient to draw a clock face with the hands showing a specific time (e.g., 11 o'clock). Award one point for each criterion met — all four must be present for a normal score.

        Interpretation:
        • 4 points: No obvious impairment
        • 1–3 points: Possible cognitive impairment — consider further neuropsychological evaluation
        """,
        inputs: [
            MedCalcInput("circle", "Draws closed circle (1 point)", .yesNo),
            MedCalcInput("position", "Draws numbers in correct position (1 point)", .yesNo),
            MedCalcInput("alltwelve", "Correctly includes all 12 numbers (1 point)", .yesNo),
            MedCalcInput("hands", "Draws hands in correct position asked by examiner (1 point)", .yesNo)
        ],
        compute: { v in
            let ids = ["circle", "position", "alltwelve", "hands"]
            guard ids.allSatisfy({ v.selection($0) != nil }) else { return "" }
            let score = ids.reduce(0) { $0 + (v.selection($1) ?? 0) }
            let interpretation = score == 4 ? "No obvious impairment" : "Possible cognitive impairment — consider further evaluation"
            return String(format: "CDT Score: %d/4\n%@", score, interpretation)
        }
    ),

    MedCalcSpec(
        fileName: "IntracranialBleedingRiskThrombolytics.htm",
        guide: """
        Predicts the risk of intracranial hemorrhage from thrombolytic therapy in elderly patients with acute myocardial infarction (Brass 2000). Answer yes/no to each of the eight criteria.

        Interpretation — total score and observed cerebral bleeding risk:
        • 0–1 point: 0.69% risk
        • 2 points: 1.02% risk
        • 3 points: 1.63% risk
        • 4 points: 2.49% risk
        • 5–8 points: 4.11% risk
        """,
        inputs: [
            MedCalcInput("age75", "Patient 75 years old or older (1 point)", .yesNo),
            MedCalcInput("blackrace", "Patient of Black race (1 point)", .yesNo),
            MedCalcInput("female", "Patient is female (1 point)", .yesNo),
            MedCalcInput("priorstroke", "Prior history of stroke (1 point)", .yesNo),
            MedCalcInput("sbp160", "Systolic BP ≥160 mmHg (1 point)", .yesNo),
            MedCalcInput("lowweight", "Body weight ≤65 kg for women, ≤80 kg for men (1 point)", .yesNo),
            MedCalcInput("inr4", "INR >4 or prothrombin time >24 seconds (1 point)", .yesNo),
            MedCalcInput("tpa", "TPA used instead of another thrombolytic (1 point)", .yesNo)
        ],
        compute: { v in
            let ids = ["age75", "blackrace", "female", "priorstroke", "sbp160", "lowweight", "inr4", "tpa"]
            guard ids.allSatisfy({ v.selection($0) != nil }) else { return "" }
            let score = ids.reduce(0) { $0 + (v.selection($1) ?? 0) }
            let risk: String
            switch score {
            case ...1: risk = "0.69% Risk"
            case 2: risk = "1.02% Risk"
            case 3: risk = "1.63% Risk"
            case 4: risk = "2.49% Risk"
            default: risk = "4.11% Risk"
            }
            return String(format: "Risk of Cerebral Bleeding: %d/8 points\n%@", score, risk)
        }
    ),

    MedCalcSpec(
        fileName: "NIHStrokeScore.htm",
        guide: """
        The NIH Stroke Scale (NIHSS) is the standard bedside assessment of stroke severity — administer it exactly as trained, item by item, and record the worst deficit for each. Select the response that matches the patient for every item; untestable limbs are scored 0 per the source form.

        Interpretation (general): ≤4 minor stroke, 5–14 moderate, ≥15 severe — a rising score between exams suggests clinical deterioration.
        """,
        inputs: [
            MedCalcInput("loc", "Level of Consciousness", .score(options: ["Alert (0)", "Not alert, but arousable with minimal stimulation (1)", "Not alert, requires repeated stimulation to attend (2)", "Coma (3)"])),
            MedCalcInput("monthage", "Patient knows month and own age", .score(options: ["Answers both correctly (0)", "Answers one correctly (1)", "Both incorrect (2)"])),
            MedCalcInput("eyeopen", "Patient opens and closes eyes on command", .score(options: ["Obeys both correctly (0)", "Obeys one correctly (1)", "Both incorrect (2)"])),
            MedCalcInput("gaze", "Best Gaze (only horizontal eye movement)", .score(options: ["Normal (0)", "Partial gaze palsy (1)", "Forced deviation (2)"])),
            MedCalcInput("visual", "Visual Field testing", .score(options: ["No visual field loss (0)", "Partial hemianopia (1)", "Complete hemianopia (2)", "Bilateral hemianopia / cortical blindness (3)"])),
            MedCalcInput("face", "Facial Paresis (show teeth, raise eyebrows, close eyes)", .score(options: ["Normal symmetrical movement (0)", "Minor paralysis (1)", "Partial paralysis of lower face (2)", "Complete paralysis of one or both sides (3)"])),
            MedCalcInput("armr", "Motor Function of Right Arm", .score(options: ["Normal (0)", "Drift (1)", "Some effort against gravity (2)", "No effort against gravity (3)", "No movement (4)", "Untestable * (0)"])),
            MedCalcInput("arml", "Motor Function of Left Arm", .score(options: ["Normal (0)", "Drift (1)", "Some effort against gravity (2)", "No effort against gravity (3)", "No movement (4)", "Untestable * (0)"])),
            MedCalcInput("legr", "Motor Function of Right Leg", .score(options: ["Normal (0)", "Drift (1)", "Some effort against gravity (2)", "No effort against gravity (3)", "No movement (4)", "Untestable * (0)"])),
            MedCalcInput("legl", "Motor Function of Left Leg", .score(options: ["Normal (0)", "Drift (1)", "Some effort against gravity (2)", "No effort against gravity (3)", "No movement (4)", "Untestable * (0)"])),
            MedCalcInput("ataxia", "Limb Ataxia", .score(options: ["None (0)", "One limb (1)", "Two limbs (2)"])),
            MedCalcInput("sensory", "Sensory by Pinprick", .score(options: ["Normal (0)", "Mild to moderate decrease in sensation (1)", "Severe to total sensory loss (2)"])),
            MedCalcInput("language", "Language", .score(options: ["No aphasia (0)", "Mild–moderate aphasia (1)", "Severe aphasia (2)", "No speech production (3)"])),
            MedCalcInput("dysarthria", "Dysarthria", .score(options: ["None (0)", "Mild–moderate slurring (1)", "Severe (2)", "Intubated or other physical impediment to testing (0)"])),
            MedCalcInput("extinction", "Extinction and Inattention", .score(options: ["Normal (0)", "Inattention/extinction in one sensory modality (1)", "Severe hemi-inattention or >1 modality (2)"]))
        ],
        compute: { v in
            let ids = ["loc", "monthage", "eyeopen", "gaze", "visual", "face", "armr", "arml", "legr", "legl", "ataxia", "sensory", "language", "dysarthria", "extinction"]
            // Points per option index; untestable/impediment options score 0.
            let tables: [[Int]] = [
                [0, 1, 2, 3],          // level of consciousness
                [0, 1, 2],              // month and age
                [0, 1, 2],              // eye opening on command
                [0, 1, 2],              // best gaze
                [0, 1, 2, 3],           // visual field
                [0, 1, 2, 3],           // facial paresis
                [0, 1, 2, 3, 4, 0],     // right arm (last = untestable)
                [0, 1, 2, 3, 4, 0],     // left arm (last = untestable)
                [0, 1, 2, 3, 4, 0],     // right leg (last = untestable)
                [0, 1, 2, 3, 4, 0],     // left leg (last = untestable)
                [0, 1, 2],              // limb ataxia
                [0, 1, 2],              // sensory
                [0, 1, 2, 3],           // language
                [0, 1, 2, 0],           // dysarthria (last = intubated/impediment)
                [0, 1, 2]               // extinction and inattention
            ]
            guard ids.allSatisfy({ v.selection($0) != nil }) else { return "" }
            var total = 0
            for (i, id) in ids.enumerated() {
                total += tables[i][v.selection(id)!]
            }
            return String(format: "NIH Stroke Score: %d/42", total)
        }
    ),

    MedCalcSpec(
        fileName: "CSFProtein.htm",
        guide: """
        Corrects CSF protein for a traumatic (bloody) tap. Enter the CSF and serum protein, the patient's hematocrit, and both RBC counts — the calculator subtracts the protein contributed by blood contamination from the measured CSF value.

        Interpretation: normal CSF total protein is about 15–45 mg/dL; a corrected value back in range suggests the elevation was due to the bloody tap rather than true inflammation.
        """,
        equation: "Corrected = ProteinCSF − (ProteinSerum × 1000) × (1 − HCT/100) × RBC_CSF / (RBC_Blood × 10⁶)",
        inputs: [
            MedCalcInput("csfprotein", "Protein CSF (mg/dL)", .number(unitHint: "mg/dL")),
            MedCalcInput("serumprotein", "Protein Serum (g/dL)", .number(unitHint: "g/dL")),
            MedCalcInput("hct", "Hematocrit (%)", .number(unitHint: "%")),
            MedCalcInput("rbccsf", "RBC CSF (/mm³ = /µL)", .number(unitHint: "cells/µL")),
            MedCalcInput("rbcblood", "RBC Blood (million/mm³)", .number(unitHint: "×10⁶ cells/mm³"))
        ],
        compute: { v in
            guard let csf = v.number("csfprotein"), let serum = v.number("serumprotein"),
                  let hct = v.number("hct"), let rbcCsf = v.number("rbccsf"),
                  let rbcBlood = v.number("rbcblood"), rbcBlood > 0, hct >= 0, hct <= 100 else { return "" }
            let corrected = csf - (serum * 1000) * (1 - hct / 100) * rbcCsf / (rbcBlood * 1e6)
            return String(format: "Corrected CSF Protein: %.1f mg/dL\n(measured %.1f, corrected for blood contamination)", corrected, csf)
        }
    )
]
