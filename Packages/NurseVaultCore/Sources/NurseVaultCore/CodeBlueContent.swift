import Foundation

/// A single drug dose used during a resuscitation algorithm.
public struct CodeBlueDrugDose: Hashable, Sendable {
    public let name: String
    public let dose: String
    public let route: String
    public let note: String?

    public init(name: String, dose: String, route: String, note: String? = nil) {
        self.name = name
        self.dose = dose
        self.route = route
        self.note = note
    }
}

/// One resuscitation algorithm — ACLS for adults or PALS for pediatrics —
/// with its care steps and the drug dosing used during the algorithm.
public struct CodeBlueAlgorithm: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let steps: [String]
    public let drugs: [CodeBlueDrugDose]

    public init(
        id: String,
        title: String,
        summary: String,
        steps: [String],
        drugs: [CodeBlueDrugDose]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.steps = steps
        self.drugs = drugs
    }

    /// The plain-text body used for the built-in vault document seeded into
    /// the "Code Blue" section.
    public var documentBody: String {
        var lines: [String] = [title, "", summary, "", "Algorithm:"]
        steps.enumerated().forEach { index, step in
            lines.append("\(index + 1). \(step)")
        }
        lines.append("")
        lines.append("Drug Doses:")
        drugs.forEach { drug in
            var line = "- \(drug.name): \(drug.dose) \(drug.route)"
            if let note = drug.note, !note.isEmpty {
                line += " — \(note)"
            }
            lines.append(line)
        }
        lines.append("")
        lines.append("Source: American Heart Association. Guidelines for CPR and ECC (2025).")
        return lines.joined(separator: "\n")
    }
}

/// The built-in Code Blue resuscitation content: the ACLS and PALS algorithms
/// with the drug dosing used during those algorithms.
///
/// Plain text on purpose — the Library seeds this into the user's "Code Blue"
/// vault section as built-in documents, so the content travels through the same
/// offline-first vault (and private CloudKit sync) as everything else.
public enum CodeBlueContent {

    /// Adult Advanced Life Support for cardiac arrest.
    public static let adultACLS = CodeBlueAlgorithm(
        id: "acls-adult",
        title: "ACLS Algorithm — Adult Cardiac Arrest",
        summary: "2025 American Heart Association adult advanced life support for cardiac arrest: high-quality CPR, defibrillation for shockable rhythms, and vasopressor therapy.",
        steps: [
            "Start high-quality CPR: begin bag-mask ventilation with oxygen and attach the cardiac monitor/defibrillator.",
            "Confirm the rhythm; if shockable (VF/pVT), defibrillate. Use a single-shock approach with immediate CPR rather than stacked shocks.",
            "Perform CPR for 2 minutes, then check the rhythm. Give IV/IO access. Give epinephrine 1 mg every 3 to 5 minutes. Consider an advanced airway and capnography.",
            "If the rhythm remains shockable, defibrillate and repeat the 2-minute CPR cycle with epinephrine every 3 to 5 minutes.",
            "For refractory VF/pVT after repeated defibrillation, amiodarone or lidocaine may be considered.",
            "For asystole or PEA, give epinephrine as soon as feasible; give epinephrine every 3 to 5 minutes.",
            "For an advanced airway, provide continuous compressions with 1 breath every 6 seconds; confirm placement with capnography."
        ],
        drugs: [
            CodeBlueDrugDose(
                name: "Epinephrine",
                dose: "1 mg",
                route: "IV/IO",
                note: "Give during cardiac arrest; in nonshockable rhythms as soon as feasible, in shockable rhythms after initial defibrillation attempts fail. Give every 3 to 5 minutes. Do not use high-dose epinephrine routinely; vasopressin is not a substitute for epinephrine."
            ),
            CodeBlueDrugDose(
                name: "Amiodarone",
                dose: "300 mg IV bolus, then 150 mg IV",
                route: "IV",
                note: "For refractory VF/pVT; or lidocaine 1 to 1.5 mg/kg IV then 0.5 to 0.75 mg/kg IV."
            ),
            CodeBlueDrugDose(
                name: "Lidocaine",
                dose: "1 to 1.5 mg/kg IV bolus, then 0.5 to 0.75 mg/kg IV",
                route: "IV",
                note: "Alternative to amiodarone for refractory shockable rhythms."
            ),
            CodeBlueDrugDose(
                name: "Atropine",
                dose: "1 mg IV bolus",
                route: "IV",
                note: "Repeat every 3 to 5 minutes; maximum total dose 3 mg."
            )
        ]
    )

    /// Pediatric Advanced Life Support for cardiac arrest.
    public static let pediatricPALS = CodeBlueAlgorithm(
        id: "pals-pediatric",
        title: "PALS Algorithm — Pediatric Cardiac Arrest",
        summary: "2025 American Heart Association pediatric advanced life support for infants and children in cardiac arrest: weight-based defibrillation dosing and epinephrine-based vasopressor therapy.",
        steps: [
            "Start age- and weight-appropriate high-quality CPR; begin bag-mask ventilation with oxygen and attach the cardiac monitor/defibrillator.",
            "For a shockable rhythm, deliver the first shock at 2 J/kg; subsequent shocks at 4 J/kg, not exceeding 10 J/kg or the adult dose.",
            "Perform CPR for 2 minutes, then check the rhythm. Give IV/IO access. Give epinephrine 0.01 mg/kg IV/IO every 3 to 5 minutes. Consider an advanced airway and capnography.",
            "If the rhythm remains shockable, deliver further shocks per the dosing sequence.",
            "For refractory shockable rhythms, give amiodarone 5 mg/kg IV/IO or lidocaine 1 mg/kg IV/IO.",
            "For asystole or PEA, give epinephrine as soon as feasible; give epinephrine every 3 to 5 minutes.",
            "For an advanced airway, provide continuous compressions with age-based breaths every 2 to 3 seconds."
        ],
        drugs: [
            CodeBlueDrugDose(
                name: "Epinephrine",
                dose: "0.01 mg/kg IV/IO (0.1 mg/mL concentration), maximum 1 mg",
                route: "IV/IO",
                note: "Give every 3 to 5 minutes; endotracheal dose 0.1 mg/kg if an endotracheal tube is in place. For symptomatic bradycardia, initial dose 0.1 mg/kg, repeat at 0.2 mg/kg."
            ),
            CodeBlueDrugDose(
                name: "Amiodarone",
                dose: "5 mg/kg IV/IO bolus, maximum 300 mg",
                route: "IV/IO",
                note: "May repeat for pulseless VT or refractory rhythms; or lidocaine 1 mg/kg IV/IO."
            ),
            CodeBlueDrugDose(
                name: "Lidocaine",
                dose: "1 mg/kg IV/IO",
                route: "IV/IO",
                note: "Alternative to amiodarone for refractory shockable rhythms."
            ),
            CodeBlueDrugDose(
                name: "Atropine",
                dose: "0.02 mg/kg IV/IO, minimum 0.1 mg, maximum single dose 0.5 mg",
                route: "IV/IO",
                note: "Repeat once for symptomatic bradycardia."
            )
        ]
    )

    /// Adult respiratory distress evaluation and management.
    public static let respiratoryDistress = CodeBlueAlgorithm(
        id: "respiratory-distress",
        title: "Respiratory Distress — Adult",
        summary: "Systematic approach to the acutely dyspneic adult: rapid triage, oxygenation, and targeted therapy based on the most likely cause (COPD, asthma, CHF, pneumonia, PE, anaphylaxis, tension pneumothorax).",
        steps: [
            "Immediate assessment: airway patency, respiratory rate, oxygen saturation, mental status, work of breathing (retractions, accessory muscles).",
            "Apply oxygen to maintain SpO2 92-96%. Consider BiPAP for COPD exacerbation or cardiogenic pulmonary edema.",
            "Obtain IV access and place cardiac monitor. Draw stat ABG/VBG if indicated.",
            "COPD exacerbation: nebulized albuterol/ipratropium; systemic corticosteroids (methylprednisolone 40-60 mg IV or prednisone 40-50 mg PO).",
            "Asthma exacerbation: nebulized albuterol 2.5 mg (repeat q20min x3); magnesium sulfate 2 g IV; systemic corticosteroids.",
            "Cardiogenic pulmonary edema: BiPAP; IV furosemide 40 mg; nitroglycerin spray 0.4 mg SL (repeat q5min, max 3 if SBP > 100).",
            "Anaphylaxis: IM epinephrine 0.3-0.5 mg anterolateral thigh; IV fluids 1-2 L crystalloid.",
            "Tension pneumothorax: immediate needle decompression 5th ICS midclavicular line; follow with tube thoracostomy.",
            "PE suspected: D-dimer if low probability; CT angiography if high probability; anticoagulate if confirmed."
        ],
        drugs: [
            CodeBlueDrugDose(
                name: "Oxygen",
                dose: "Titrate to SpO2 92-96%",
                route: "Various",
                note: "Target 88-92% in known COPD with chronic CO2 retention."
            ),
            CodeBlueDrugDose(
                name: "Albuterol",
                dose: "2.5 mg",
                route: "Nebulized",
                note: "Repeat q20min x3 for asthma/COPD. Add ipratropium 0.5 mg. Continuous nebulization for severe cases."
            ),
            CodeBlueDrugDose(
                name: "Ipratropium",
                dose: "0.5 mg",
                route: "Nebulized",
                note: "Combine with albuterol for COPD exacerbation."
            ),
            CodeBlueDrugDose(
                name: "Methylprednisolone",
                dose: "40-60 mg",
                route: "IV",
                note: "Systemic corticosteroids for COPD/asthma. Alternative: prednisone 40-50 mg PO."
            ),
            CodeBlueDrugDose(
                name: "Epinephrine",
                dose: "0.3-0.5 mg (1 mg/mL)",
                route: "IM",
                note: "Anterolateral thigh for anaphylaxis. Repeat q5-15min. Do NOT delay for other treatments."
            ),
            CodeBlueDrugDose(
                name: "Furosemide",
                dose: "40 mg (or 2x maintenance dose)",
                route: "IV",
                note: "For cardiogenic pulmonary edema. May repeat. Caution in hypotensive patients."
            ),
            CodeBlueDrugDose(
                name: "Nitroglycerin",
                dose: "0.4 mg SL spray",
                route: "SL spray",
                note: "Repeat q5min x3 if SBP > 100. For pulmonary edema or ACS. Avoid in RV infarct/PDE5 inhibitor use."
            ),
            CodeBlueDrugDose(
                name: "Magnesium Sulfate",
                dose: "2 g IV over 20min",
                route: "IV",
                note: "For severe asthma unresponsive to initial nebulized therapy."
            ),
            CodeBlueDrugDose(
                name: "Heparin",
                dose: "80 units/kg bolus, then 18 units/kg/hr infusion",
                route: "IV",
                note: "For confirmed PE. Adjust to aPTT or anti-Xa. Alternative: enoxaparin 1 mg/kg SC BID."
            )
        ]
    )

    /// Adult tachycardia evaluation (narrow QRS vs wide QRS).
    public static let tachycardia = CodeBlueAlgorithm(
        id: "tachycardia",
        title: "Tachycardia Evaluation — Adult",
        summary: "Algorithm for stable and unstable tachycardia: narrow-complex (SVT, AFib/AFlutter, sinus tachycardia) vs wide-complex (VT, SVT with aberrancy), guided by stability and QRS width.",
        steps: [
            "Assess stability: hypotension, altered mental status, chest pain, shock, heart failure. Unstable → immediate synchronized cardioversion.",
            "Obtain 12-lead ECG. Note QRS width: narrow (< 120 ms) vs wide (≥ 120 ms). Determine rhythm: regular or irregular.",
            "Unstable narrow-complex: synchronized cardioversion 50-100 J. If unsuccessful, escalate to 200 J or higher.",
            "Stable SVT: vagal maneuvers (modified Valsalva). If unsuccessful, adenosine 6 mg rapid IV push; if no change, 12 mg rapid IV push. May repeat 12 mg once.",
            "Atrial fibrillation/flutter (stable): rate control with diltiazem 0.25 mg/kg IV over 2min; if no response, repeat 0.35 mg/kg. Alternatively metoprolol 5 mg IV q5min (max 15 mg). If rapid rate with WPW → contraindicate AV nodal blockers; use procainamide or electrical cardioversion.",
            "Unstable wide-complex: synchronized cardioversion 100 J (biphasic). If monomorphic VT confirmed, consider procainamide 20 mg/min (max 17 mg/kg) or amiodarone 150 mg IV over 10min.",
            "Polymorphic VT/torsades: IV magnesium 2 g over 1-2min. Correct potassium and magnesium. Discontinue QT-prolonging agents. Temporary pacing if bradycardia-dependent."
        ],
        drugs: [
            CodeBlueDrugDose(
                name: "Adenosine",
                dose: "6 mg rapid IV push, then 12 mg if no change, then 12 mg once",
                route: "IV (follow with 20 mL saline flush, elevate arm)",
                note: "For stable narrow-complex tachycardia. Transient asystole/flush common. Do NOT use in 2nd/3rd degree AV block without pacemaker."
            ),
            CodeBlueDrugDose(
                name: "Diltiazem",
                dose: "0.25 mg/kg IV over 2min, then 0.35 mg/kg if needed",
                route: "IV",
                note: "Rate control in AFib/flutter. Avoid in HFrEF (LVEF < 40%)."
            ),
            CodeBlueDrugDose(
                name: "Metoprolol",
                dose: "5 mg IV over 2min, repeat q5min (max 15 mg)",
                route: "IV",
                note: "Alternative rate control. Avoid in decompensated HF or bronchospasm."
            ),
            CodeBlueDrugDose(
                name: "Procainamide",
                dose: "20-50 mg/min IV (max 17 mg/kg)",
                route: "IV",
                note: "Stable monomorphic VT or SVT with WPW. Monitor BP — can cause hypotension and QT prolongation."
            ),
            CodeBlueDrugDose(
                name: "Amiodarone",
                dose: "150 mg IV over 10min",
                route: "IV",
                note: "Stable polymorphic VT or wide-complex tachycardia of uncertain origin."
            ),
            CodeBlueDrugDose(
                name: "Magnesium Sulfate",
                dose: "2 g over 1-2min",
                route: "IV",
                note: "First-line for torsades de pointes. Also useful in alcohol-withdrawal tachycardia."
            )
        ]
    )

    /// Adult bradycardia with pulse algorithm.
    public static let bradycardia = CodeBlueAlgorithm(
        id: "bradycardia",
        title: "Bradycardia with Pulse — Adult",
        summary: "2025 AHA adult bradycardia algorithm: identify underlying cause, then apply pharmacologic therapy (atropine → transcutaneous pacing → dopamine/epinephrine infusion) for symptomatic bradycardia.",
        steps: [
            "Assess: heart rate < 50 bpm with signs of poor perfusion (hypotension, altered mental status, shock, ischemic chest discomfort, acute heart failure).",
            "Obtain 12-lead ECG. Identify rhythm: sinus bradycardia, sinus arrest, 1st/2nd/3rd degree AV block, junctional rhythm, ventricular escape.",
            "If symptomatic: prepare transcutaneous pacing pads. Establish IV access. Monitor continuously.",
            "Administer atropine 0.5 mg IV/IO every 3 to 5 minutes (maximum 3 mg). For organophosphate/nerve agent exposure, use larger atropine doses (2-5 mg).",
            "If atropine ineffective → transcutaneous pacing. Alternative: dopamine infusion 5-20 mcg/kg/min or epinephrine infusion 2-10 mcg/min.",
            "Consider magnesium 1-2 g IV for torsades or digitalis toxicity.",
            "Reverse the underlying cause: hypoxia (oxygenate), hypovolemia (IV fluids), hypoglycemia (glucose), hypothermia (warm), toxins (specific antidotes), tension pneumothorax (decompress), cardiac tamponade (pericardiocentesis)."
        ],
        drugs: [
            CodeBlueDrugDose(
                name: "Atropine",
                dose: "0.5 mg IV/IO every 3-5 min (max 3 mg)",
                route: "IV/IO",
                note: "Symptomatic sinus bradycardia or AV nodal block. Higher doses (2-5 mg) for organophosphate/nerve agent exposure."
            ),
            CodeBlueDrugDose(
                name: "Dopamine",
                dose: "5-20 mcg/kg/min infusion",
                route: "IV infusion",
                note: "Alternative to pacing when atropine fails. Titrate to hemodynamic response."
            ),
            CodeBlueDrugDose(
                name: "Epinephrine",
                dose: "2-10 mcg/min infusion",
                route: "IV infusion",
                note: "Alternative to pacing. Titrate to heart rate and blood pressure."
            ),
            CodeBlueDrugDose(
                name: "Magnesium Sulfate",
                dose: "1-2 g IV over 5-60min",
                route: "IV",
                note: "For torsades de pointes or digitalis-associated arrhythmias."
            )
        ]
    )

    /// Acute stroke evaluation (including tPA/thrombectomy eligibility).
    public static let acuteStroke = CodeBlueAlgorithm(
        id: "acute-stroke",
        title: "Acute Stroke — Adult",
        summary: "2025 AHA/ASA acute ischemic stroke guidelines: rapid identification (FAST), non-contrast CT to rule out hemorrhage, time-based decision for IV thrombolysis (alteplase 0.9 mg/kg within 4.5 hours or tenecteplase 0.25 mg/kg within 6 hours), and endovascular thrombectomy for large vessel occlusion (within 6-24 hours with perfusion imaging).",
        steps: [
            "Identify stroke using FAST (Face drooping, Arm weakness, Speech difficulty, Time to call 911). Note exact time symptoms began (last known well time).",
            "Immediate non-contrast head CT within 20 minutes. Determine hemorrhagic vs ischemic stroke.",
            "If ischemic and last known well < 4.5 hours: IV alteplase 0.9 mg/kg (max 90 mg) — 10% bolus over 1min, then 90% over 60min. OR tenecteplase 0.25 mg/kg (max 25 mg) single IV bolus within 6 hours.",
            "Check blood glucose. Treat hypoglycemia (50% dextrose 25g IV). Target glucose 140-180 mg/dL.",
            "Check blood pressure: if ≥ 185/110 mmHg, lower with nicardipine, labetalol, or clevidipine to < 185/110 before tPA. Target < 180/105 during and after tPA.",
            "If LVO suspected: CT angiography. If within 6 hours → mechanical thrombectomy. If 6-24 hours with favorable perfusion imaging (DAWN/DEFUSE-3) → thrombectomy.",
            "If tPA contraindicated: aspirin 162-325 mg within 24-48 hours (hold for 24 hours after tPA). Admit to stroke unit. Identify and treat underlying cause."
        ],
        drugs: [
            CodeBlueDrugDose(
                name: "Alteplase (tPA)",
                dose: "0.9 mg/kg (max 90 mg) — 10% bolus, 90% over 60min",
                route: "IV",
                note: "Must be given within 4.5 hours of symptom onset. Check contraindications: recent surgery, bleeding diathesis, BP > 185/110."
            ),
            CodeBlueDrugDose(
                name: "Tenecteplase",
                dose: "0.25 mg/kg (max 25 mg) as single bolus",
                route: "IV",
                note: "Alternative to alteplase. Must be given within 6 hours of onset. May be used as bridge to thrombectomy."
            ),
            CodeBlueDrugDose(
                name: "Nicardipine",
                dose: "5 mg/hr IV, titrate by 2.5 mg/hr q5-15min (max 15 mg/hr)",
                route: "IV infusion",
                note: "For BP lowering prior to tPA. Target < 185/110 mmHg."
            ),
            CodeBlueDrugDose(
                name: "Labetalol",
                dose: "10-20 mg IV over 2min, repeat 20-40 mg q10min (max 300 mg)",
                route: "IV",
                note: "For BP lowering. Avoid in asthma, heart block, or decompensated HF."
            ),
            CodeBlueDrugDose(
                name: "Dextrose 50%",
                dose: "25 g IV (50 mL of D50W)",
                route: "IV",
                note: "For hypoglycemia (< 60 mg/dL). Confirm with point-of-care glucose."
            ),
            CodeBlueDrugDose(
                name: "Aspirin",
                dose: "162-325 mg PO",
                route: "PO",
                note: "Within 24-48 hours for non-thrombolysed ischemic stroke. Hold 24 hours after tPA."
            )
        ]
    )

    /// Sepsis and septic shock early goal-directed therapy (SSC 2021).
    public static let sepsis = CodeBlueAlgorithm(
        id: "sepsis",
        title: "Sepsis & Septic Shock — Adult",
        summary: "2021 Surviving Sepsis Campaign bundles: rapid recognition (qSOFA/SIRS), early antibiotic administration within 1 hour, lactate measurement, blood cultures before antibiotics, and hemodynamic support with IV fluids and vasopressors as needed.",
        steps: [
            "Identify suspected infection and assess for sepsis (SOFA score increase ≥ 2, or qSOFA ≥ 2: RR ≥ 22, altered mentation, SBP ≤ 100). Septic shock: vasopressor requirement to maintain MAP ≥ 65 mmHg with lactate > 2 mmol/L.",
            "Draw blood cultures (at least 2 sets from separate sites) and lactate level. Obtain additional cultures as clinically indicated.",
            "Begin broad-spectrum antibiotics within 1 hour. Choose agents based on likely source and local antibiogram.",
            "If hypotensive (SBP < 90 mmHg or MAP < 65 mmHg) or lactate ≥ 4 mmol/L: crystalloid fluid bolus 30 mL/kg within first 3 hours. Reassess perfusion (capillary refill, mental status, urine output, lactate trend).",
            "If still hypotensive after initial 30 mL/kg → start norepinephrine to maintain MAP ≥ 65 mmHg. Add vasopressin (0.03 units/min) if MAP target not achieved.",
            "If fluids and norepinephrine insufficient → add vasopressin (0.03-0.06 units/min) or epinephrine. Consider dobutamine if persistent hypoperfusion despite adequate MAP.",
            "Source control: drain abscesses, remove infected devices, debride necrotic tissue, source-specific interventions. Obtain imaging if source unclear."
        ],
        drugs: [
            CodeBlueDrugDose(
                name: "Crystalloid (NS or LR)",
                dose: "30 mL/kg within 3 hours",
                route: "IV bolus",
                note: "First-line fluid for sepsis. Reassess volume response after initial bolus. Adjust for heart failure or fluid overload."
            ),
            CodeBlueDrugDose(
                name: "Norepinephrine",
                dose: "Start 0.1 mcg/kg/min, titrate to MAP ≥ 65 mmHg",
                route: "IV infusion (central line preferred)",
                note: "First-line vasopressor for septic shock. Titrate to MAP ≥ 65."
            ),
            CodeBlueDrugDose(
                name: "Vasopressin",
                dose: "0.03 units/min (fixed dose, do not titrate)",
                route: "IV infusion",
                note: "Add-on to norepinephrine. Fixed dose 0.03 units/min."
            ),
            CodeBlueDrugDose(
                name: "Epinephrine",
                dose: "0.05-0.5 mcg/kg/min",
                route: "IV infusion",
                note: "Second-line vasopressor when norepinephrine and vasopressin insufficient."
            ),
            CodeBlueDrugDose(
                name: "Dobutamine",
                dose: "2.5-20 mcg/kg/min",
                route: "IV infusion",
                note: "For persistent hypoperfusion despite adequate MAP. May cause hypotension."
            )
        ]
    )
}
