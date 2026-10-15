import SwiftUI

struct EBMStatisticsView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var bayesPrev = "5.0"
    @State private var bayesSens = "90.0"
    @State private var bayesSpec = "95.0"
    
    @State private var bayes2Prev = "5.0"
    @State private var bayes2LRPlus = "5.0"
    @State private var bayes2LRMinus = "0.1"
    
    @State private var benefitSce = "20"
    @State private var benefitCtrl = "30"
    
    @State private var falseNegTP = "80"
    @State private var falseNegFN = "20"
    @State private var falseNegFP = "10"
    @State private var falseNegTN = "90"
    
    @State private var falsePosTP = "80"
    @State private var falsePosFN = "20"
    @State private var falsePosFP = "10"
    @State private var falsePosTN = "90"
    
    @State private var lrSens = "85"
    @State private var lrSpec = "90"
    
    @State private var lrDataTP = "80"
    @State private var lrDataFN = "20"
    @State private var lrDataFP = "10"
    @State private var lrDataTN = "90"
    
    @State private var npvDataTP = "80"
    @State private var npvDataFN = "20"
    @State private var npvDataFP = "10"
    @State private var npvDataTN = "90"
    
    @State private var ppvDataTP = "80"
    @State private var ppvDataFN = "20"
    @State private var ppvDataFP = "10"
    @State private var ppvDataTN = "90"
    
    @State private var oddsPrev = "5.0"
    @State private var oddsLR = "5.0"
    
    @State private var percPERC = 0
    @State private var percAge70 = false
    @State private var perCPriorHF = false
    @State private var percPriorCAD = false
    @State private var percpCoag = false
    @State private var percSurgery = false
    @State private var percLegSwelling = false
    @State private var percpHemoptysis = false
    @State private var percPEOther = true
    
    @State private var sensSens = "85"
    @State private var sensSpec = "90"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "bayesiananalysis_1.htm":
            return calcBayesianAnalysis1()
        case "bayesiananalysis_2.htm":
            return calcBayesianAnalysis2()
        case "benefitincrease.htm":
            return calcBenefitIncrease()
        case "falsenegativerate.htm":
            return calcFalseNegativeRate()
        case "falsepositiverate.htm":
            return calcFalsePositiveRate()
        case "likelihoodratio.htm":
            return calcLikelihoodRatio()
        case "likelihoodratio_rawdata.htm":
            return calcLikelihoodRatioRaw()
        case "negativepredictivevalue.htm":
            return calcNPV()
        case "negativepredictivevalue_rawdata.htm":
            return calcNPVRaw()
        case "positivepredictivevalue.htm":
            return calcPPV()
        case "positivepredictivevalue_rawdata.htm":
            return calcPPVRaw()
        case "oddsprobability.htm":
            return calcOddsProbability()
        case "perc_riskforpe.htm":
            return calcPERC()
        case "sensitivityspecificity.htm":
            return calcSensitivitySpecificity()
        default:
            return "Not yet implemented"
        }
    }
    
    func calcBayesianAnalysis1() -> String {
        guard let prev = Double(bayesPrev), let sens = Double(bayesSens),
              let spec = Double(bayesSpec), prev > 0, sens > 0, spec > 0 else {
            return "Enter valid values"
        }
        let p = prev / 100.0, s = sens / 100.0, sp = spec / 100.0
        let postProb = (s * p) / (s * p + (1.0 - sp) * (1.0 - p))
        return String(format: "Post-test probability: %.1f%% (Prevalence: %.1f%%)", postProb * 100.0, prev)
    }
    
    func calcBayesianAnalysis2() -> String {
        guard let prev = Double(bayes2Prev), let lrPlus = Double(bayes2LRPlus),
              let lrMinus = Double(bayes2LRMinus), prev > 0, lrPlus > 0, lrMinus > 0 else {
            return "Enter valid values"
        }
        let p = prev / 100.0
        let postPositive = (lrPlus * p) / (lrPlus * p + (1.0 - p))
        let postNegative = (lrMinus * p) / (lrMinus * p + (1.0 - p))
        return String(format: "Post-test (positive): %.1f%%\nPost-test (negative): %.1f%%", postPositive * 100.0, postNegative * 100.0)
    }
    
    func calcBenefitIncrease() -> String {
        guard let sce = Double(benefitSce), let ctrl = Double(benefitCtrl),
              sce > 0, ctrl > 0 else { return "Enter valid values" }
        let ar = sce / 100.0, cr = ctrl / 100.0
        let nnt = 1.0 / (ar - cr)
        return String(format: "Absolute Risk: %d%% vs %d%%\nNNT: %.0f", Int(sce), Int(ctrl), nnt)
    }
    
    func calcFalseNegativeRate() -> String {
        guard let tp = Double(falseNegTP), let fn = Double(falseNegFN),
              let fp = Double(falseNegFP), let tn = Double(falseNegTN),
              tp > 0, fn > 0 else { return "Enter valid values" }
        let sens = tp / (tp + fn)
        let fpr = fp / (fp + tn)
        return String(format: "Sensitivity: %.1f%%\nFalse Neg Rate: %.1f%%\nSpecificity: %.1f%%", sens * 100.0, (1.0 - sens) * 100.0, (1.0 - fpr) * 100.0)
    }
    
    func calcFalsePositiveRate() -> String {
        guard let tp = Double(falsePosTP), let fn = Double(falsePosFN),
              let fp = Double(falsePosFP), let tn = Double(falsePosTN),
              tp > 0, fp > 0 else { return "Enter valid values" }
        let sens = tp / (tp + fn)
        let fpr = fp / (fp + tn)
        return String(format: "Sensitivity: %.1f%%\nFalse Pos Rate: %.1f%%\nSpecificity: %.1f%%", sens * 100.0, fpr * 100.0, (1.0 - fpr) * 100.0)
    }
    
    func calcLikelihoodRatio() -> String {
        guard let sens = Double(lrSens), let spec = Double(lrSpec),
              sens > 0, spec > 0 else { return "Enter valid values" }
        let s = sens / 100.0, sp = spec / 100.0
        let lrPlus = s / (1.0 - sp)
        let lrMinus = (1.0 - s) / sp
        return String(format: "LR+: %.2f\nLR-: %.2f", lrPlus, lrMinus)
    }
    
    func calcLikelihoodRatioRaw() -> String {
        guard let tp = Double(lrDataTP), let fn = Double(lrDataFN),
              let fp = Double(lrDataFP), let tn = Double(lrDataTN),
              tp > 0, fp > 0 else { return "Enter valid values" }
        let sens = tp / (tp + fn)
        let fpr = fp / (fp + tn)
        return String(format: "LR+: %.2f\nLR-: %.2f", sens / fpr, (1.0 - sens) / (1.0 - fpr))
    }
    
    func calcNPV() -> String {
        guard let tp = Double(npvDataTP), let fn = Double(npvDataFN),
              let fp = Double(npvDataFP), let tn = Double(npvDataTN),
              tp > 0, fp > 0 else { return "Enter valid values" }
        let npv = tn / (tn + fp)
        return String(format: "NPV: %.1f%%", npv * 100.0)
    }
    
    func calcNPVRaw() -> String {
        return calcNPV()
    }
    
    func calcPPV() -> String {
        guard let tp = Double(ppvDataTP), let fn = Double(ppvDataFN),
              let fp = Double(ppvDataFP), let tn = Double(ppvDataTN),
              tp > 0, fp > 0 else { return "Enter valid values" }
        let ppv = tp / (tp + fp)
        return String(format: "PPV: %.1f%%", ppv * 100.0)
    }
    
    func calcPPVRaw() -> String {
        return calcPPV()
    }
    
    func calcOddsProbability() -> String {
        guard let prev = Double(oddsPrev), let lr = Double(oddsLR), prev > 0, lr > 0 else {
            return "Enter valid values" }
        let p = prev / 100.0
        let postOdds = (p / (1.0 - p)) * lr
        let postProb = postOdds / (1.0 + postOdds)
        return String(format: "Post-test probability: %.1f%%", postProb * 100.0)
    }
    
    func calcPERC() -> String {
        var s = 0
        if percAge70 { s += 1 }
        if perCPriorHF { s += 1 }
        if percPriorCAD { s += 1 }
        if percpCoag { s += 1 }
        if percSurgery { s += 1 }
        if percLegSwelling { s += 1 }
        if percpHemoptysis { s += 1 }
        let dx = s == 0 ? "PE unlikely - no imaging needed" : "PE likely - image"
        return String(format: "PERC Score: %d/8 (%@)", s, dx)
    }
    
    func calcSensitivitySpecificity() -> String {
        guard let sens = Double(sensSens), let spec = Double(sensSpec),
              sens > 0, spec > 0 else { return "Enter valid values" }
        return String(format: "Sensitivity: %.1f%%\nSpecificity: %.1f%%", sens, spec)
    }
    
    var inputFields: some View {
        Group {
            Section("Bayesian Analysis") {
                TextField("Prevalence (%)", text: $bayesPrev).keyboardType(.decimalPad)
                TextField("Sensitivity (%)", text: $bayesSens).keyboardType(.decimalPad)
                TextField("Specificity (%)", text: $bayesSpec).keyboardType(.decimalPad)
            }
            
            Section("Benefit Increase (NNT)") {
                TextField("Control Event Rate (%)", text: $benefitCtrl).keyboardType(.decimalPad)
                TextField("Experimental Event Rate (%)", text: $benefitSce).keyboardType(.decimalPad)
            }
            
            Section("Likelihood Ratios") {
                TextField("Sensitivity (%)", text: $lrSens).keyboardType(.decimalPad)
                TextField("Specificity (%)", text: $lrSpec).keyboardType(.decimalPad)
            }
            
            Section("PERC Rule") {
                Toggle("Age ≥ 50", isOn: $percAge70)
                Toggle("Prior HF", isOn: $perCPriorHF)
                Toggle("Known CAD", isOn: $percPriorCAD)
                Toggle("Prior PE/DVT", isOn: $percpCoag)
                Toggle("Surgery 4w", isOn: $percSurgery)
                Toggle("Unilateral leg swelling", isOn: $percLegSwelling)
                Toggle("Hemoptysis", isOn: $percpHemoptysis)
                Toggle("PE most likely diagnosis", isOn: $percPEOther)
            }
        }
    }
    
    var body: some View {
        Form {
            inputFields
            Section("Result") { Text(result) }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
