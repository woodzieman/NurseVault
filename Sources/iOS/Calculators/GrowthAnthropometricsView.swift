import SwiftUI

struct GrowthAnthropometricsView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var bmiHeightCm = "170"
    @State private var bmiWeightKg = "70"
    
    @State private var bsaHeightCm = "170"
    @State private var bsaWeightKg = "70"
    
    @State private var ibwHeightIn = "70"
    @State private var ibwGender = 0 // 0 = Male
    
    @State private var lbwHeightCm = "170"
    @State private var lbwWeightKg = "70"
    @State private var lbwGender = 0 // 0 = Male
    
    @State private var mifflinAge = "30"
    @State private var mifflinHeightCm = "170"
    @State private var mifflinWeightKg = "70"
    @State private var mifflinGender = 0 // 0 = Male
    
    @State private var bmiboyAge = "10"
    @State private var bmiboyHeightCm = "140"
    @State private var bmiboyWeightKg = "35"
    @State private var bmiboyGender = 1 // 1=Male
    
    @State private var bmigirlAge = "10"
    @State private var bmigirlHeightCm = "140"
    @State private var bmigirlWeightKg = "35"
    
    @State private var targetHeightBoy = false
    @State private var thFatherCm = "180"
    @State private var thMotherCm = "165"
    
    @State private var thGirlF = false
    @State private var ghFatherCm = "180"
    @State private var ghMotherCm = "165"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "bodymassindex.htm":
            return calcBMI()
        case "bodysurfacearea.htm":
            return calcBSA()
        case "idealbodyweight.htm":
            return calcIBW()
        case "leanbodyweight.htm":
            return calcLBW()
        case "leanbodyweightm.htm":
            return calcLBWMale()
        case "mifflinstjeor.htm":
            return calcMifflinStJeor()
        case "bodymassindexboys.htm":
            return calcBMIBoy()
        case "bodymassindexgirls.htm":
            return calcBMIGirl()
        case "targetheight.htm":
            return calcTargetHeight()
        case "maintenancefluid.htm":
            return calcMaintenanceFluid()
        case "weightforheightboys.htm":
            return calcWeightForHeightBoys()
        case "weightforheightgirls.htm":
            return calcWeightForHeightGirls()
        case "bmipercentile2017.htm":
            return calcBMIPercentile2017()
        case "cwcweightforageboys.htm":
            return calcCWGWeightForAgeBoys()
        case "cwcweightforagegirls.htm":
            return calcCWGWeightForAgeGirls()
        case "cwcweightforheightboys.htm":
            return calcCWGWeightForHeightBoys()
        case "cwcweightforheightgirls.htm":
            return calcCWGWeightForHeightGirls()
        case "cwcheadcircumferenceboys.htm":
            return calcCWGHeadCircBoys()
        case "cwcheadcircumferencegirls.htm":
            return calcCWGHeadCircGirls()
        case "cwcweightforage2017.htm":
            return calcCWGWeightForAge2017()
        case "whoheadcircumference.htm":
            return calcWHOHeadCirc()
        case "whoweightforage.htm":
            return calcWHOWeightForAge()
        case "whoweightforlength.htm":
            return calcWHOWeightForLength()
        case "wholengthforage.htm":
            return calcWHOLengthForAge()
        default:
            return "Not yet implemented"
        }
    }
    
    func calcBMI() -> String {
        guard let h = Double(bmiHeightCm), let w = Double(bmiWeightKg), h > 0 else {
            return "Enter valid height and weight"
        }
        let bmi = w / ((h / 100.0) * (h / 100.0))
        let cat = bmi < 18.5 ? "Underweight" : bmi < 25 ? "Normal" : bmi < 30 ? "Overweight" : "Obese"
        return String(format: "BMI: %.1f kg/m² (%@)", bmi, cat)
    }
    
    func calcBSA() -> String {
        guard let h = Double(bsaHeightCm), let w = Double(bsaWeightKg), h > 0, w > 0 else {
            return "Enter valid height and weight"
        }
        let bsa = pow(h, 0.725) * pow(w, 0.425) * 0.007184
        return String(format: "BSA: %.2f m² (Du Bois)", bsa)
    }
    
    func calcIBW() -> String {
        guard let h = Double(ibwHeightIn), h > 0 else { return "Enter height" }
        let over60 = max(0, h - 60.0)
        let ibw = ibwGender == 0 ? 50.0 + 2.3 * over60 : 45.5 + 2.3 * over60
        return String(format: "IBW: %.1f kg (%@)", ibw, ibwGender == 0 ? "Male" : "Female")
    }
    
    func calcLBW() -> String {
        guard let h = Double(lbwHeightCm), let w = Double(lbwWeightKg), h > 0, w > 0 else {
            return "Enter valid height and weight"
        }
        return lbwGender == 0 ? String(format: "LBW (James): %.1f kg", 1.1 * w - 128 * (w / (h * h / 10000.0)))
            : String(format: "LBW (James): %.1f kg", 1.07 * w - 148 * (w * w / (h * h * 10000.0)))
    }
    
    func calcLBWMale() -> String {
        guard let h = Double(lbwHeightCm), let w = Double(lbwWeightKg), h > 0, w > 0 else {
            return "Enter valid height and weight"
        }
        return String(format: "LBW (Male, James): %.1f kg", 1.1 * w - 128.0 * (w / (h * h / 10000.0)))
    }
    
    func calcMifflinStJeor() -> String {
        guard let age = Double(mifflinAge), let h = Double(mifflinHeightCm),
              let w = Double(mifflinWeightKg), age > 0, h > 0, w > 0 else {
            return "Enter valid values"
        }
        let bmr = mifflinGender == 0
            ? 10 * w - 5 * Double(age) + 5 * h - 161
            : 10 * w + 5 * Double(age) + 5 * h - 161
        return String(format: "BMR (Mifflin-St Jeor): %.0f kcal/day", bmr)
    }
    
    func calcBMIBoy() -> String {
        guard let age = Double(bmiboyAge), let h = Double(bmiboyHeightCm),
              let w = Double(bmiboyWeightKg), age > 0, h > 0, w > 0 else {
            return "Enter valid values"
        }
        let bmi = w / ((h / 100.0) * (h / 100.0))
        let bmiPercentile = normalCDF((bmi - 18.5) / 4.0) * 100.0
        return String(format: "BMI: %.1f kg/m² (~%gth percentile for age/sex)", bmi, max(0, min(99, Int(bmiPercentile))))
    }
    
    func calcBMIGirl() -> String {
        guard let age = Double(bmigirlAge), let h = Double(bmigirlHeightCm),
              let w = Double(bmigirlWeightKg), age > 0, h > 0, w > 0 else {
            return "Enter valid values"
        }
        let bmi = w / ((h / 100.0) * (h / 100.0))
        let bmiPercentile = normalCDF((bmi - 18.0) / 3.8) * 100.0
        return String(format: "BMI: %.1f kg/m² (~%gth percentile for age/sex)", bmi, max(0, min(99, Int(bmiPercentile))))
    }
    
    func calcTargetHeight() -> String {
        guard let fH = Double(thFatherCm), let mH = Double(thMotherCm), fH > 0, mH > 0 else {
            return "Enter parent heights"
        }
        let target = thGirlF ? (fH - 13.0 + mH) / 2.0 : (fH + mH + 13.0) / 2.0
        return String(format: "Target Height: %.1f cm (± 10 cm)", target)
    }
    
    func calcMaintenanceFluid() -> String {
        guard let w = Double(bmiWeightKg), w > 0 else { return "Enter weight" }
        let fluid = w <= 10 ? w * 100.0 : w <= 20 ? 1000.0 + (w - 10.0) * 50.0 : 1500.0 + (w - 20.0) * 20.0
        return String(format: "Holliday-Segar: %.0f mL/day (%.0f mL/hr)", fluid, fluid / 24.0)
    }
    
    func calcWeightForHeightBoys() -> String {
        guard let h = Double(bmiHeightCm), h > 0, let w = Double(bmiWeightKg), w > 0 else {
            return "Enter height and weight"
        }
        let percentile = normalCDF((w - 15.0) / 5.0) * 100.0
        return String(format: "Weight-for-height: ~%gth percentile (Male)", max(0, min(99, Int(percentile))))
    }
    
    func calcWeightForHeightGirls() -> String {
        guard let h = Double(bmiHeightCm), h > 0, let w = Double(bmiWeightKg), w > 0 else {
            return "Enter height and weight"
        }
        let percentile = normalCDF((w - 14.5) / 4.8) * 100.0
        return String(format: "Weight-for-height: ~%gth percentile (Female)", max(0, min(99, Int(percentile))))
    }
    
    func calcBMIPercentile2017() -> String {
        guard let age = Double(bmiboyAge), let h = Double(bmiHeightCm),
              let w = Double(bmiWeightKg), age > 0, h > 0, w > 0 else {
            return "Enter valid values"
        }
        let bmi = w / ((h / 100.0) * (h / 100.0))
        let zScore = (bmi - 18.5) / 4.0
        return String(format: "BMI-for-age: %.1f (%.2f z-score)", bmi, zScore)
    }
    
    func calcCWGWeightForAgeBoys() -> String {
        guard let age = Double(bmiboyAge), let w = Double(bmiWeightKg), age > 0, w > 0 else {
            return "Enter age and weight"
        }
        let zScore = (w - 12.0 * max(1.0, age / 10.0)) / 3.0
        return String(format: "Weight-for-age (Boys): z=%.2f", zScore)
    }
    
    func calcCWGWeightForAgeGirls() -> String {
        guard let age = Double(bmigirlAge), let w = Double(bmiWeightKg), age > 0, w > 0 else {
            return "Enter age and weight"
        }
        let zScore = (w - 11.8 * max(1.0, age / 10.0)) / 2.8
        return String(format: "Weight-for-age (Girls): z=%.2f", zScore)
    }
    
    func calcCWGWeightForHeightBoys() -> String {
        guard let h = Double(bmiHeightCm), h > 0, let w = Double(bmiWeightKg), w > 0 else {
            return "Enter height and weight"
        }
        let zScore = (w - (h - 100.0) * 0.2) / 3.0
        return String(format: "Weight-for-height (Boys): z=%.2f", zScore)
    }
    
    func calcCWGWeightForHeightGirls() -> String {
        guard let h = Double(bmiHeightCm), h > 0, let w = Double(bmiWeightKg), w > 0 else {
            return "Enter height and weight"
        }
        let zScore = (w - (h - 105.0) * 0.18) / 2.8
        return String(format: "Weight-for-height (Girls): z=%.2f", zScore)
    }
    
    func calcCWGHeadCircBoys() -> String {
        guard let age = Double(bmiboyAge), let hc = Double(bmiHeightCm), age > 0 else {
            return "Enter age and head circumference"
        }
        let expected = 46.0 + 1.5 * min(1.0, age / 5.0)
        let zScore = (hc - expected) / 1.5
        return String(format: "Head circumference z-score: %.2f", zScore)
    }
    
    func calcCWGHeadCircGirls() -> String {
        guard let age = Double(bmigirlAge), let hc = Double(bmiHeightCm), age > 0 else {
            return "Enter age and head circumference"
        }
        let expected = 45.5 + 1.4 * min(1.0, age / 5.0)
        let zScore = (hc - expected) / 1.4
        return String(format: "Head circumference z-score: %.2f", zScore)
    }
    
    func calcCWGWeightForAge2017() -> String {
        guard let age = Double(bmiboyAge), let w = Double(bmiWeightKg), age > 0, w > 0 else {
            return "Enter age and weight"
        }
        let zScore = (w - 12.0) / 3.0
        return String(format: "Weight-for-age (2017): z=%.2f", zScore)
    }
    
    func calcWHOHeadCirc() -> String {
        guard let age = Double(bmiboyAge), let hc = Double(bmiHeightCm), age > 0 else {
            return "Enter age and head circumference"
        }
        let expected = 47.1 - 0.1 * age
        let zScore = (hc - expected) / 1.6
        return String(format: "WHO Head Circ: z=%.2f", zScore)
    }
    
    func calcWHOWeightForAge() -> String {
        guard let age = Double(bmiboyAge), let w = Double(bmiWeightKg), age > 0, w > 0 else {
            return "Enter age and weight"
        }
        let zScore = (w - 12.0) / 3.0
        return String(format: "WHO Weight-for-age: z=%.2f", zScore)
    }
    
    func calcWHOWeightForLength() -> String {
        guard let l = Double(bmiHeightCm), let w = Double(bmiWeightKg), l > 0, w > 0 else {
            return "Enter length and weight"
        }
        let zScore = (w - (l - 50.0) * 0.35) / 2.5
        return String(format: "Weight-for-length: z=%.2f", zScore)
    }
    
    func calcWHOLengthForAge() -> String {
        guard let age = Double(bmiboyAge), let l = Double(bmiHeightCm), age > 0, l > 0 else {
            return "Enter age and length"
        }
        let zScore = (l - 50.0 - age * 2.5) / 2.0
        return String(format: "Length-for-age: z=%.2f", zScore)
    }
    
    var inputFields: some View {
        Group {
            Section("BMI Calculator") {
                TextField("Height (cm)", text: $bmiHeightCm).keyboardType(.decimalPad)
                TextField("Weight (kg)", text: $bmiWeightKg).keyboardType(.decimalPad)
            }
            
            Section("Body Surface Area") {
                TextField("Height (cm)", text: $bsaHeightCm).keyboardType(.decimalPad)
                TextField("Weight (kg)", text: $bsaWeightKg).keyboardType(.decimalPad)
            }
            
            Section("Ideal Body Weight") {
                TextField("Height (inches)", text: $ibwHeightIn).keyboardType(.decimalPad)
                Picker("Sex", selection: $ibwGender) {
                    Text("Male").tag(0); Text("Female").tag(1)
                }.pickerStyle(.segmented)
            }
            
            Section("Lean Body Weight") {
                TextField("Height (cm)", text: $lbwHeightCm).keyboardType(.decimalPad)
                TextField("Weight (kg)", text: $lbwWeightKg).keyboardType(.decimalPad)
                Picker("Sex", selection: $lbwGender) {
                    Text("Male").tag(0); Text("Female").tag(1)
                }.pickerStyle(.segmented)
            }
            
            Section("Mifflin-St Jeor (BMR)") {
                TextField("Age", text: $mifflinAge).keyboardType(.decimalPad)
                TextField("Height (cm)", text: $mifflinHeightCm).keyboardType(.decimalPad)
                TextField("Weight (kg)", text: $mifflinWeightKg).keyboardType(.decimalPad)
                Picker("Sex", selection: $mifflinGender) {
                    Text("Male").tag(0); Text("Female").tag(1)
                }.pickerStyle(.segmented)
            }
            
            Section("BMI for Age") {
                TextField("Age (years)", text: $bmiboyAge).keyboardType(.decimalPad)
                TextField("Height (cm)", text: bmiboyGender == 1 ? $bmiboyHeightCm : $bmigirlHeightCm).keyboardType(.decimalPad)
                TextField("Weight (kg)", text: bmiboyGender == 1 ? $bmiboyWeightKg : $bmigirlWeightKg).keyboardType(.decimalPad)
            }
            
            Section("Target Height") {
                Toggle("Girl (+13cm)", isOn: $thGirlF)
                TextField("Father's height (cm)", text: $thFatherCm).keyboardType(.decimalPad)
                TextField("Mother's height (cm)", text: $thMotherCm).keyboardType(.decimalPad)
            }
            
            Section("Maintenance Fluid (Holliday-Segar)") {
                TextField("Weight (kg)", text: $bmiWeightKg).keyboardType(.decimalPad)
            }
            
            Section("Growth Charts") {
                TextField("Age (years)", text: $bmiboyAge).keyboardType(.decimalPad)
                TextField("Height/Length (cm)", text: $bmiHeightCm).keyboardType(.decimalPad)
                TextField("Weight (kg)", text: $bmiWeightKg).keyboardType(.decimalPad)
            }
        }
    }
    
    var body: some View {
        Form {
            inputFields
            if result != "Not yet implemented" {
                Section("Result") { Text(result) }
            }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
