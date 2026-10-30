import Foundation

/// Calculator specs for the growthAnthropometrics category.
let growthAnthropometricsCalculatorSpecs: [MedCalcSpec] = [
    MedCalcSpec(
        fileName: "BodyMassIndex.htm",
        guide: """
        Body mass index (BMI) classifies adult weight relative to height. Weigh the patient in light clothing without shoes and measure standing height; enter weight in kg and height in cm.

        Interpretation — BMI (kg/m²):
        • <18.5: Below normal weight
        • 18.5–<25: Normal weight
        • 25–<30: Overweight
        • 30–<35: Class I obesity
        • 35–<40: Class II obesity
        • ≥40: Class III obesity
        """,
        equation: "BMI = (Weight_lb/2.205) / (Height_in/39.37)²",
        inputs: [
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters")),
            MedCalcInput("weight", "Weight (kg)", .number(unitHint: "kilograms"))
        ],
        compute: { v in
            guard let h = v.number("height"), let w = v.number("weight"), h > 0, w > 0 else { return "" }
            let bmi = w / pow(h / 100.0, 2)
            let category: String
            switch bmi {
            case ..<18.5: category = "Below normal weight"
            case ..<25: category = "Normal weight"
            case ..<30: category = "Overweight"
            case ..<35: category = "Class I Obesity"
            case ..<40: category = "Class II Obesity"
            default: category = "Class III Obesity"
            }
            return String(format: "BMI: %.1f kg/m²\n%@", bmi, category)
        }
    ),

    MedCalcSpec(
        fileName: "BodySurfaceArea.htm",
        guide: """
        Body surface area (BSA) by the Du Bois formula is used to normalize drug doses (e.g., chemotherapy), cardiac index, and metabolic rates. Enter height in cm and weight in kg.

        Typical adult BSA is about 1.7 m²; values below ~1.5 or above ~2.0 are worth double-checking.
        """,
        equation: "BSA = 0.007184 × Height(cm)^0.725 × Weight(kg)^0.425",
        inputs: [
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters")),
            MedCalcInput("weight", "Weight (kg)", .number(unitHint: "kilograms"))
        ],
        compute: { v in
            guard let h = v.number("height"), let w = v.number("weight"), h > 0, w > 0 else { return "" }
            let bsa = 0.007184 * pow(h, 0.725) * pow(w, 0.425)
            return String(format: "BSA (Du Bois): %.3f m²", bsa)
        }
    ),

    MedCalcSpec(
        fileName: "MifflinStJeor.htm",
        guide: """
        The Mifflin-St Jeor equation estimates resting energy expenditure (REE, kcal/day) — the calories burned at rest. It is more accurate than Harris-Benedict for most adults and is used to build nutrition plans. Enter age in years, weight in kg, height in cm.

        Interpretation: multiply REE by an activity factor (~1.2 sedentary to ~1.7 very active) to estimate total daily energy expenditure.
        """,
        equation: "REE = 10×Weight(kg) + 6.25×Height(cm) − 5×Age(yr) + Sex (Male +5, Female −161)",
        inputs: [
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"])),
            MedCalcInput("age", "Age (years)", .number(unitHint: "years")),
            MedCalcInput("weight", "Weight (kg)", .number(unitHint: "kilograms")),
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters"))
        ],
        compute: { v in
            guard let sex = v.selection("sex"), let age = v.number("age"),
                  let w = v.number("weight"), let h = v.number("height"),
                  age > 0, w > 0, h > 0 else { return "" }
            let ree = 10 * w + 6.25 * h - 5 * age + (sex == 0 ? -161 : 5)
            return String(format: "Resting Energy Expenditure: %.0f kcal/day", ree)
        }
    ),

    MedCalcSpec(
        fileName: "IdealBodyWgt.htm",
        guide: """
        Ideal body weight (IBW) estimates a healthy weight for height and is used when actual body weight would distort dosing or fluid calculations. Enter height in cm — the result is in kg.

        Interpretation: compare with actual weight; if actual exceeds IBW by 20–30% or more, consider using adjusted body weight for dosing per your institution's policy.
        """,
        equation: "IBW = Height(m)² × Sex (Male 23, Female 21.5)",
        inputs: [
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters")),
            MedCalcInput("sex", "Sex", .choice(options: ["Female", "Male"]))
        ],
        compute: { v in
            guard let h = v.number("height"), let sex = v.selection("sex"), h > 0 else { return "" }
            let meters = h / 100.0
            let ibw = pow(meters, 2) * (sex == 0 ? 21.5 : 23.0)
            return String(format: "Ideal Body Weight: %.1f kg (%@)", ibw, sex == 0 ? "Female" : "Male")
        }
    ),

    MedCalcSpec(
        fileName: "LeanBodyWgtF.htm",
        guide: """
        Lean body weight (LBW) for females estimates fat-free mass from height alone (Burton/Sawchuk-Zaske). Used in pharmacokinetic dosing when lean mass matters more than total weight. Enter height in cm — the result is in kg.
        """,
        equation: "LBW[kg] = 0.65 × Height[cm] − 50.74",
        inputs: [
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters"))
        ],
        compute: { v in
            guard let h = v.number("height"), h > 0 else { return "" }
            return String(format: "Lean Body Weight (Female): %.1f kg", 0.65 * h - 50.74)
        }
    ),

    MedCalcSpec(
        fileName: "LeanBodyWgtM.htm",
        guide: """
        Lean body weight (LBW) for males estimates fat-free mass from height alone (Burton/Sawchuk-Zaske). Used in pharmacokinetic dosing when lean mass matters more than total weight. Enter height in cm — the result is in kg.
        """,
        equation: "LBW[kg] = 0.73 × Height[cm] − 59.42",
        inputs: [
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters"))
        ],
        compute: { v in
            guard let h = v.number("height"), h > 0 else { return "" }
            return String(format: "Lean Body Weight (Male): %.1f kg", 0.73 * h - 59.42)
        }
    ),

    MedCalcSpec(
        fileName: "BodyMassIndexBoys.htm",
        guide: """
        BMI-for-age percentile for boys aged 2–20 years using the CDC LMS growth charts. Weigh in light clothing, measure standing height without shoes; enter age in years, height in cm, weight in kg.

        Interpretation (CDC classification):
        • <5th percentile: Underweight
        • 5th to <85th percentile: Healthy weight
        • 85th to <95th percentile: Overweight
        • ≥95th to <120% of the 95th percentile and <35 kg/m²: Class I obesity
        • ≥120% to <140% of the 95th percentile or ≥35 kg/m² (whichever is lower): Class II obesity
        • ≥140% of the 95th percentile or ≥40 kg/m² (whichever is lower): Class III obesity
        """,
        equation: "BMI = Weight/(Height/100)²; Z-score from CDC LMS table; Percentile = Φ(Z)",
        inputs: [
            MedCalcInput("age", "Age (years)", .number(unitHint: "2–20 years")),
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters")),
            MedCalcInput("weight", "Weight (kg)", .number(unitHint: "kilograms"))
        ],
        compute: { v in
            guard let age = v.number("age"), let h = v.number("height"), let w = v.number("weight"),
                  age >= 2, age <= 20, h > 0, w > 0 else { return "" }
            let bmi = w / pow(h / 100.0, 2)
            guard let z = MedCalcLms.zScore(MedCalcLmsData.bmiBoys, age * 12, bmi),
                  let p95bmi = MedCalcLms.bmiAtPercentile(MedCalcLmsData.bmiBoys, age * 12) else { return "" }
            let percentile = MedCalcLms.percentile(z)
            let classification: String
            if percentile < 5 {
                classification = "Underweight"
            } else if percentile < 85 {
                classification = "Healthy weight"
            } else if percentile < 95 {
                classification = "Overweight"
            } else if bmi < 1.2 * p95bmi && bmi < 35 {
                classification = "Class I obesity"
            } else if bmi >= 1.4 * p95bmi || bmi >= 40 {
                classification = "Class III obesity"
            } else {
                classification = "Class II obesity"
            }
            return String(format: "BMI: %.1f kg/m²\n%.1fth percentile for age (z-score %.2f)\n95th-percentile BMI: %.1f\nClassification: %@",
                          bmi, percentile, z, p95bmi, classification)
        }
    ),

    MedCalcSpec(
        fileName: "BodyMassIndexGirls.htm",
        guide: """
        BMI-for-age percentile for girls aged 2–20 years using the CDC LMS growth charts. Weigh in light clothing, measure standing height without shoes; enter age in years, height in cm, weight in kg.

        Interpretation (CDC classification):
        • <5th percentile: Underweight
        • 5th to <85th percentile: Healthy weight
        • 85th to <95th percentile: Overweight
        • ≥95th to <120% of the 95th percentile and <35 kg/m²: Class I obesity
        • ≥120% to <140% of the 95th percentile or ≥35 kg/m² (whichever is lower): Class II obesity
        • ≥140% of the 95th percentile or ≥40 kg/m² (whichever is lower): Class III obesity
        """,
        equation: "BMI = Weight/(Height/100)²; Z-score from CDC LMS table; Percentile = Φ(Z)",
        inputs: [
            MedCalcInput("age", "Age (years)", .number(unitHint: "2–20 years")),
            MedCalcInput("height", "Height (cm)", .number(unitHint: "centimeters")),
            MedCalcInput("weight", "Weight (kg)", .number(unitHint: "kilograms"))
        ],
        compute: { v in
            guard let age = v.number("age"), let h = v.number("height"), let w = v.number("weight"),
                  age >= 2, age <= 20, h > 0, w > 0 else { return "" }
            let bmi = w / pow(h / 100.0, 2)
            guard let z = MedCalcLms.zScore(MedCalcLmsData.bmiGirls, age * 12, bmi),
                  let p95bmi = MedCalcLms.bmiAtPercentile(MedCalcLmsData.bmiGirls, age * 12) else { return "" }
            let percentile = MedCalcLms.percentile(z)
            let classification: String
            if percentile < 5 {
                classification = "Underweight"
            } else if percentile < 85 {
                classification = "Healthy weight"
            } else if percentile < 95 {
                classification = "Overweight"
            } else if bmi < 1.2 * p95bmi && bmi < 35 {
                classification = "Class I obesity"
            } else if bmi >= 1.4 * p95bmi || bmi >= 40 {
                classification = "Class III obesity"
            } else {
                classification = "Class II obesity"
            }
            return String(format: "BMI: %.1f kg/m²\n%.1fth percentile for age (z-score %.2f)\n95th-percentile BMI: %.1f\nClassification: %@",
                          bmi, percentile, z, p95bmi, classification)
        }
    )
]
