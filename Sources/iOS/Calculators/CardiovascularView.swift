import SwiftUI

struct CardiovascularView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var cvdDuration = "5"
    @State private var cvdAgeAtStart = "15"
    @State private var cvdAlbuminExcretion = "10"
    @State private var cvdSystolicBP = "120"
    @State private var cvdSmoking = false
    @State private var cvdHba1c = "7.0"
    

    

    

    

    

    

    

    
    @State private var afHf = false
    @State private var afHt = false
    @State private var afAge70 = false
    @State private var afDm = false
    @State private var afStrk = false
    @State private var afVas = false
    @State private var afAge65 = false
    @State private var afFemale = false
    

    
    @State private var coHr = "70"
    @State private var coSvMl = "70"
    @State private var coVo2MlMin = "250"
    @State private var coAvDiff = "5"
    
    @State private var cvrAge = "55"
    @State private var cvrTotalChol = "200"
    @State private var cvrHdl = "50"
    @State private var cvrSystolic = "130"
    @State private var cvrTreatedBp = false
    @State private var cvrSmoking = false
    @State private var cvrDiabetes = false
    
    @State private var wvtsCancer = false
    @State private var wvtsPrevDvt = false
    @State private var wvtsSurgery4w = false
    @State private var wvtsHemoptysis = false
    @State private var wvtsCancer2 = false
    @State private var wvtsLegSwelling = false
    @State private var wvtsAltDiag = true
    
    @State private var esAge = "65"
    @State private var esFemale = false
    @State private var esChronPulm = false
    @State private var esCvSt = "0"
    @State private var esPriorSurg = "0"
    @State private var ef = "55"
    @State private var esAortic = false
    @State private var esOtherValve = false
    @State private var esUrg = "0"
    @State private var esCerebro = false
    @State private var esThorAorta = false
    @State private var esRenal = "0"
    @State private var esEndo = false
    @State private var esUnstableAng = false
    @State private var esCreatMgDl = "1.0"
    @State private var esEmerg = false
    
    @State private var frTdL = "200"
    @State private var frHdl = "50"
    @State private var frTrigMgDl = "150"
    
    @State private var marTdL = "200"
    @State private var marHdl = "50"
    @State private var marTrigMgDl = "150"
    
    @State private var graceAge = "65"
    @State private var graceHr = "80"
    @State private var graceSbp = "120"
    @State private var graceCreatMgDl = "1.0"
    @State private var graceCardiacArrest = false
    @State private var graceStDev = false
    @State private var graceEnzElev = false
    @State private var graceKillip = "1"
    
    @State private var hBledHtn = false
    @State private var hBledRenal = false
    @State private var hBledLiver = false
    @State private var hBledStroke = false
    @State private var hBledBleed = false
    @State private var hBledLabileInr = false
    @State private var hBledElder = false
    @State private var hBledDrugs = false
    @State private var hBledAlcohol = false
    
    @State private var micConcST = "0"
    @State private var micDisStMm = "5"
    @State private var micDisQrsd = "120"
    @State private var micExConc = false
    
    @State private var mvpSys = "120"
    @State private var mvpDia = "80"
    

    
    @State private var meldCreatMgDl = "1.5"
    @State private var meldBilMgDl = "2.0"
    @State private var meldInr = "1.5"
    
    @State private var meld3Creat = "1.5"
    @State private var meld3Bil = "2.0"
    @State private var meld3Inr = "1.5"
    @State private var meld3NaMm = "135"
    @State private var meld3AlbGdL = "3.5"
    

    
    @State private var qtcHr = "75"
    @State private var qtcQtMsec = "420"
    
    @State private var genPrevDvtPe = false
    @State private var genSurgery = false
    @State private var genFracture = false
    @State private var genCancer = false
    @State private var genUnilateral = false
    @State private var genHemoptysis = false
    @State private var genHrGt80 = false
    
    @State private var reLvHvolt = false
    @State private var reStTchanges = false
    @State private var reSvplusRvmm = "20"
    @State private var reLaAbnormal = false
    @State private var reUwave = false
    
    @State private var timiAge = "65"
    @State private var timiAntStemi = false
    @State private var timiSysBP = "120"
    @State private var timiHr = "80"
    @State private var timiKillip = "1"
    
    @State private var timiUaAge70 = false
    @State private var timiUaRiskF3 = false
    @State private var timiUaKnownCad = false
    @State private var timiUaAsprin = false
    @State private var timiUaSevereAng = false
    @State private var timiUaStDev = false
    @State private var timiUaEnzElev = false
    
    @State private var pelPrevDvt = false
    @State private var pelPrevPe = false
    @State private var pelSurg4w = false
    @State private var pelHemoptysis = false
    @State private var pelCancer = false
    @State private var pelLegSwelling = false
    @State private var pelAltDiag = true
    

    

    
    @State private var vldlTdL = "200"
    @State private var vldlHdl = "50"
    @State private var vldlLdl = "100"
    

    

    

    

    

    
    var body: some View {
        Form {
            Section("Inputs") { contentInput }
            Section("Result") { Text(calculationResult) }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: calculationResult)
        .toolbar { Button("Close") { dismiss() } }
    }
    
    var contentInput: some View {
        Group {
        switch calculator.fileName.lowercased() {
        case "cvdinm1.htm":
            cvdInputView





        case "atrialfibchadsvasc.htm":
            chadsVascInputView

        case "cardiacoutput.htm":
            cardiacOutputInputView
        case "cardiacoutput_mc.htm":
            cardiacOutputFickInputView
        case "cvriskrevised2018.htm":
            cvRiskInputView
        case "dvtscorewells.htm":
            wellsDvtInputView
        case "euroscoreadd.htm":
            euroScoreInputView
        case "friedewald.htm":
            friedewaldInputView
        case "friedewald_si.htm":
            friedewaldSIInputView
        case "martinldl.htm":
            martinLdlInputView
        case "grace2score.htm":
            graceScoreInputView
        case "hasbled.htm":
            hasBledInputView
        case "micriterialbbb.htm":
            miLbbbInputView
        case "meanvascpres.htm":
            meanVascPresInputView

        case "meld.htm":
            meldInputView
        case "meld3.htm":
            meld3InputView

        case "qtintervalcorrection.htm":
            qtcInputView
        case "revisedgenevascore.htm":
            genevaScoreInputView
        case "romhilestes.htm":
            romhiltEstesInputView
        case "timi_stemi.htm":
            timiStemiInputView
        case "timi_ua_nstem1.htm":
            timiUaInputView
        case "pulmonaryembriskscore.htm":
            pelScoreInputView

        case "verylowdensitylipoprotein.htm":
            vldlInputView

        default:
            EmptyView()
        }
        }
    }
    
    var calculationResult: String {
        switch calculator.fileName.lowercased() {
        case "cvdinm1.htm":
            return calcCvdType1Risk()

        case "cardiacoutput_mc.htm":
            return calcCardiacOutputFick()
        case "cvriskrevised2018.htm":
            return calcCvRisk2018()
        case "dvtscorewells.htm":
            return calcWellsDvt()
        case "euroscoreadd.htm":
            return calcEuroScore()
        case "friedewald.htm":
            return calcFriedewald()
        case "friedewald_si.htm":
            return calcFriedewaldSI()
        case "martinldl.htm":
            return calcMartinLdl()
        case "grace2score.htm":
            return calcGraceScore()
        case "hasbled.htm":
            return calcHasBled()
        case "micriterialbbb.htm":
            return calcMILBBB()
        case "meanvascpres.htm":
            return calcMeanVascPres()

        case "meld.htm":
            return calcMeld()
        case "meld3.htm":
            return calcMeld3()

        case "qtintervalcorrection.htm":
            return calcQtc()
        case "revisedgenevascore.htm":
            return calcGeneva()
        case "romhilestes.htm":
            return calcRomhiltEstes()
        case "timi_stemi.htm":
            return calcTimiStemi()
        case "timi_ua_nstem1.htm":
            return calcTimiUa()
        case "pulmonaryembriskscore.htm":
            return calcPelScore()

        case "verylowdensitylipoprotein.htm":
            return calcVldl()

        default:
            return "Not yet implemented"
        }
    }
    
    func calcCvdType1Risk() -> String {
        guard let dur = Double(cvdDuration), let age = Double(cvdAgeAtStart),
              let alb = Double(cvdAlbuminExcretion), let sys = Double(cvdSystolicBP),
              let hba = Double(cvdHba1c), dur > 0, age > 0, hba > 0 else {
            return "Enter valid values"
        }
        // TODO: implement 5-year CVD risk formula for type 1 diabetes
        return "Not yet implemented"
    }
    

    

    
    

    

    

    

    
    func calcChadsVasc() -> String {
        var s = 0
        if afHf { s += 1 }; if afHt { s += 1 }; if afAge70 { s += 2 }; if afDm { s += 1 }
        if afStrk { s += 2 }; if afVas { s += 1 }; if afAge65 { s += 1 }; if afFemale { s += 1 }
        let rec = s == 0 ? "No AC" : s == 1 ? "Consider" : "AC recommended"
        return String(format: "CHA2DS2-VASc: %d (%@)", s, rec)
    }
    

    
    func calcCardiacOutput() -> String {
        guard let hr = Double(coHr), let sv = Double(coSvMl), hr > 0, sv > 0 else {
            return "Enter valid values"
        }
        return String(format: "CO: %.1f L/min (HR: %.0f x SV: %.0f mL)", (hr * sv) / 1000.0, hr, sv)
    }
    
    func calcCardiacOutputFick() -> String {
        guard let vo2 = Double(coVo2MlMin), let av = Double(coAvDiff), vo2 > 0, av > 0 else {
            return "Enter valid values"
        }
        return String(format: "CO (Fick): %.1f L/min", vo2 / av)
    }
    
    func calcCvRisk2018() -> String {
        guard let age = Double(cvrAge), let tc = Double(cvrTotalChol),
              let hdl = Double(cvrHdl), let sbp = Double(cvrSystolic),
              age >= 40 && age <= 79, tc > 0, hdl > 0, sbp > 0 else {
            return "Enter valid values (age 40-79)"
        }
        let la = log(age / 10.0), lt = log(tc), lh = log(hdl), ls = log(sbp)
        var logit = -20.46 + 3.77 * la + 0.73 * lt - 1.64 * lh + 3.43 * ls
        if cvrTreatedBp { logit += 0.78 }
        if cvrSmoking { logit += 0.78 }
        if cvrDiabetes { logit += 0.63 }
        return String(format: "10-Year ASCVD Risk: %.1f%%", 1.0 / (1.0 + exp(-logit)) * 100.0)
    }
    
    func calcWellsDvt() -> String {
        var s = 0.0
        if wvtsCancer { s += 1 }; if wvtsPrevDvt { s += 1.5 }; if wvtsSurgery4w { s += 1.5 }
        if wvtsHemoptysis { s += 1 }; if wvtsCancer2 { s += 1 }; if wvtsLegSwelling { s += 1 }
        if !wvtsAltDiag { s += 1.5 }
        return String(format: "Wells DVT: %.0f (%@)", Double(s), s >= 4.0 ? "Likely" : "Unlikely")
    }
    
    func calcEuroScore() -> String {
        guard let age = Double(esAge), let ef = Double(ef),
              let creatMgDl = Double(esCreatMgDl), age > 0, ef > 0, creatMgDl > 0 else {
            return "Enter valid values"
        }
        var s = Double(age) * 0.2
        if esFemale { s += 1.0 }; if esChronPulm { s += 1.0 }
        s += ((Double(esCvSt) ?? 0) + (Double(esPriorSurg) ?? 0)) * 0.5
        s += ef < 30.0 ? 2.0 : ef < 50.0 ? 1.0 : 0.0
        if esAortic { s += 1.0 }; if esOtherValve { s += 0.5 }
        s += Double(esUrg) ?? 0; if esCerebro { s += 1.0 }; if esThorAorta { s += 1.5 }
        s += (Double(esRenal) ?? 0) * 0.8; if esEndo { s += 2.0 }; if esUnstableAng { s += 1.0 }
        s += creatMgDl * 0.5; if esEmerg { s += 1.0 }
        return String(format: "EuroSCORE: %.1f (Mortality: %.1f%%)", s, min(exp(-s / 100.0) * 100.0, 99.0))
    }
    
    func calcFriedewald() -> String {
        guard let tdL = Double(frTdL), let hdl = Double(frHdl),
              let trig = Double(frTrigMgDl), tdL > 0, hdl > 0, trig <= 400 else {
            return "Triglycerides must be < 400 mg/dL"
        }
        let ldl = tdL - hdl - (trig / 5.0)
        return String(format: "LDL: %.1f mg/dL", ldl)
    }
    
    func calcFriedewaldSI() -> String {
        guard let tdMm = Double(frTdL), let hdlMm = Double(frHdl),
              let trigMm = Double(frTrigMgDl), tdMm > 0, hdlMm > 0 else {
            return "Enter valid values"
        }
        let ldl = tdMm - hdlMm - (trigMm / 2.18)
        return String(format: "LDL (SI): %.1f mmol/L", ldl)
    }
    
    func calcMartinLdl() -> String {
        guard let tdL = Double(marTdL), let hdl = Double(marHdl),
              let trig = Double(marTrigMgDl), tdL > 0, hdl > 0 else {
            return "Enter valid values"
        }
        let vldl = trig / 5.0
        let ldl = tdL - (1.167 * vldl) / (1.0 + vldl / (0.221 * tdL))
        return String(format: "LDL (Martin): %.1f mg/dL", ldl)
    }
    
    func calcGraceScore() -> String {
        guard let age = Double(graceAge), let hr = Double(graceHr),
              let sbp = Double(graceSbp), let creat = Double(graceCreatMgDl),
              age >= 20 && age <= 100, hr > 0, sbp > 0 else {
            return "Enter valid values"
        }
        var s = max(0.0, (age - 35.0)) * 0.042
        if hr > 100 { s += 0.5 }; if sbp < 100 { s += 0.8 }
        if creat > 1.5 { s += 0.6 }
        if graceCardiacArrest { s += 1.5 }; if graceStDev { s += 0.5 }
        if graceEnzElev { s += 0.4 }
        s += (Double(graceKillip) ?? 1.0) * 0.3
        return String(format: "GRACE 2.0: %.1f", s)
    }
    
    func calcHasBled() -> String {
        var s = 0
        if hBledHtn { s += 1 }; if hBledRenal { s += 1 }; if hBledLiver { s += 1 }
        if hBledStroke { s += 1 }; if hBledBleed { s += 1 }; if hBledLabileInr { s += 1 }
        if hBledElder { s += 1 }; if hBledDrugs { s += 1 }; if hBledAlcohol { s += 1 }
        let risk = s >= 3 ? "High" : "Low"
        return String(format: "HAS-BLED: %d (%@)", s, risk)
    }
    
    func calcMILBBB() -> String {
        var s = (Int(micConcST) ?? 0) + Int(Double(micDisStMm) ?? 0) / 5 + (micExConc ? 3 : 0)
        let likelihood = s >= 3 ? "High" : s >= 1 ? "Possible" : "Unlikely"
        return String(format: "Sgarbossa: %d (%@)", s, likelihood)
    }
    
    func calcMeanVascPres() -> String {
        guard let sys = Double(mvpSys), let dia = Double(mvpDia), sys > 0, dia > 0 else {
            return "Enter valid values"
        }
        return String(format: "MVP: %.1f mmHg", dia + (sys - dia) / 3.0)
    }
    

    
    func calcMeld() -> String {
        guard let cr = Double(meldCreatMgDl), let bil = Double(meldBilMgDl),
              let inr = Double(meldInr), cr >= 0, bil > 0, inr > 0 else {
            return "Enter valid values"
        }
        let raw = 3.78 * log(max(bil, 1.0)) + 11.2 * log(max(inr, 1.0))
                 + 9.57 * log(max(cr, 1.0)) + 10.0
        let m = Int(max(6, round(raw)))
        let mort = m <= 10 ? "~2%" : m <= 20 ? "~6%" : m <= 30 ? "~20%" : m <= 40 ? "~72%" : "~90%"
        return String(format: "MELD: %d (3-mo mortality: %@)", m, mort)
    }
    
    func calcMeld3() -> String {
        guard let cr = Double(meld3Creat), let bil = Double(meld3Bil),
              let inr = Double(meld3Inr), let na = Double(meld3NaMm),
              let alb = Double(meld3AlbGdL), cr >= 0, bil > 0, inr > 0, na > 0, alb > 0 else {
            return "Enter valid values"
        }
        let raw = 3.78 * log(max(bil, 1.0)) + 11.2 * log(max(inr, 1.0))
                 + 9.57 * log(max(cr, 1.0)) + 10.0
        let naAdj = max(1.0 - 0.0391 * (max(125.0, na) - 135.0), 0.8)
        let m = max(6, min(Int(round(raw * naAdj)), 40))
        return String(format: "MELD 3.0: %d", m)
    }
    

    
    func calcQtc() -> String {
        guard let hr = Double(qtcHr), let qt = Double(qtcQtMsec), hr > 0 else {
            return "Enter valid values"
        }
        let bazett = qt / sqrt(hr / 60.0)
        let frid = qt / pow(hr / 60.0, 0.33)
        let hodges = qt + 1.75 * (hr - 60.0)
        return String(format: "QTc Bazett: %.0f ms\nQTc Fridericsson: %.0f ms\nQTc Hodges: %.0f ms", bazett, frid, hodges)
    }
    
    func calcGeneva() -> String {
        var s = 0.0
        if genPrevDvtPe { s += 1.5 }; if genSurgery { s += 1.5 }; if genFracture { s += 1.5 }
        if genCancer { s += 2.0 }; if genUnilateral { s += 2.0 }; if genHemoptysis { s += 1.5 }
        if genHrGt80 { s += 2.0 }
        let prob = s <= 4 ? "Unlikely" : s <= 15 ? "Likely" : "High"
        return String(format: "Geneva: %.0f (%@)", Double(s), prob)
    }
    
    func calcRomhiltEstes() -> String {
        var s = 0
        if reLvHvolt { s += 3 }; if reStTchanges { s += 3 }
        s += max(0, Int(Double(reSvplusRvmm) ?? 0) - 25) / 5
        if reLaAbnormal { s += 3 }; if reUwave { s += 3 }
        let dx = s >= 5 ? "LVH probable" : s >= 4 ? "LVH possible" : "No LVH"
        return String(format: "Romhilt-Estes: %d (%@)", s, dx)
    }
    
    func calcTimiStemi() -> String {
        guard let age = Double(timiAge), let sys = Double(timiSysBP),
              let hr = Double(timiHr), age > 0, sys > 0, hr > 0 else {
            return "Enter valid values"
        }
        var s = 0
        if age >= 70 { s += 2 } else if age >= 50 { s += 1 }
        if timiAntStemi { s += 1 }
        if sys < 100 { s += 2 } else if sys < 120 { s += 1 }
        if hr > 100 { s += 2 } else if hr > 80 { s += 1 }
        s += Int(timiKillip) ?? 1
        let mort = s <= 2 ? "~1%" : s <= 4 ? "~3%" : s <= 6 ? "~8%" : s <= 9 ? "~15%" : "~30%"
        return String(format: "TIMI STEMI: %d (Mortality: %@)", s, mort)
    }
    
    func calcTimiUa() -> String {
        var s = 0
        if timiUaAge70 { s += 1 }; if timiUaRiskF3 { s += 1 }; if timiUaKnownCad { s += 1 }
        if timiUaAsprin { s += 1 }; if timiUaSevereAng { s += 1 }; if timiUaStDev { s += 1 }
        if timiUaEnzElev { s += 1 }
        let event = s <= 1 ? "~5%" : s <= 3 ? "~15%" : "~38%"
        return String(format: "TIMI UA: %d (Event rate: %@)", s, event)
    }
    
    func calcPelScore() -> String {
        var s = 0.0
        if pelPrevDvt { s += 1.5 }; if pelPrevPe { s += 1.5 }; if pelSurg4w { s += 1.5 }
        if pelHemoptysis { s += 1.0 }; if pelCancer { s += 1.0 }; if pelLegSwelling { s += 1.0 }
        if !pelAltDiag { s += 1.5 }
        return String(format: "Wells PE: %.0f (%@)", Double(s), s >= 4.0 ? "Likely" : "Unlikely")
    }
    

    

    
    func calcVldl() -> String {
        guard let tdL = Double(vldlTdL), let hdl = Double(vldlHdl),
              let ldl = Double(vldlLdl), tdL > 0 else { return "Enter valid values" }
        return String(format: "VLDL: %.1f mg/dL", tdL - hdl - ldl)
    }
    

    

    

    

    
    // MARK: - Helper Functions
    private func log(_ x: Double) -> Double { x > 0 ? log(x) : 0 }
    private func exp(_ x: Double) -> Double { exp(x) }
    
    // MARK: - Input View Builders
    private var cvdInputView: some View {
        VStack(spacing: 12) {
            TextField("Duration of diabetes (years)", text: $cvdDuration).keyboardType(.decimalPad)
            TextField("Age at onset (years)", text: $cvdAgeAtStart).keyboardType(.decimalPad)
            TextField("Albumin excretion rate (mg/min)", text: $cvdAlbuminExcretion).keyboardType(.decimalPad)
            TextField("Systolic BP (mmHg)", text: $cvdSystolicBP).keyboardType(.decimalPad)
            Toggle("Current smoker", isOn: $cvdSmoking)
            TextField("HbA1c (%)", text: $cvdHba1c).keyboardType(.decimalPad)
        }
    }
    

    

    
    
    

    

    

    

    
    private var chadsVascInputView: some View {
        VStack(spacing: 12) {
            Toggle("Congestive Heart Failure (+1)", isOn: $afHf)
            Toggle("Hypertension (+1)", isOn: $afHt)
            Toggle("Age ≥ 75 (+2)", isOn: $afAge70)
            Toggle("Diabetes (+1)", isOn: $afDm)
            Toggle("Stroke/TIA (+2)", isOn: $afStrk)
            Toggle("Vascular disease (+1)", isOn: $afVas)
            Toggle("Age 65-74 (+1)", isOn: $afAge65)
            Toggle("Female sex (+1)", isOn: $afFemale)
        }
    }
    

    
    private var cardiacOutputInputView: some View {
        VStack(spacing: 12) {
            TextField("Heart Rate (bpm)", text: $coHr).keyboardType(.decimalPad)
            TextField("Stroke Volume (mL)", text: $coSvMl).keyboardType(.decimalPad)
        }
    }
    
    private var cardiacOutputFickInputView: some View {
        VStack(spacing: 12) {
            TextField("VO2 (mL/min)", text: $coVo2MlMin).keyboardType(.decimalPad)
            TextField("AV O2 difference (mL/dL)", text: $coAvDiff).keyboardType(.decimalPad)
        }
    }
    
    private var cvRiskInputView: some View {
        VStack(spacing: 12) {
            TextField("Age (40-79)", text: $cvrAge).keyboardType(.decimalPad)
            TextField("Total Cholesterol (mg/dL)", text: $cvrTotalChol).keyboardType(.decimalPad)
            TextField("HDL Cholesterol (mg/dL)", text: $cvrHdl).keyboardType(.decimalPad)
            TextField("Systolic BP (mmHg)", text: $cvrSystolic).keyboardType(.decimalPad)
            Toggle("On BP medication (+1)", isOn: $cvrTreatedBp)
            Toggle("Current smoker (+1)", isOn: $cvrSmoking)
            Toggle("Diabetes (+1)", isOn: $cvrDiabetes)
        }
    }
    
    private var wellsDvtInputView: some View {
        VStack(spacing: 12) {
            Toggle("Active cancer (+1)", isOn: $wvtsCancer)
            Toggle("DVT/PE in last 4 weeks (+1.5)", isOn: $wvtsPrevDvt)
            Toggle("Surgery/immobilization 4w (+1.5)", isOn: $wvtsSurgery4w)
            Toggle("Hemoptysis (+1)", isOn: $wvtsHemoptysis)
            Toggle("Other malignancy (+1)", isOn: $wvtsCancer2)
            Toggle("Unilateral leg swelling (+1)", isOn: $wvtsLegSwelling)
            Toggle("Alternative diagnosis most likely (no points)", isOn: $wvtsAltDiag)
        }
    }
    
    private var euroScoreInputView: some View {
        VStack(spacing: 12) {
            TextField("Age", text: $esAge).keyboardType(.decimalPad)
            Toggle("Female (+1)", isOn: $esFemale)
            Toggle("Chronic pulmonary disease (+1)", isOn: $esChronPulm)
            TextField("Extra-cardiac arterial disease (0-3)", text: $esCvSt).keyboardType(.numberPad)
            TextField("Prior cardiac surgery (0-3)", text: $esPriorSurg).keyboardType(.numberPad)
            TextField("Ejection Fraction (%)", text: $ef).keyboardType(.decimalPad)
            Toggle("Aortic valve surgery (+1)", isOn: $esAortic)
            Toggle("Other valve surgery (+0.5)", isOn: $esOtherValve)
            TextField("Surgical urgency (0-3)", text: $esUrg).keyboardType(.numberPad)
            Toggle("Cerebrovascular disease (+1)", isOn: $esCerebro)
            Toggle("Thoracic aorta disease (+1.5)", isOn: $esThorAorta)
            TextField("Renal failure (0-3)", text: $esRenal).keyboardType(.numberPad)
            Toggle("Active endocarditis (+2)", isOn: $esEndo)
            Toggle("Unstable angina (+1)", isOn: $esUnstableAng)
            TextField("Serum Creatinine (mg/dL)", text: $esCreatMgDl).keyboardType(.decimalPad)
            Toggle("Emergency procedure (+1)", isOn: $esEmerg)
        }
    }
    
    private var friedewaldInputView: some View {
        VStack(spacing: 12) {
            TextField("Total Cholesterol (mg/dL)", text: $frTdL).keyboardType(.decimalPad)
            TextField("HDL Cholesterol (mg/dL)", text: $frHdl).keyboardType(.decimalPad)
            TextField("Triglycerides (mg/dL, must be < 400)", text: $frTrigMgDl).keyboardType(.decimalPad)
        }
    }
    
    private var friedewaldSIInputView: some View {
        VStack(spacing: 12) {
            TextField("Total Cholesterol (mmol/L)", text: $frTdL).keyboardType(.decimalPad)
            TextField("HDL Cholesterol (mmol/L)", text: $frHdl).keyboardType(.decimalPad)
            TextField("Triglycerides (mmol/L)", text: $frTrigMgDl).keyboardType(.decimalPad)
        }
    }
    
    private var martinLdlInputView: some View {
        VStack(spacing: 12) {
            TextField("Total Cholesterol (mg/dL)", text: $marTdL).keyboardType(.decimalPad)
            TextField("HDL Cholesterol (mg/dL)", text: $marHdl).keyboardType(.decimalPad)
            TextField("Triglycerides (mg/dL)", text: $marTrigMgDl).keyboardType(.decimalPad)
        }
    }
    
    private var graceScoreInputView: some View {
        VStack(spacing: 12) {
            TextField("Age (20-100)", text: $graceAge).keyboardType(.decimalPad)
            TextField("Heart Rate (bpm)", text: $graceHr).keyboardType(.decimalPad)
            TextField("Systolic BP (mmHg)", text: $graceSbp).keyboardType(.decimalPad)
            TextField("Serum Creatinine (mg/dL)", text: $graceCreatMgDl).keyboardType(.decimalPad)
            Toggle("Cardiac arrest at admission (+1.5)", isOn: $graceCardiacArrest)
            Toggle("ST-segment deviation (+0.5)", isOn: $graceStDev)
            Toggle("Elevated cardiac enzymes (+0.4)", isOn: $graceEnzElev)
            TextField("Killip class (1-4)", text: $graceKillip).keyboardType(.numberPad)
        }
    }
    
    private var hasBledInputView: some View {
        VStack(spacing: 12) {
            Toggle("Hypertension (+1)", isOn: $hBledHtn)
            Toggle("Abnormal renal/liver function (+1 each)", isOn: $hBledRenal)
            Toggle("Stroke history (+1)", isOn: $hBledStroke)
            Toggle("Bleeding diathesis (+1)", isOn: $hBledBleed)
            Toggle("Labile INR (+1)", isOn: $hBledLabileInr)
            Toggle("Elderly (age > 65) (+1)", isOn: $hBledElder)
            Toggle("Drugs (antiplatelet/NSAID) (+1)", isOn: $hBledDrugs)
            Toggle("Alcohol (≥8 drinks/wk) (+1)", isOn: $hBledAlcohol)
        }
    }
    
    private var miLbbbInputView: some View {
        VStack(spacing: 12) {
            TextField("Concordant ST elevation (mm)", text: $micConcST).keyboardType(.numberPad)
            TextField("Excessive discordant ST depression (mm)", text: $micDisStMm).keyboardType(.decimalPad)
            TextField("QRS duration (ms)", text: $micDisQrsd).keyboardType(.decimalPad)
            Toggle("Excessive concordant ST elevation (+3)", isOn: $micExConc)
        }
    }
    
    private var meanVascPresInputView: some View {
        VStack(spacing: 12) {
            TextField("Systolic BP (mmHg)", text: $mvpSys).keyboardType(.decimalPad)
            TextField("Diastolic BP (mmHg)", text: $mvpDia).keyboardType(.decimalPad)
        }
    }
    

    
    private var meldInputView: some View {
        VStack(spacing: 12) {
            TextField("Serum Creatinine (mg/dL)", text: $meldCreatMgDl).keyboardType(.decimalPad)
            TextField("Serum Bilirubin (mg/dL)", text: $meldBilMgDl).keyboardType(.decimalPad)
            TextField("INR", text: $meldInr).keyboardType(.decimalPad)
        }
    }
    
    private var meld3InputView: some View {
        VStack(spacing: 12) {
            TextField("Serum Creatinine (mg/dL)", text: $meld3Creat).keyboardType(.decimalPad)
            TextField("Serum Bilirubin (mg/dL)", text: $meld3Bil).keyboardType(.decimalPad)
            TextField("INR", text: $meld3Inr).keyboardType(.decimalPad)
            TextField("Serum Sodium (mmol/L)", text: $meld3NaMm).keyboardType(.decimalPad)
            TextField("Serum Albumin (g/dL)", text: $meld3AlbGdL).keyboardType(.decimalPad)
        }
    }
    

    
    private var qtcInputView: some View {
        VStack(spacing: 12) {
            TextField("Heart Rate (bpm)", text: $qtcHr).keyboardType(.decimalPad)
            TextField("QT interval (msec)", text: $qtcQtMsec).keyboardType(.decimalPad)
        }
    }
    
    private var genevaScoreInputView: some View {
        VStack(spacing: 12) {
            Toggle("Previous DVT/PE (+1.5)", isOn: $genPrevDvtPe)
            Toggle("Surgery or fracture within 4 weeks (+1.5 each)", isOn: $genSurgery)
            Toggle("Active malignancy (+2)", isOn: $genCancer)
            Toggle("Unilateral lower limb swelling (+2)", isOn: $genUnilateral)
            Toggle("Hemoptysis (+1.5)", isOn: $genHemoptysis)
            Toggle("Heart rate > 80 bpm (+2)", isOn: $genHrGt80)
        }
    }
    
    private var romhiltEstesInputView: some View {
        VStack(spacing: 12) {
            Toggle("LVH voltage criteria (+3)", isOn: $reLvHvolt)
            Toggle("ST-T changes (+3)", isOn: $reStTchanges)
            TextField("S in V1 + R in V5/V6 (mm)", text: $reSvplusRvmm).keyboardType(.decimalPad)
            Toggle("Left atrial abnormality (+3)", isOn: $reLaAbnormal)
            Toggle("U wave (+3)", isOn: $reUwave)
        }
    }
    
    private var timiStemiInputView: some View {
        VStack(spacing: 12) {
            TextField("Age", text: $timiAge).keyboardType(.decimalPad)
            Toggle("Anterior MI or LBBB (+1)", isOn: $timiAntStemi)
            TextField("Systolic BP (mmHg)", text: $timiSysBP).keyboardType(.decimalPad)
            TextField("Heart Rate (bpm)", text: $timiHr).keyboardType(.decimalPad)
            TextField("Killip class (1-4)", text: $timiKillip).keyboardType(.numberPad)
        }
    }
    
    private var timiUaInputView: some View {
        VStack(spacing: 12) {
            Toggle("Age ≥ 65 (+1)", isOn: $timiUaAge70)
            Toggle("≥ 3 CAD risk factors (+1)", isOn: $timiUaRiskF3)
            Toggle("Known CAD (+1)", isOn: $timiUaKnownCad)
            Toggle("Aspirin use in past 14 days (+1)", isOn: $timiUaAsprin)
            Toggle("Severe angina (≥2 episodes/24h) (+1)", isOn: $timiUaSevereAng)
            Toggle("ST deviation (≥ 0.05 mV) (+1)", isOn: $timiUaStDev)
            Toggle("Elevated cardiac markers (+1)", isOn: $timiUaEnzElev)
        }
    }
    
    private var pelScoreInputView: some View {
        VStack(spacing: 12) {
            Toggle("Previous DVT/PE (+1.5)", isOn: $pelPrevDvt)
            Toggle("Previous PE (+1.5)", isOn: $pelPrevPe)
            Toggle("Surgery/trauma within 4 weeks (+1.5)", isOn: $pelSurg4w)
            Toggle("Hemoptysis (+1)", isOn: $pelHemoptysis)
            Toggle("Active malignancy (+1)", isOn: $pelCancer)
            Toggle("Unilateral leg swelling (+1)", isOn: $pelLegSwelling)
            Toggle("PE is #1 diagnosis or equally likely (no points)", isOn: $pelAltDiag)
        }
    }
    

    

    
    private var vldlInputView: some View {
        VStack(spacing: 12) {
            TextField("Total Cholesterol (mg/dL)", text: $vldlTdL).keyboardType(.decimalPad)
            TextField("HDL Cholesterol (mg/dL)", text: $vldlHdl).keyboardType(.decimalPad)
            TextField("LDL Cholesterol (mg/dL)", text: $vldlLdl).keyboardType(.decimalPad)
        }
    }
    

    

    

    

    
}
