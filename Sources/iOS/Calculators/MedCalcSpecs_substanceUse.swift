import Foundation

/// Calculator specs for the substanceUse category.
let substanceUseCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "CIWA.htm",
        guide: """
        The CIWA-Ar scale quantifies alcohol withdrawal severity to guide benzodiazepine dosing and disposition decisions. Assess the patient at regular intervals (commonly every 1–4 hours); score each item by observation and interview using the options shown, then sum all items.

        Interpretation — total score out of 67:
        • 0–9: Very mild withdrawal
        • 10–15: Mild withdrawal
        • 16–20: Modest (moderate) withdrawal
        • 21–67: Severe withdrawal — high risk for seizures and delirium tremens; consider inpatient monitoring

        Note: the source leaves some intermediate levels unlabeled; those options use standard graded-severity wording between the described anchors.
        """,
        inputs: {
            let nausea = [
                "No nausea and no vomiting (0)",
                "Mild nausea with no vomiting (1)",
                "Moderate nausea with no vomiting (2)",
                "Severe nausea with occasional vomiting (3)",
                "Intermittent nausea with dry heaves (4)",
                "Frequent nausea with dry heaves and occasional vomiting (5)",
                "Constant nausea, frequent dry heaves (6)",
                "Constant nausea, frequent dry heaves, and vomiting (7)"
            ]
            let tremor = [
                "No tremor (0)",
                "Not visible, but can be felt fingertip to fingertip (1)",
                "Mild tremor with arms extended (2)",
                "Moderate tremor with arms extended (3)",
                "Moderate, with patient's arms extended (4)",
                "Marked tremor with arms extended (5)",
                "Severe tremor with arms extended (6)",
                "Severe, even with arms not extended (7)"
            ]
            let sweats = [
                "No sweat visible (0)",
                "Barely perceptible sweating, palms moist (1)",
                "Mild sweating on forehead and neck (2)",
                "Moderate sweating on face and body (3)",
                "Beads of sweat obvious on forehead (4)",
                "Profuse sweating over most of the body (5)",
                "Heavy drenching sweats (6)",
                "Drenching sweats (7)"
            ]
            let anxiety = [
                "No anxiety, at ease (0)",
                "Mildly anxious (1)",
                "Moderately anxious (2)",
                "Markedly anxious or guarded (3)",
                "Moderately anxious, or guarded, so anxiety is inferred (4)",
                "Severely anxious and agitated (5)",
                "Near-panic anxiety with agitation (6)",
                "Equivalent to acute panic states as seen in severe delirium or acute schizophrenic reactions (7)"
            ]
            let agitation = [
                "Normal activity (0)",
                "Somewhat more than normal activity (1)",
                "Mildly fidgety and restless (2)",
                "Moderately fidgety and restless (3)",
                "Moderately fidgety and restless (4)",
                "Markedly restless, unable to sit still (5)",
                "Severe agitation, pacing most of the interview (6)",
                "Paces back and forth during most of the interview, or constantly thrashes about (7)"
            ]
            let tactile = [
                "None (0)",
                "Very mild itching, pins and needles, burning or numbness (1)",
                "Mild itching, pins and needles, burning or numbness (2)",
                "Moderate itching, pins and needles, burning or numbness (3)",
                "Moderately severe hallucinations (4)",
                "Severe hallucinations (5)",
                "Extremely severe hallucinations (6)",
                "Continuous hallucinations (7)"
            ]
            let auditory = [
                "Not present (0)",
                "Very mild harshness or ability to frighten (1)",
                "Mild harshness or ability to frighten (2)",
                "Moderate harshness or ability to frighten (3)",
                "Moderately severe hallucinations (4)",
                "Severe hallucinations (5)",
                "Extremely severe hallucinations (6)",
                "Continuous hallucinations (7)"
            ]
            let visual = [
                "Not present (0)",
                "Very mild sensitivity (1)",
                "Mild sensitivity (2)",
                "Moderate sensitivity (3)",
                "Moderately severe hallucinations (4)",
                "Severe hallucinations (5)",
                "Extremely severe hallucinations (6)",
                "Continuous hallucinations (7)"
            ]
            let headache = [
                "Not present (0)",
                "Very mild (1)",
                "Mild (2)",
                "Moderate (3)",
                "Moderately severe (4)",
                "Severe (5)",
                "Very severe (6)",
                "Extremely severe (7)"
            ]
            let orientation = [
                "Oriented and can do serial additions (0)",
                "Cannot do serial additions or is uncertain about date (1)",
                "Disoriented for date by no more than two calendar days (2)",
                "Disoriented for date by more than two calendar days (3)",
                "Disoriented for place and/or person (4)"
            ]
            return [
                MedCalcInput("q1", "Nausea and vomiting — ask: “Do you feel sick to your stomach? Have you vomited?”", .score(options: nausea)),
                MedCalcInput("q2", "Tremor — arms extended, fingers spread apart; observe", .score(options: tremor)),
                MedCalcInput("q3", "Paroxysmal sweats — observe", .score(options: sweats)),
                MedCalcInput("q4", "Anxiety — ask: “Do you feel nervous?” and observe", .score(options: anxiety)),
                MedCalcInput("q5", "Agitation — observe activity level", .score(options: agitation)),
                MedCalcInput("q6", "Tactile disturbances — itching, pins/needles, burning, numbness, bugs crawling on skin", .score(options: tactile)),
                MedCalcInput("q7", "Auditory disturbances — sounds harsh or frightening; hearing things not there", .score(options: auditory)),
                MedCalcInput("q8", "Visual disturbances — light too bright/hurts eyes; seeing things not there", .score(options: visual)),
                MedCalcInput("q9", "Headache/fullness in head (do not rate dizziness or lightheadedness)", .score(options: headache)),
                MedCalcInput("q10", "Orientation and clouding of sensorium — ask date, place, person; count forward by three", .score(options: orientation))
            ]
        }(),
        compute: { v in
            let ids = ["q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10"]
            guard ids.allSatisfy({ v.selection($0) != nil }) else { return "" }
            let total = ids.reduce(0) { $0 + (v.selection($1) ?? 0) }
            let severity: String
            switch total {
            case ...9: severity = "Very mild withdrawal"
            case 10...15: severity = "Mild withdrawal"
            case 16...20: severity = "Modest (moderate) withdrawal"
            default: severity = "Severe withdrawal — high risk for seizures/delirium tremens; consider inpatient monitoring"
            }
            return "CIWA-Ar Score: \(total)/67\n\(severity)"
        }
    )
]
