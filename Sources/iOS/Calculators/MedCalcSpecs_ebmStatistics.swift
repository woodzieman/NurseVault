import Foundation

/// Calculator specs for the EBM & Statistics category.
/// Sources: BayesianAnalysis_1/2.htm, BenefitIncrease.htm, FalseNegativeRateSSP.htm,
/// FalsePositiveRateSSP.htm, Likelihood*.htm, NegPredVal*.htm, PosPredVal*.htm,
/// oddsprob.htm, perc.htm, ProbOdds.htm, Sensitivity.htm, Specificity.htm
let ebmStatisticsCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "BayesianAnalysis_1.htm",
        guide: """
        Bayesian Statistics I computes the full set of diagnostic test probabilities from a test's sensitivity, specificity, and the disease prevalence. All three inputs are required.

        Enter prevalence, sensitivity, and specificity as percentages (e.g., 5 for 5%). The result lists true/false rates, predictive values, likelihood ratios, pre/post-test odds and probabilities, and overall accuracy.
        """,
        equation: """
        TruePos = Sensitivity × Prevalence; TrueNeg = Specificity × (1 − Prevalence)
        PosPredValue = 100 × TruePos / (TruePos + FalsePos)
        LR+ = Sensitivity / (1 − Specificity); LR− = (1 − Sensitivity) / Specificity
        PostProb = PostOdds / (1 + PostOdds), PostOdds = PreTestOdds × LR
        """,
        inputs: [
            MedCalcInput("prev", "Prevalence", .number(unitHint: "% (e.g. 5 for 5%)")),
            MedCalcInput("sens", "Sensitivity", .number(unitHint: "% (e.g. 90)")),
            MedCalcInput("spec", "Specificity", .number(unitHint: "% (e.g. 95)"))
        ],
        compute: { v in
            guard let prev = v.number("prev"), let sens = v.number("sens"), let spec = v.number("spec") else { return "" }
            let p = prev / 100, s = sens / 100, sp = spec / 100
            let tp = s * p, fp = (1 - sp) * (1 - p), tn = sp * (1 - p), fn = (1 - s) * p
            let ppv = tp + fp > 0 ? 100 * tp / (tp + fp) : 0
            let npv = tn + fn > 0 ? 100 * tn / (tn + fn) : 0
            let lrPos = s / (1 - sp), lrNeg = (1 - s) / sp
            let preOdds = p / (1 - p)
            let postPos = preOdds * lrPos / (1 + preOdds * lrPos) * 100
            let postNeg = preOdds * lrNeg / (1 + preOdds * lrNeg) * 100
            let fpr = fp + tn > 0 ? 100 * fp / (fp + tn) : 0
            let fnr = tp + fn > 0 ? 100 * fn / (tp + fn) : 0
            let acc = 100 * (tp + tn)
            return """
            True Pos: \(String(format: "%.1f%%", 100 * tp))
            False Pos: \(String(format: "%.1f%%", 100 * fp))
            True Neg: \(String(format: "%.1f%%", 100 * tn))
            False Neg: \(String(format: "%.1f%%", 100 * fn))
            Pos Pred Value: \(String(format: "%.1f%%", ppv))
            Neg Pred Value: \(String(format: "%.1f%%", npv))
            LR Pos: \(String(format: "%.2f", lrPos))
            LR Neg: \(String(format: "%.2f", lrNeg))
            Pre Test Odds: \(String(format: "%.3f", preOdds))
            Post Prob Pos: \(String(format: "%.1f%%", postPos))
            Post Prob Neg: \(String(format: "%.1f%%", postNeg))
            False Pos Rate: \(String(format: "%.1f%%", fpr))
            False Neg Rate: \(String(format: "%.1f%%", fnr))
            Overall Accuracy: \(String(format: "%.1f%%", acc))
            """
        }
    ),

    MedCalcSpec(
        fileName: "BayesianAnalysis_2.htm",
        guide: """
        Bayesian Statistics II works from raw 2×2 counts: enter the number of true positives, false positives, true negatives, and false negatives from a study or test dataset.

        It derives sensitivity, specificity, prevalence, predictive values, likelihood ratios, and post-test probabilities. Enter whole numbers (counts).
        """,
        equation: """
        Sensitivity = TruePos / (TruePos + FalseNeg)
        Specificity = TrueNeg / (TrueNeg + FalsePos)
        Prevalence = (TruePos + FalseNeg) / (all four)
        """,
        inputs: [
            MedCalcInput("tp", "True Positives", .number(unitHint: "count (e.g. 80)")),
            MedCalcInput("fp", "False Positives", .number(unitHint: "count (e.g. 10)")),
            MedCalcInput("tn", "True Negatives", .number(unitHint: "count (e.g. 90)")),
            MedCalcInput("fn", "False Negatives", .number(unitHint: "count (e.g. 20)"))
        ],
        compute: { v in
            guard let tp = v.number("tp"), let fp = v.number("fp"), let tn = v.number("tn"), let fn = v.number("fn") else { return "" }
            let total = tp + fp + tn + fn
            guard total > 0, tp + fn > 0, tn + fp > 0 else { return "" }
            let sens = tp / (tp + fn), spec = tn / (tn + fp)
            let prev = (tp + fn) / total
            let ppv = 100 * tp / (tp + fp), npv = 100 * tn / (tn + fn)
            let lrPos = sens / (1 - spec), lrNeg = (1 - sens) / spec
            let preOdds = prev / (1 - prev)
            let postPos = preOdds * lrPos / (1 + preOdds * lrPos) * 100
            let postNeg = preOdds * lrNeg / (1 + preOdds * lrNeg) * 100
            let fpr = 100 * fp / (fp + tn), fnr = 100 * fn / (tp + fn)
            let acc = 100 * (tp + tn) / total
            return """
            Sensitivity: \(String(format: "%.1f%%", 100 * sens))
            Specificity: \(String(format: "%.1f%%", 100 * spec))
            Prevalence: \(String(format: "%.1f%%", 100 * prev))
            Pos Pred Value: \(String(format: "%.1f%%", ppv))
            Neg Pred Value: \(String(format: "%.1f%%", npv))
            LR Pos: \(String(format: "%.2f", lrPos))
            LR Neg: \(String(format: "%.2f", lrNeg))
            Pre Test Odds: \(String(format: "%.3f", preOdds))
            Post Prob Pos: \(String(format: "%.1f%%", postPos))
            Post Prob Neg: \(String(format: "%.1f%%", postNeg))
            False Pos Rate: \(String(format: "%.1f%%", fpr))
            False Neg Rate: \(String(format: "%.1f%%", fnr))
            Overall Accuracy: \(String(format: "%.1f%%", acc))
            """
        }
    ),

    MedCalcSpec(
        fileName: "BenefitIncrease.htm",
        guide: """
        Compares an experimental event rate against a control event rate to derive the absolute benefit, relative benefit, and the Number Needed to Treat (NNT).

        Enter both event rates as percentages. A lower experimental rate than the control rate gives a benefit; if the experimental rate is higher, values will be negative (a harm, and NNH territory).
        """,
        equation: """
        AbsBenefitIncrease = ControlEventRate − ExpEventRate
        RelBenefitIncrease = AbsBenefitIncrease / ControlEventRate
        NNT = 1 / AbsBenefitIncrease
        """,
        inputs: [
            MedCalcInput("ctrl", "Control Event Rate", .number(unitHint: "% (e.g. 20)")),
            MedCalcInput("exp", "Experimental Event Rate", .number(unitHint: "% (e.g. 15)"))
        ],
        compute: { v in
            guard let ctrl = v.number("ctrl"), let exp = v.number("exp") else { return "" }
            let c = ctrl / 100, e = exp / 100
            let absB = c - e
            guard absB != 0 else { return "Absolute benefit is zero — control and experimental rates are equal." }
            let relB = absB / c
            let nnt = 1 / absB
            return """
            Absolute Benefit: \(String(format: "%.2f%%", 100 * absB))
            Relative Benefit: \(String(format: "%.1f%%", 100 * relB))
            NNT: \(String(format: "%.1f", nnt))
            """
        }
    ),

    MedCalcSpec(
        fileName: "FalseNegativeRateSSP.htm",
        guide: """
        Derives the false negative rate from a test's sensitivity and the disease prevalence. Note that the false negative rate is simply 1 − sensitivity; prevalence is included to show the underlying true/false rates and pre-test odds.

        Enter prevalence and sensitivity as percentages.
        """,
        equation: """
        TruePos = Sensitivity × Prevalence
        FalseNeg = (1 − Sensitivity) × Prevalence
        FalseNegRate = 100 × FalseNeg / (TruePos + FalseNeg)
        """,
        inputs: [
            MedCalcInput("prev", "Prevalence", .number(unitHint: "% (e.g. 5)")),
            MedCalcInput("sens", "Sensitivity", .number(unitHint: "% (e.g. 85)"))
        ],
        compute: { v in
            guard let prev = v.number("prev"), let sens = v.number("sens") else { return "" }
            let p = prev / 100, s = sens / 100
            let tp = s * p, fn = (1 - s) * p
            let fnr = tp + fn > 0 ? 100 * fn / (tp + fn) : 0
            let preOdds = p / (1 - p)
            return """
            True Pos: \(String(format: "%.2f%%", 100 * tp))
            False Neg: \(String(format: "%.2f%%", 100 * fn))
            Pre Test Odds: \(String(format: "%.3f", preOdds))
            False Neg Rate: \(String(format: "%.1f%%", fnr))
            """
        }
    ),

    MedCalcSpec(
        fileName: "FalsePositiveRateSSP.htm",
        guide: """
        Derives the false positive rate from a test's specificity and the disease prevalence. Note that the false positive rate is simply 1 − specificity; prevalence is included to show the underlying true/false rates.

        Enter prevalence and specificity as percentages.
        """,
        equation: """
        FalsePos = (1 − Specificity) × (1 − Prevalence)
        TrueNeg = Specificity × (1 − Prevalence)
        FalsePosRate = 100 × FalsePos / (FalsePos + TrueNeg)
        """,
        inputs: [
            MedCalcInput("prev", "Prevalence", .number(unitHint: "% (e.g. 5)")),
            MedCalcInput("spec", "Specificity", .number(unitHint: "% (e.g. 95)"))
        ],
        compute: { v in
            guard let prev = v.number("prev"), let spec = v.number("spec") else { return "" }
            let p = prev / 100, sp = spec / 100
            let fp = (1 - sp) * (1 - p), tn = sp * (1 - p)
            let fpr = fp + tn > 0 ? 100 * fp / (fp + tn) : 0
            return """
            False Pos: \(String(format: "%.2f%%", 100 * fp))
            True Neg: \(String(format: "%.2f%%", 100 * tn))
            False Pos Rate: \(String(format: "%.1f%%", fpr))
            """
        }
    ),

    MedCalcSpec(
        fileName: "Likelihood.htm",
        guide: """
        Computes the positive and negative likelihood ratios (LR+) and (LR−) from a test's sensitivity and specificity.

        LR+ tells how much a positive test result raises the odds of disease; LR− tells how much a negative result lowers it. Enter sensitivity and specificity as percentages.
        """,
        equation: """
        LR+ = Sensitivity / (1 − Specificity)
        LR− = (1 − Sensitivity) / Specificity
        """,
        inputs: [
            MedCalcInput("sens", "Sensitivity", .number(unitHint: "% (e.g. 85)")),
            MedCalcInput("spec", "Specificity", .number(unitHint: "% (e.g. 90)"))
        ],
        compute: { v in
            guard let sens = v.number("sens"), let spec = v.number("spec") else { return "" }
            let s = sens / 100, sp = spec / 100
            let lrPos = s / (1 - sp), lrNeg = (1 - s) / sp
            return """
            LR Pos: \(String(format: "%.2f", lrPos))
            LR Neg: \(String(format: "%.2f", lrNeg))
            """
        }
    ),

    MedCalcSpec(
        fileName: "LikelihoodRNData.htm",
        guide: """
        Computes the negative likelihood ratio (LR−) from raw 2×2 test data. Enter the counts of true positives, false positives, true negatives, and false negatives.
        """,
        equation: """
        Sensitivity = TruePos / (TruePos + FalseNeg)
        LR− = (1 − Sensitivity) / Specificity
        """,
        inputs: [
            MedCalcInput("tp", "True Positives", .number(unitHint: "count")),
            MedCalcInput("fp", "False Positives", .number(unitHint: "count")),
            MedCalcInput("tn", "True Negatives", .number(unitHint: "count")),
            MedCalcInput("fn", "False Negatives", .number(unitHint: "count"))
        ],
        compute: { v in
            guard let tp = v.number("tp"), let fp = v.number("fp"), let tn = v.number("tn"), let fn = v.number("fn") else { return "" }
            guard tp + fn > 0, tn + fp > 0 else { return "" }
            let sens = tp / (tp + fn), spec = tn / (tn + fp)
            let lrNeg = (1 - sens) / spec
            return """
            Sensitivity: \(String(format: "%.1f%%", 100 * sens))
            Specificity: \(String(format: "%.1f%%", 100 * spec))
            LR Neg: \(String(format: "%.2f", lrNeg))
            """
        }
    ),

    MedCalcSpec(
        fileName: "LikelihoodRPData.htm",
        guide: """
        Computes the positive likelihood ratio (LR+) from raw 2×2 test data. Enter the counts of true positives, false positives, true negatives, and false negatives.
        """,
        equation: """
        Specificity = TrueNeg / (TrueNeg + FalsePos)
        LR+ = Sensitivity / (1 − Specificity)
        """,
        inputs: [
            MedCalcInput("tp", "True Positives", .number(unitHint: "count")),
            MedCalcInput("fp", "False Positives", .number(unitHint: "count")),
            MedCalcInput("tn", "True Negatives", .number(unitHint: "count")),
            MedCalcInput("fn", "False Negatives", .number(unitHint: "count"))
        ],
        compute: { v in
            guard let tp = v.number("tp"), let fp = v.number("fp"), let tn = v.number("tn"), let fn = v.number("fn") else { return "" }
            guard tp + fn > 0, tn + fp > 0 else { return "" }
            let sens = tp / (tp + fn), spec = tn / (tn + fp)
            let lrPos = sens / (1 - spec)
            return """
            Sensitivity: \(String(format: "%.1f%%", 100 * sens))
            Specificity: \(String(format: "%.1f%%", 100 * spec))
            LR Pos: \(String(format: "%.2f", lrPos))
            """
        }
    ),

    MedCalcSpec(
        fileName: "NegPredValueData.htm",
        guide: """
        Computes the negative predictive value (NPV) directly from raw counts: the proportion of people with a negative test result who truly do not have the disease. Enter the counts of true negatives and false negatives.
        """,
        equation: "NPV = 100 × TrueNeg / (TrueNeg + FalseNeg)",
        inputs: [
            MedCalcInput("tn", "True Negatives", .number(unitHint: "count")),
            MedCalcInput("fn", "False Negatives", .number(unitHint: "count"))
        ],
        compute: { v in
            guard let tn = v.number("tn"), let fn = v.number("fn") else { return "" }
            guard tn + fn > 0 else { return "" }
            return "NPV: \(String(format: "%.1f%%", 100 * tn / (tn + fn)))"
        }
    ),

    MedCalcSpec(
        fileName: "NegPredVal.htm",
        guide: """
        Computes the negative predictive value (NPV) of a test from its sensitivity, specificity, and the disease prevalence — the proportion of people with a negative result who truly do not have the disease.

        NPV is highly prevalence-dependent: it is high when the disease is rare. Enter all values as percentages.
        """,
        equation: """
        NPV = 100 × ((1 − Prevalence) × Specificity) / (((1 − Prevalence) × Specificity) + (Prevalence × (1 − Sensitivity)))
        """,
        inputs: [
            MedCalcInput("prev", "Prevalence", .number(unitHint: "% (e.g. 5)")),
            MedCalcInput("sens", "Sensitivity", .number(unitHint: "% (e.g. 85)")),
            MedCalcInput("spec", "Specificity", .number(unitHint: "% (e.g. 90)"))
        ],
        compute: { v in
            guard let prev = v.number("prev"), let sens = v.number("sens"), let spec = v.number("spec") else { return "" }
            let p = prev / 100, s = sens / 100, sp = spec / 100
            let den = (1 - p) * sp + p * (1 - s)
            guard den > 0 else { return "" }
            return "NPV: \(String(format: "%.1f%%", 100 * (1 - p) * sp / den))"
        }
    ),

    MedCalcSpec(
        fileName: "oddsprob.htm",
        guide: """
        Converts a probability to odds. Odds express the chance of an event versus the chance of it not occurring. Enter the probability as a percentage (e.g., 5 for 5%).
        """,
        equation: "Odds = Probability / (1 − Probability)",
        inputs: [
            MedCalcInput("prob", "Probability", .number(unitHint: "% (e.g. 5)"))
        ],
        compute: { v in
            guard let prob = v.number("prob") else { return "" }
            let p = prob / 100
            guard p < 1 else { return "" }
            return "Odds: \(String(format: "%.3f", p / (1 - p)))"
        }
    ),

    MedCalcSpec(
        fileName: "perc.htm",
        guide: """
        The PERC (Pulmonary Embolism Rule-out Criteria) rule screens for pulmonary embolism in low-suspected-risk patients. Answer yes/no to each of the eight criteria; each present criterion scores 1 point.

        • 0 points: low risk of PE — diagnostic testing can safely be omitted (provided clinical suspicion is also low)
        • 1 to 8 points: increased risk of PE — further testing (D-dimer, imaging) is indicated
        """,
        inputs: [
            MedCalcInput("age", "Age ≥ 50 years (1 point)", .yesNo),
            MedCalcInput("hr", "Heart rate ≥ 100 beats per minute (1 point)", .yesNo),
            MedCalcInput("o2", "Arterial oxygen saturation < 95% (1 point)", .yesNo),
            MedCalcInput("leg", "Swelling of a single leg (1 point)", .yesNo),
            MedCalcInput("hemo", "Hemoptysis (1 point)", .yesNo),
            MedCalcInput("surg", "History of recent surgery or trauma (1 point)", .yesNo),
            MedCalcInput("vte", "History of venous thromboembolic disease: DVT or PE (1 point)", .yesNo),
            MedCalcInput("estrogen", "Use of estrogen hormone (1 point)", .yesNo)
        ],
        compute: { v in
            let ids = ["age", "hr", "o2", "leg", "hemo", "surg", "vte", "estrogen"]
            guard ids.allSatisfy({ v.selection($0) != nil }) else { return "" }
            let score = ids.reduce(0) { $0 + (v.selection($1) ?? 0) }
            let interp = score == 0
                ? "Low risk of pulmonary embolism — testing may be omitted"
                : "Increased risk of pulmonary embolism — further testing indicated"
            return "PERC Score: \(score)/8\n\(interp)"
        }
    ),

    MedCalcSpec(
        fileName: "PosPredValueData.htm",
        guide: """
        Computes the positive predictive value (PPV) directly from raw counts: the proportion of people with a positive test result who truly have the disease. Enter the counts of true positives and false positives.
        """,
        equation: "PPV = 100 × TruePos / (TruePos + FalsePos)",
        inputs: [
            MedCalcInput("tp", "True Positives", .number(unitHint: "count")),
            MedCalcInput("fp", "False Positives", .number(unitHint: "count"))
        ],
        compute: { v in
            guard let tp = v.number("tp"), let fp = v.number("fp") else { return "" }
            guard tp + fp > 0 else { return "" }
            return "PPV: \(String(format: "%.1f%%", 100 * tp / (tp + fp)))"
        }
    ),

    MedCalcSpec(
        fileName: "PosPredValue.htm",
        guide: """
        Computes the positive predictive value (PPV) of a test from its sensitivity, specificity, and the disease prevalence — the proportion of people with a positive result who truly have the disease.

        PPV rises with prevalence. Enter all values as percentages.
        """,
        equation: """
        PPV = 100 × (Prevalence × Sensitivity) / ((Prevalence × Sensitivity) + ((1 − Prevalence) × (1 − Specificity)))
        """,
        inputs: [
            MedCalcInput("prev", "Prevalence", .number(unitHint: "% (e.g. 5)")),
            MedCalcInput("sens", "Sensitivity", .number(unitHint: "% (e.g. 85)")),
            MedCalcInput("spec", "Specificity", .number(unitHint: "% (e.g. 90)"))
        ],
        compute: { v in
            guard let prev = v.number("prev"), let sens = v.number("sens"), let spec = v.number("spec") else { return "" }
            let p = prev / 100, s = sens / 100, sp = spec / 100
            let num = p * s
            let den = num + (1 - p) * (1 - sp)
            guard den > 0 else { return "" }
            return "PPV: \(String(format: "%.1f%%", 100 * num / den))"
        }
    ),

    MedCalcSpec(
        fileName: "ProbOdds.htm",
        guide: """
        Converts odds back to a probability. Enter the odds as a number (e.g., 0.053 for 5% probability).
        """,
        equation: "Probability = Odds / (1 + Odds)",
        inputs: [
            MedCalcInput("odds", "Odds", .number(unitHint: "e.g. 0.053"))
        ],
        compute: { v in
            guard let odds = v.number("odds"), odds > 0 else { return "" }
            return "Probability: \(String(format: "%.1f%%", 100 * odds / (1 + odds)))"
        }
    ),

    MedCalcSpec(
        fileName: "Sensitivity.htm",
        guide: """
        Computes the sensitivity of a test from raw counts — the proportion of people with the disease who test positive. Enter the counts of true positives and false negatives.
        """,
        equation: "Sensitivity = 100 × TruePositives / (TruePositives + FalseNegatives)",
        inputs: [
            MedCalcInput("tp", "True Positives", .number(unitHint: "count")),
            MedCalcInput("fn", "False Negatives", .number(unitHint: "count"))
        ],
        compute: { v in
            guard let tp = v.number("tp"), let fn = v.number("fn") else { return "" }
            guard tp + fn > 0 else { return "" }
            return "Sensitivity: \(String(format: "%.1f%%", 100 * tp / (tp + fn)))"
        }
    ),

    MedCalcSpec(
        fileName: "Specificity.htm",
        guide: """
        Computes the specificity of a test from raw counts — the proportion of people without the disease who test negative. Enter the counts of true negatives and false positives.
        """,
        equation: "Specificity = 100 × TrueNegatives / (TrueNegatives + FalsePositives)",
        inputs: [
            MedCalcInput("tn", "True Negatives", .number(unitHint: "count")),
            MedCalcInput("fp", "False Positives", .number(unitHint: "count"))
        ],
        compute: { v in
            guard let tn = v.number("tn"), let fp = v.number("fp") else { return "" }
            guard tn + fp > 0 else { return "" }
            return "Specificity: \(String(format: "%.1f%%", 100 * tn / (tn + fp)))"
        }
    )
]
