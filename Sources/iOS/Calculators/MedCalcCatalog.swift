import Foundation

// This file is shared: it is compiled into the app, the widget extensions, and the watch app.


struct CalculatorInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let fileName: String
    let merckPage: String?
    
    init(id: String, title: String, category: String, fileName: String, merckPage: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.fileName = fileName
        self.merckPage = merckPage
    }
}


enum CalculatorCategory: String, CaseIterable {
    case cardiovascular = "Cardiovascular"
    case criticalcarescores = "Critical Care Scores"
    case ebmandstatistics = "EBM & Statistics"
    case electrolytesandacidbase = "Electrolytes & Acid-Base"
    case endocrinology = "Endocrinology"
    case gastroenterology = "Gastroenterology"
    case growthandanthropometrics = "Growth & Anthropometrics"
    case hematology = "Hematology"
    case hepatic = "Hepatic"
    case infectiousdisease = "Infectious Disease"
    case mentalhealthandscreening = "Mental Health & Screening"
    case neonatology = "Neonatology"
    case neurology = "Neurology"
    case oncologyandrisk = "Oncology & Risk"
    case other = "Other"
    case pediatrics = "Pediatrics"
    case pharmacologyandtoxicology = "Pharmacology & Toxicology"
    case pulmonary = "Pulmonary"
    case renal = "Renal"
    case respiratoryandgasexchange = "Respiratory & Gas Exchange"
    case rheumatology = "Rheumatology"
    case sleepmedicine = "Sleep Medicine"
    case substanceuse = "Substance Use"
    case unitconversions = "Unit Conversions"
    case urology = "Urology"
}

extension CalculatorCategory {
    var displayTitle: String {
        switch self {
        case .cardiovascular:
            return "Cardiovascular"
        case .criticalcarescores:
            return "Critical Care"
        case .ebmandstatistics:
            return "Statistics"
        case .electrolytesandacidbase:
            return "Electrolytes"
        case .endocrinology:
            return "Endocrinology"
        case .gastroenterology:
            return "Gastroenterology"
        case .growthandanthropometrics:
            return "Growth"
        case .hematology:
            return "Hematology"
        case .hepatic:
            return "Hepatic"
        case .infectiousdisease:
            return "Infectious"
        case .mentalhealthandscreening:
            return "Mental Health"
        case .neonatology:
            return "Neonatology"
        case .neurology:
            return "Neurology"
        case .oncologyandrisk:
            return "Oncology"
        case .other:
            return "Other"
        case .pediatrics:
            return "Pediatrics"
        case .pharmacologyandtoxicology:
            return "Toxicology"
        case .pulmonary:
            return "Pulmonary"
        case .renal:
            return "Renal"
        case .respiratoryandgasexchange:
            return "Respiratory"
        case .rheumatology:
            return "Rheumatology"
        case .sleepmedicine:
            return "Sleep"
        case .substanceuse:
            return "Substance Use"
        case .unitconversions:
            return "Conversions"
        case .urology:
            return "Urology"
        }
    }
}

func makeCalculatorList() -> [CalculatorInfo] {
    var result: [CalculatorInfo] = []
    result.append(CalculatorInfo(id: "CVDinDM1htm", title: "5-Year Risk of Cardiovascular Disease in Type I Diabetes", category: "Cardiovascular", fileName: "CVDinDM1.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/5-year-risk-of-cardiovascular-disease-in-type-i-diabetes"))
    result.append(CalculatorInfo(id: "AAGradienthtm", title: "A-a Gradient", category: "Respiratory & Gas Exchange", fileName: "AAGradient.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/a-a-gradient"))
    result.append(CalculatorInfo(id: "abchtm", title: "ABC Score for Prediction of 30-Day Mortality in Acute GI Bleeding", category: "Gastroenterology", fileName: "abc.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/abc-score-for-prediction-of-30-day-mortality-in-acute-gi-bleeding"))
    result.append(CalculatorInfo(id: "AbsEoCounthtm", title: "Absolute Eosinophil Count", category: "Hematology", fileName: "AbsEoCount.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/absolute-eosinophil-count"))
    result.append(CalculatorInfo(id: "AbsLymphocyteCnthtm", title: "Absolute Lymphocyte Count", category: "Hematology", fileName: "AbsLymphocyteCnt.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/absolute-lymphocyte-count"))
    result.append(CalculatorInfo(id: "AbsNeutrophileCnthtm", title: "Absolute Neutrophil Count", category: "Hematology", fileName: "AbsNeutrophileCnt.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/absolute-neutrophil-count"))
    result.append(CalculatorInfo(id: "AbsReticCnthtm", title: "Absolute Reticulocyte Count", category: "Hematology", fileName: "AbsReticCnt.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/absolute-reticulocyte-count"))
    result.append(CalculatorInfo(id: "acetaminophentox2023htm", title: "Acetaminophen (Paracetamol) Toxicity Assessment (Revised 2023)", category: "Pharmacology & Toxicology", fileName: "acetaminophentox2023.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/acetaminophen-paracetamol-toxicity-assessment-revised-2023"))
    result.append(CalculatorInfo(id: "AlcoholScreenhtm", title: "Alcohol Consumption Screening AUDIT Questionnaire", category: "Mental Health & Screening", fileName: "AlcoholScreen.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/alcohol-consumption-screening-audit-questionnaire"))
    result.append(CalculatorInfo(id: "AndrogenDefhtm", title: "Androgen Deficiency in Aging Males (ADAM) Screener", category: "Endocrinology", fileName: "AndrogenDef.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/androgen-deficiency-in-aging-males-adam-screener"))
    result.append(CalculatorInfo(id: "AnionGaphtm", title: "Anion Gap", category: "Electrolytes & Acid-Base", fileName: "AnionGap.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/anion-gap"))
    result.append(CalculatorInfo(id: "AnionGapDeltaGradienthtm", title: "Anion Gap Delta Delta Gradient Multicalc", category: "Electrolytes & Acid-Base", fileName: "AnionGapDeltaGradient.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/anion-gap-delta-delta-gradient-multicalc"))
    result.append(CalculatorInfo(id: "AnionGapHypoAlbhtm", title: "Anion Gap in Hypoalbumin States", category: "Electrolytes & Acid-Base", fileName: "AnionGapHypoAlb.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/anion-gap-in-hypoalbumin-states"))
    result.append(CalculatorInfo(id: "AnthraxScreeninghtm", title: "Anthrax Screening for Exposed Patients", category: "Infectious Disease", fileName: "AnthraxScreening.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/anthrax-screening-for-exposed-patients"))
    result.append(CalculatorInfo(id: "ApacheScorehtm", title: "APACHE II Scoring System and Mortality Estimates (Acute Physiology and Chronic Health Disease Classification System II)", category: "Critical Care Scores", fileName: "ApacheScore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/apache-ii-scoring-system-and-mortality-estimates-acute-physiology-and-chronic-health-disease-classification-system-ii"))
    result.append(CalculatorInfo(id: "ApgarScorehtm", title: "Apgar Score", category: "Neonatology", fileName: "ApgarScore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/apgar-score"))
    result.append(CalculatorInfo(id: "ArterialBloodGashtm", title: "Arterial Blood Gas Interpretation TreeCalc", category: "Respiratory & Gas Exchange", fileName: "ArterialBloodGas.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/arterial-blood-gas-interpretation-treecalc"))
    result.append(CalculatorInfo(id: "AtrialFibCHADSVASchtm", title: "Atrial Fibrillation CHA(2)DS(2)-VASc Score for Stroke Risk", category: "Cardiovascular", fileName: "AtrialFibCHADSVASc.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/atrial-fibrillation-cha2ds2-vasc-score-for-stroke-risk"))
    result.append(CalculatorInfo(id: "autoImmunehepatitishtm", title: "Autoimmune Hepatitis Diagnostic Criteria", category: "Hepatic", fileName: "autoImmunehepatitis.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/autoimmune-hepatitis-diagnostic-criteria"))
    result.append(CalculatorInfo(id: "BarrettProgRiskhtm", title: "Barrett Esophagus Progression Risk TreeCalc®", category: "Gastroenterology", fileName: "BarrettProgRisk.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/barrett-esophagus-progression-risk-treecalc"))
    result.append(CalculatorInfo(id: "Basichtm", title: "Basic Unit Conversions", category: "Unit Conversions", fileName: "Basic.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/basic-unit-conversions"))
    result.append(CalculatorInfo(id: "BayesianAnalysis1htm", title: "Bayesian Statistics I MultiCalc", category: "EBM & Statistics", fileName: "BayesianAnalysis_1.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/bayesian-statistics-i-multicalc"))
    result.append(CalculatorInfo(id: "BayesianAnalysis2htm", title: "Bayesian Statistics II MultiCalc", category: "EBM & Statistics", fileName: "BayesianAnalysis_2.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/bayesian-statistics-ii-multicalc"))
    result.append(CalculatorInfo(id: "BISAPScorehtm", title: "Bedside index of severity in acute pancreatitis (BISAP) score", category: "Critical Care Scores", fileName: "BISAPScore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/bedside-index-of-severity-in-acute-pancreatitis-bisap-score"))
    result.append(CalculatorInfo(id: "BenefitIncreasehtm", title: "Benefit Increase / Number Needed to Treat Multicalc", category: "EBM & Statistics", fileName: "BenefitIncrease.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/benefit-increase-number-needed-to-treat-multicalc"))
    result.append(CalculatorInfo(id: "BloodPressurePercentBoyshtm", title: "Blood Pressure Percentiles for Boys (2 - 17 years)", category: "Pediatrics", fileName: "BloodPressurePercentBoys.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/blood-pressure-percentiles-for-boys-2-17-years"))
    result.append(CalculatorInfo(id: "BloodPressurePercentGirlshtm", title: "Blood Pressure Percentiles for Girls (2 - 17 years)", category: "Pediatrics", fileName: "BloodPressurePercentGirls.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/blood-pressure-percentiles-for-girls-2-17-years"))
    result.append(CalculatorInfo(id: "BloodPressurePercent2017htm", title: "Blood pressure percentiles, 0 to 17 years (2017 standard)", category: "Pediatrics", fileName: "BloodPressurePercent2017.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/blood-pressure-percentiles-0-to-17-years-2017-standard"))
    result.append(CalculatorInfo(id: "BODEhtm", title: "BODE Index for COPD Survival Prediction", category: "Pulmonary", fileName: "BODE.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/bode-index-for-copd-survival-prediction"))
    result.append(CalculatorInfo(id: "BodyMassIndexBoyshtm", title: "Body Mass Index (BMI) percentiles for boys (2 to 20 years)", category: "Growth & Anthropometrics", fileName: "BodyMassIndexBoys.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/body-mass-index-bmi-percentiles-for-boys-2-to-20-years"))
    result.append(CalculatorInfo(id: "BodyMassIndexGirlshtm", title: "Body Mass Index (BMI) percentiles for girls (2 to 20 years)", category: "Growth & Anthropometrics", fileName: "BodyMassIndexGirls.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/body-mass-index-bmi-percentiles-for-girls-2-to-20-years"))
    result.append(CalculatorInfo(id: "BodyMassIndexhtm", title: "Body Mass Index (Quetelet's index)", category: "Growth & Anthropometrics", fileName: "BodyMassIndex.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/body-mass-index-quetelets-index"))
    result.append(CalculatorInfo(id: "BodySurfaceAreahtm", title: "Body Surface Area (Du Bois Method)", category: "Growth & Anthropometrics", fileName: "BodySurfaceArea.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/body-surface-area-du-bois-method"))
    result.append(CalculatorInfo(id: "gail2018htm", title: "Breast cancer risk assessment by Gail Model (2018)", category: "Oncology & Risk", fileName: "gail2018.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/breast-cancer-risk-assessment-by-gail-model-2018"))
    result.append(CalculatorInfo(id: "BurnInjuryFluidParklandhtm", title: "Burn Injury Fluid Resuscitation, Adult (Parkland crystalloid estimate)", category: "Critical Care Scores", fileName: "BurnInjuryFluidParkland.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/burn-injury-fluid-resuscitation-adult-parkland-crystalloid-estimate"))
    result.append(CalculatorInfo(id: "CalciumAlbuminhtm", title: "Calcium Correction in Hypoalbuminemia", category: "Electrolytes & Acid-Base", fileName: "CalciumAlbumin.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/calcium-correction-in-hypoalbuminemia"))
    result.append(CalculatorInfo(id: "CalciumAlbuminSIhtm", title: "Calcium Correction in Hypoalbuminemia (SI units)", category: "Electrolytes & Acid-Base", fileName: "CalciumAlbumin_SI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/calcium-correction-in-hypoalbuminemia-si-units"))
    result.append(CalculatorInfo(id: "CardiacOutputhtm", title: "Cardiac Output", category: "Cardiovascular", fileName: "CardiacOutput.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cardiac-output"))
    result.append(CalculatorInfo(id: "CardiacOutputMChtm", title: "Cardiac Output MultiCalc", category: "Cardiovascular", fileName: "CardiacOutput_MC.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cardiac-output-multicalc"))
    result.append(CalculatorInfo(id: "CVRiskRevised2018htm", title: "Cardiovascular Risk Assessment (10-year, Revised Pooled Cohort Equations 2018)", category: "Cardiovascular", fileName: "CVRiskRevised2018.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cardiovascular-risk-assessment-10-year-revised-pooled-cohort-equations-2018"))
    result.append(CalculatorInfo(id: "ahaprevhtm", title: "Cardiovascular risk assessment in adults (10 and 30-year, AHA PREVENT 2023)", category: "Other", fileName: "aha_prev.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cardiovascular-risk-assessment-in-adults-10-and-30-year-aha-prevent-2023"))
    result.append(CalculatorInfo(id: "CDCWeightForAgeBoyshtm", title: "CDC Weight for Age Percentiles for Boys (2-20 years)", category: "Pediatrics", fileName: "CDCWeightForAgeBoys.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cdc-weight-for-age-percentiles-for-boys-2-20-years"))
    result.append(CalculatorInfo(id: "CDCWeightForAgeGirlshtm", title: "CDC Weight for Age Percentiles for Girls (2-20 years)", category: "Pediatrics", fileName: "CDCWeightForAgeGirls.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cdc-weight-for-age-percentiles-for-girls-2-20-years"))
    result.append(CalculatorInfo(id: "CDCWeightForHeightBoyshtm", title: "CDC Weight for Height Percentiles for Boys (77-121 cm tall)", category: "Pediatrics", fileName: "CDCWeightForHeightBoys.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cdc-weight-for-height-percentiles-for-boys-77-121-cm-tall"))
    result.append(CalculatorInfo(id: "CDCWeightForHeightGirlshtm", title: "CDC Weight for Height Percentiles for Girls (77-121 cm tall)", category: "Pediatrics", fileName: "CDCWeightForHeightGirls.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cdc-weight-for-height-percentiles-for-girls-77-121-cm-tall"))
    result.append(CalculatorInfo(id: "CentorMcIssacSoreThroatCriteriahtm", title: "Centor Strep Pharyngitis Criteria With McIsaac Modification", category: "Infectious Disease", fileName: "CentorMcIssacSoreThroatCriteria.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/centor-strep-pharyngitis-criteria-with-mcisaac-modification"))
    result.append(CalculatorInfo(id: "ChildTurPuScorehtm", title: "Child Pugh Classification for Severity of Liver Disease", category: "Hepatic", fileName: "ChildTurPuScore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/child-pugh-classification-for-severity-of-liver-disease"))
    result.append(CalculatorInfo(id: "cirrhosisprobabilitymchtm", title: "Cirrhosis Probability in Hepatitis C", category: "Hepatic", fileName: "cirrhosisprobability_mc.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/cirrhosis-probability-in-hepatitis-c"))
    result.append(CalculatorInfo(id: "CIWAhtm", title: "CIWA-Ar Clinical Institute Withdrawal Assessment for Alcohol Scale", category: "Substance Use", fileName: "CIWA.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/ciwa-ar-clinical-institute-withdrawal-assessment-for-alcohol-scale"))
    result.append(CalculatorInfo(id: "clockdrawinghtm", title: "Clock Drawing Task (Cognitive Impairment Screening)", category: "Neurology", fileName: "clockdrawing.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/clock-drawing-task-cognitive-impairment-screening"))
    result.append(CalculatorInfo(id: "CommunityAcqPneumoniahtm", title: "Community-Acquired Pneumonia Severity Index (PSI) for Adults", category: "Infectious Disease", fileName: "CommunityAcqPneumonia.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/community-acquired-pneumonia-severity-index-psi-for-adults"))
    result.append(CalculatorInfo(id: "CreatinineClSIhtm", title: "Creatinine Clearance (measured SI units)", category: "Renal", fileName: "CreatinineCl_SI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/creatinine-clearance-measured-si-units"))
    result.append(CalculatorInfo(id: "CreatinineClhtm", title: "Creatinine Clearance (measured)", category: "Renal", fileName: "CreatinineCl.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/creatinine-clearance-measured"))
    result.append(CalculatorInfo(id: "CreatinineClCGSIhtm", title: "Creatinine Clearance Estimate by Cockcroft-Gault Equation (SI units)", category: "Renal", fileName: "CreatinineCl_CG_SI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/creatinine-clearance-estimate-by-cockcroft-gault-equation-si-units"))
    result.append(CalculatorInfo(id: "CreatinineClSanakahtm", title: "Creatinine Clearance Estimate by Sanaka Formula (for older subjects with low muscle mass)", category: "Renal", fileName: "CreatinineCl_Sanaka.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/creatinine-clearance-estimate-by-sanaka-formula-for-older-subjects-with-low-muscle-mass"))
    result.append(CalculatorInfo(id: "CDAIhtm", title: "Crohn Disease Activity Index (CDAI)", category: "Gastroenterology", fileName: "CDAI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/crohn-disease-activity-index-cdai"))
    result.append(CalculatorInfo(id: "CSFProteinhtm", title: "CSF Protein Concentration Correction in Blood Contaminated CSF", category: "Neurology", fileName: "CSFProtein.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/csf-protein-concentration-correction-in-blood-contaminated-csf"))
    result.append(CalculatorInfo(id: "CSFWBChtm", title: "CSF WBC Correction in Blood Contaminated CSF", category: "Infectious Disease", fileName: "CSF_WBC.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/csf-wbc-correction-in-blood-contaminated-csf"))
    result.append(CalculatorInfo(id: "DMSelfAssesshtm", title: "Diabetes Risk Self-Assessment", category: "Endocrinology", fileName: "DMSelfAssess.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/diabetes-risk-self-assessment"))
    result.append(CalculatorInfo(id: "DLCOAnemiahtm", title: "Diffusing capacity for carbon monoxide (DLCO) corrected for anemia", category: "Pulmonary", fileName: "DLCO_Anemia.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/diffusing-capacity-for-carbon-monoxide-dlco-corrected-for-anemia"))
    result.append(CalculatorInfo(id: "DVTScoreWellshtm", title: "DVT Probability: Wells Score System", category: "Cardiovascular", fileName: "DVTScoreWells.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/dvt-probability-wells-score-system"))
    result.append(CalculatorInfo(id: "ecoghtm", title: "ECOG Performance Status", category: "Oncology & Risk", fileName: "ecog.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/ecog-performance-status"))
    result.append(CalculatorInfo(id: "PediatricETTubeSizehtm", title: "Endotracheal tube size for children (Age 1 to 8 years)", category: "Pediatrics", fileName: "PediatricETTubeSize.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/endotracheal-tube-size-for-children-age-1-to-8-years"))
    result.append(CalculatorInfo(id: "Energyhtm", title: "Energy Unit Conversions", category: "Unit Conversions", fileName: "Energy.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/energy-unit-conversions"))
    result.append(CalculatorInfo(id: "epworthsleepscalehtm", title: "Epworth Sleepiness Scale (ESS)", category: "Sleep Medicine", fileName: "epworthsleepscale.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/epworth-sleepiness-scale-ess"))
    result.append(CalculatorInfo(id: "EuroSCOREAddhtm", title: "EuroSCORE for Cardiac Surgery Risk Assessment (additive version)", category: "Cardiovascular", fileName: "EuroSCOREAdd.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/euroscore-for-cardiac-surgery-risk-assessment-additive-version"))
    result.append(CalculatorInfo(id: "FalseNegativeRateSSPhtm", title: "False Negative Rate from Sensitivity and Prevalence", category: "EBM & Statistics", fileName: "FalseNegativeRateSSP.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/false-negative-rate-from-sensitivity-and-prevalence"))
    result.append(CalculatorInfo(id: "FalsePositiveRateSSPhtm", title: "False Positive Rate from Specificity and Prevalence", category: "EBM & Statistics", fileName: "FalsePositiveRateSSP.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/false-positive-rate-from-specificity-and-prevalence"))
    result.append(CalculatorInfo(id: "fib4multidxhtm", title: "FIB-4 Index, an Indirect Marker for Liver Fibrosis in Adults (2026 update)", category: "Hepatic", fileName: "fib4_multidx.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/fib-4-index-an-indirect-marker-for-liver-fibrosis-in-adults-2026-update"))
    result.append(CalculatorInfo(id: "Flowhtm", title: "Flow Unit Conversions", category: "Pulmonary", fileName: "Flow.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/flow-unit-conversions"))
    result.append(CalculatorInfo(id: "FractExcAmylasehtm", title: "Fractional Excretion of Amylase (Amylase to creatinine clearance ratio)", category: "Unit Conversions", fileName: "FractExcAmylase.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/fractional-excretion-of-amylase-amylase-to-creatinine-clearance-ratio"))
    result.append(CalculatorInfo(id: "FractExcSodiumhtm", title: "Fractional Excretion of Sodium", category: "Electrolytes & Acid-Base", fileName: "FractExcSodium.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/fractional-excretion-of-sodium"))
    result.append(CalculatorInfo(id: "FractExcSodiumSIhtm", title: "Fractional Excretion of Sodium (SI units)", category: "Electrolytes & Acid-Base", fileName: "FractExcSodium_SI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/fractional-excretion-of-sodium-si-units"))
    result.append(CalculatorInfo(id: "FriedewaldSIhtm", title: "Friedewald Equation for Low Density Lipoprotein (LDL-C SI units)", category: "Cardiovascular", fileName: "Friedewald_SI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/friedewald-equation-for-low-density-lipoprotein-ldl-c-si-units"))
    result.append(CalculatorInfo(id: "Friedewaldhtm", title: "Friedewald Equation for Low Density Lipoprotein (LDL-C)", category: "Cardiovascular", fileName: "Friedewald.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/friedewald-equation-for-low-density-lipoprotein-ldl-c"))
    result.append(CalculatorInfo(id: "GIPSShtm", title: "Genetically Inspired International Prognostic Scoring System (GIPSS) for Primary Myelofibrosis in Adults", category: "Hepatic", fileName: "GIPSS.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/genetically-inspired-international-prognostic-scoring-system-gipss-for-primary-myelofibrosis-in-adults"))
    result.append(CalculatorInfo(id: "GeriatricDepressionhtm", title: "Geriatric Depression Scale", category: "Other", fileName: "GeriatricDepression.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/geriatric-depression-scale"))
    result.append(CalculatorInfo(id: "GlasgowComaScalehtm", title: "Glasgow Coma Scale", category: "Neurology", fileName: "GlasgowComaScale.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/glasgow-coma-scale"))
    result.append(CalculatorInfo(id: "GFRCKDEPIhtm", title: "Glomerular Filtration Rate Estimate by CKD-EPI Equation", category: "Renal", fileName: "GFR_CKD_EPI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/glomerular-filtration-rate-estimate-by-ckd-epi-equation"))
    result.append(CalculatorInfo(id: "GFRMDRDFullhtm", title: "Glomerular Filtration Rate Estimate by the MDRD Equation", category: "Renal", fileName: "GFR_MDRD_Full.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/glomerular-filtration-rate-estimate-by-the-mdrd-equation"))
    result.append(CalculatorInfo(id: "gfrckdepiwithcystatin2021htm", title: "Glomerular Filtration Rate Estimation (eGFR) by CKD-EPI Equation with Creatinine and Cystatin C, without Race (2021)", category: "Renal", fileName: "gfr_ckd_epi_with_cystatin_2021.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/glomerular-filtration-rate-estimation-egfr-by-ckd-epi-equation-with-creatinine-and-cystatin-c-without-race-2021"))
    result.append(CalculatorInfo(id: "GFRCKDEPI2021htm", title: "Glomerular Filtration Rate Estimation (eGFR) by CKD-EPI Equation with Creatinine, without Race (2021)", category: "Renal", fileName: "GFR_CKD_EPI_2021.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/glomerular-filtration-rate-estimation-egfr-by-ckd-epi-equation-with-creatinine-without-race-2021"))
    result.append(CalculatorInfo(id: "GFRCKDEPIbyCystatin2012htm", title: "Glomerular Filtration Rate Estimation (eGFR) by CKD-EPI Equation with Cystatin C, without Race (2012)", category: "Renal", fileName: "GFR_CKD_EPI_by_Cystatin_2012.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/glomerular-filtration-rate-estimation-egfr-by-ckd-epi-equation-with-cystatin-c-without-race-2012"))
    result.append(CalculatorInfo(id: "GlycemicAssessmenthtm", title: "Glycemic Assessment", category: "Endocrinology", fileName: "GlycemicAssessment.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/glycemic-assessment"))
    result.append(CalculatorInfo(id: "GRACE2Scorehtm", title: "GRACE 2.0 Score for Acute Coronary Syndrome Prognosis (non-linear model 2014)", category: "Cardiovascular", fileName: "GRACE2Score.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/grace-20-score-for-acute-coronary-syndrome-prognosis-non-linear-model-2014"))
    result.append(CalculatorInfo(id: "HASBLEDhtm", title: "HAS-BLED Bleeding Risk Score", category: "Cardiovascular", fileName: "HASBLED.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/has-bled-bleeding-risk-score"))
    result.append(CalculatorInfo(id: "HeightPotentialhtm", title: "Height Potential: A Child's Target Height Based on Midparental Height", category: "Pediatrics", fileName: "HeightPotential.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/height-potential-a-childs-target-height-based-on-midparental-height"))
    result.append(CalculatorInfo(id: "HendersonHasselbachhtm", title: "Henderson-Hasselbalch Equation", category: "Electrolytes & Acid-Base", fileName: "HendersonHasselbach.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/henderson-hasselbalch-equation"))
    result.append(CalculatorInfo(id: "HepatitisCriteriahtm", title: "Hepatitis Discriminant Function for Corticosteroid Therapy in Alcoholic Hepatitis", category: "Hepatic", fileName: "HepatitisCriteria.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/hepatitis-discriminant-function-for-corticosteroid-therapy-in-alcoholic-hepatitis"))
    result.append(CalculatorInfo(id: "HyponatremiaCorrectionhtm", title: "Hyponatremia Correction Infusate Rate", category: "Electrolytes & Acid-Base", fileName: "HyponatremiaCorrection.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/hyponatremia-correction-infusate-rate"))
    result.append(CalculatorInfo(id: "IdealBodyWgthtm", title: "Ideal Body Weight", category: "Growth & Anthropometrics", fileName: "IdealBodyWgt.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/ideal-body-weight"))
    result.append(CalculatorInfo(id: "IntracranialBleedingRiskThrombolyticshtm", title: "Intracranial Bleeding Risk from Thrombolytic Therapy of MI", category: "Neurology", fileName: "IntracranialBleedingRiskThrombolytics.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/intracranial-bleeding-risk-from-thrombolytic-therapy-of-mi"))
    result.append(CalculatorInfo(id: "KtVFormulaeMultihtm", title: "Kt/V Dialysis Dose Formulae MultiCalc", category: "Renal", fileName: "Kt_V_Formulae_Multi.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/ktv-dialysis-dose-formulae-multicalc"))
    result.append(CalculatorInfo(id: "LeanBodyWgtFhtm", title: "Lean Body Weight (Female)", category: "Growth & Anthropometrics", fileName: "LeanBodyWgtF.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/lean-body-weight-female"))
    result.append(CalculatorInfo(id: "LeanBodyWgtMhtm", title: "Lean Body Weight (Male)", category: "Growth & Anthropometrics", fileName: "LeanBodyWgtM.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/lean-body-weight-male"))
    result.append(CalculatorInfo(id: "Lengthhtm", title: "Length Unit Conversions", category: "Unit Conversions", fileName: "Length.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/length-unit-conversions"))
    result.append(CalculatorInfo(id: "Likelihoodhtm", title: "Likelihood Ratio MultiCalc", category: "EBM & Statistics", fileName: "Likelihood.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/likelihood-ratio-multicalc"))
    result.append(CalculatorInfo(id: "LikelihoodRNDatahtm", title: "Likelihood Ratio of Negative from Raw Data", category: "EBM & Statistics", fileName: "LikelihoodRNData.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/likelihood-ratio-of-negative-from-raw-data"))
    result.append(CalculatorInfo(id: "LikelihoodRPDatahtm", title: "Likelihood Ratio of Positive from Raw Data", category: "EBM & Statistics", fileName: "LikelihoodRPData.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/likelihood-ratio-of-positive-from-raw-data"))
    result.append(CalculatorInfo(id: "LungVolumeshtm", title: "Lung Volume Multicalc", category: "Pulmonary", fileName: "LungVolumes.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/lung-volume-multicalc"))
    result.append(CalculatorInfo(id: "MICriteriaLBBBhtm", title: "M.I. Criteria for Likelihood in Chest Pain with LBBB", category: "Cardiovascular", fileName: "MICriteriaLBBB.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/mi-criteria-for-likelihood-in-chest-pain-with-lbbb"))
    result.append(CalculatorInfo(id: "maggichtm", title: "MAGGIC Score Predicting Heart Failure Survival", category: "Oncology & Risk", fileName: "maggic.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/maggic-score-predicting-heart-failure-survival"))
    result.append(CalculatorInfo(id: "MaintenanceFluidChildrenhtm", title: "Maintenance Fluid Calculation for Children", category: "Pediatrics", fileName: "MaintenanceFluidChildren.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/maintenance-fluid-calculation-for-children"))
    result.append(CalculatorInfo(id: "MartinLDLhtm", title: "Martin Equation for Low Density Lipoprotein (LDL-C)", category: "Cardiovascular", fileName: "MartinLDL.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/martin-equation-for-low-density-lipoprotein-ldl-c"))
    result.append(CalculatorInfo(id: "MeanVascPreshtm", title: "Mean Vascular Pressure (systemic or pulmonary)", category: "Cardiovascular", fileName: "MeanVascPres.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/mean-vascular-pressure-systemic-or-pulmonary"))
    result.append(CalculatorInfo(id: "MedsScorehtm", title: "MEDS Score: Mortality in ER Sepsis", category: "Critical Care Scores", fileName: "MedsScore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/meds-score-mortality-in-er-sepsis"))
    result.append(CalculatorInfo(id: "meld3htm", title: "MELD 3.0 Score Including Serum Albumin", category: "Hepatic", fileName: "meld3.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/meld-30-score-including-serum-albumin"))
    result.append(CalculatorInfo(id: "MELDhtm", title: "MELD Score for End-Stage Liver Disease (NOT appropriate for patients under the age of 12)", category: "Hepatic", fileName: "MELD.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/meld-score-for-end-stage-liver-disease-not-appropriate-for-patients-under-the-age-of-12"))
    result.append(CalculatorInfo(id: "MifflinStJeorhtm", title: "Mifflin-St. Jeor Resting Energy Expenditure (REE)", category: "Growth & Anthropometrics", fileName: "MifflinStJeor.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/mifflin-st-jeor-resting-energy-expenditure-ree"))
    result.append(CalculatorInfo(id: "Milanhtm", title: "Milan Criteria in Liver Transplantation for Hepatocellular Carcinoma", category: "Hepatic", fileName: "Milan.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/milan-criteria-in-liver-transplantation-for-hepatocellular-carcinoma"))
    result.append(CalculatorInfo(id: "MODShtm", title: "Multiple Organ Dysfunction Score (MODS)", category: "Critical Care Scores", fileName: "MODS.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/multiple-organ-dysfunction-score-mods"))
    result.append(CalculatorInfo(id: "NegPredValueDatahtm", title: "Negative Predictive Value from Raw Data", category: "EBM & Statistics", fileName: "NegPredValueData.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/negative-predictive-value-from-raw-data"))
    result.append(CalculatorInfo(id: "NegPredValhtm", title: "Negative Predictive Value of a Test", category: "EBM & Statistics", fileName: "NegPredVal.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/negative-predictive-value-of-a-test"))
    result.append(CalculatorInfo(id: "neonatalsepsishtm", title: "Neonatal Early-Onset Sepsis Risk Prediction", category: "Neonatology", fileName: "neonatalsepsis.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/neonatal-early-onset-sepsis-risk-prediction"))
    result.append(CalculatorInfo(id: "newbornhyperbili2022htm", title: "Newborn hyperbilirubinemia assessment for infants born at 35 weeks or more gestation (2022 update)", category: "Neonatology", fileName: "newbornhyperbili2022.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/newborn-hyperbilirubinemia-assessment-for-infants-born-at-35-weeks-or-more-gestation-2022-update"))
    result.append(CalculatorInfo(id: "NIHStrokeScorehtm", title: "NIH Stroke Score", category: "Neurology", fileName: "NIHStrokeScore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/nih-stroke-score"))
    result.append(CalculatorInfo(id: "oddsprobhtm", title: "Odds from Probability", category: "EBM & Statistics", fileName: "oddsprob.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/odds-from-probability"))
    result.append(CalculatorInfo(id: "Osmolalityhtm", title: "Osmolality Estimator (serum)", category: "Electrolytes & Acid-Base", fileName: "Osmolality.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/osmolality-estimator-serum"))
    result.append(CalculatorInfo(id: "Oxygenhtm", title: "Oxygen Delivery Units Conversions", category: "Respiratory & Gas Exchange", fileName: "Oxygen.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/oxygen-delivery-units-conversions"))
    result.append(CalculatorInfo(id: "PaO2FIO2Ratiohtm", title: "PaO2 / FIO2 Ratio (for MODS Calculation)", category: "Respiratory & Gas Exchange", fileName: "PaO2_FIO2Ratio.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/pao2-fio2-ratio-for-mods-calculation"))
    result.append(CalculatorInfo(id: "PeakExpFlowhtm", title: "Peak Expiratory Flow Prediction", category: "Pulmonary", fileName: "PeakExpFlow.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/peak-expiratory-flow-prediction"))
    result.append(CalculatorInfo(id: "peldcrhtm", title: "PELD-Cr Score for End-stage Liver Disease in patients less than 12 years old (2023 update)", category: "Hepatic", fileName: "peldcr.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/peld-cr-score-for-end-stage-liver-disease-in-patients-less-than-12-years-old-2023-update"))
    result.append(CalculatorInfo(id: "perchtm", title: "PERC Rule for the Assessment of Possible Pulmonary Embolism", category: "EBM & Statistics", fileName: "perc.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/perc-rule-for-the-assessment-of-possible-pulmonary-embolism"))
    result.append(CalculatorInfo(id: "pftgli22htm", title: "PFT predicted values by 2022 race-neutral GLI equations, ages 3 to 95", category: "Pulmonary", fileName: "pft_gli_22.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/pft-predicted-values-by-2022-race-neutral-gli-equations-ages-3-to-95"))
    result.append(CalculatorInfo(id: "plasmichtm", title: "PLASMIC Score for Estimating the Likelihood of Severe ADAMTS13 Deficiency in Adults with Suspected TTP", category: "Hematology", fileName: "plasmic.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/plasmic-score-for-estimating-the-likelihood-of-severe-adamts13-deficiency-in-adults-with-suspected-ttp"))
    result.append(CalculatorInfo(id: "PneumoThoraxhtm", title: "Pneumothorax Degree of Collapse", category: "Respiratory & Gas Exchange", fileName: "PneumoThorax.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/pneumothorax-degree-of-collapse"))
    result.append(CalculatorInfo(id: "PosPredValueDatahtm", title: "Positive Predictive Value from Raw Data", category: "EBM & Statistics", fileName: "PosPredValueData.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/positive-predictive-value-from-raw-data"))
    result.append(CalculatorInfo(id: "PosPredValuehtm", title: "Positive Predictive Value of a Test", category: "EBM & Statistics", fileName: "PosPredValue.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/positive-predictive-value-of-a-test"))
    result.append(CalculatorInfo(id: "GestationDatehtm", title: "Pregnancy Gestation by LMP and Ultrasound Biometry", category: "Other", fileName: "GestationDate.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/pregnancy-gestation-by-lmp-and-ultrasound-biometry"))
    result.append(CalculatorInfo(id: "HIThtm", title: "Pretest probability of heparin-induced thrombocytopenia (4-T's score)", category: "Hematology", fileName: "HIT.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/pretest-probability-of-heparin-induced-thrombocytopenia-4-ts-score"))
    result.append(CalculatorInfo(id: "ProbOddshtm", title: "Probability from Odds", category: "EBM & Statistics", fileName: "ProbOdds.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/probability-from-odds"))
    result.append(CalculatorInfo(id: "ProstatismSymptomScorehtm", title: "Prostatism Symptom Score", category: "Urology", fileName: "ProstatismSymptomScore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/prostatism-symptom-score"))
    result.append(CalculatorInfo(id: "PulmonaryEmbRiskhtm", title: "Pulmonary Embolism Wells Score", category: "Cardiovascular", fileName: "PulmonaryEmbRisk.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/pulmonary-embolism-wells-score"))
    result.append(CalculatorInfo(id: "qtintervalcorrectionhtm", title: "QT Interval Correction (EKG)", category: "Cardiovascular", fileName: "qtintervalcorrection.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/qt-interval-correction-ekg"))
    result.append(CalculatorInfo(id: "ReticProdIndexhtm", title: "Reticulocyte Production Index", category: "Hematology", fileName: "ReticProdIndex.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/reticulocyte-production-index"))
    result.append(CalculatorInfo(id: "revisedgenevascorehtm", title: "Revised Geneva Score for Estimation of the Clinical Probability of Pulmonary Embolism in Adults", category: "Cardiovascular", fileName: "revisedgenevascore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/revised-geneva-score-for-estimation-of-the-clinical-probability-of-pulmonary-embolism-in-adults"))
    result.append(CalculatorInfo(id: "RheumatoidArthritisCDAIhtm", title: "Rheumatoid Arthritis Clinical Disease Activity Index CDAI", category: "Rheumatology", fileName: "RheumatoidArthritisCDAI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/rheumatoid-arthritis-clinical-disease-activity-index-cdai"))
    result.append(CalculatorInfo(id: "RheumatoidArthritisDAS28htm", title: "Rheumatoid Arthritis Disease Activity Score DAS-28", category: "Rheumatology", fileName: "RheumatoidArthritisDAS28.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/rheumatoid-arthritis-disease-activity-score-das-28"))
    result.append(CalculatorInfo(id: "RomhiltEsteshtm", title: "Romhilt-Estes Criteria for Left Ventricular Hypertrophy", category: "Cardiovascular", fileName: "RomhiltEstes.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/romhilt-estes-criteria-for-left-ventricular-hypertrophy"))
    result.append(CalculatorInfo(id: "Sensitivityhtm", title: "Sensitivity of a Test", category: "EBM & Statistics", fileName: "Sensitivity.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/sensitivity-of-a-test"))
    result.append(CalculatorInfo(id: "QSOFAhtm", title: "Sequential Organ Failure Assessment (Quick): qSOFA Score", category: "Critical Care Scores", fileName: "QSOFA.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/sequential-organ-failure-assessment-quick-qsofa-score"))
    result.append(CalculatorInfo(id: "SOFAhtm", title: "Sequential Organ Failure Assessment (SOFA)", category: "Critical Care Scores", fileName: "SOFA.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/sequential-organ-failure-assessment-sofa"))
    result.append(CalculatorInfo(id: "AscitesAlbGradienthtm", title: "Serum-Ascites Albumin Gradient", category: "Other", fileName: "AscitesAlbGradient.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/serum-ascites-albumin-gradient"))
    result.append(CalculatorInfo(id: "SmallPoxhtm", title: "Smallpox Risk Assessment (CDC version 1.0 2002) TreeCalc", category: "Infectious Disease", fileName: "SmallPox.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/smallpox-risk-assessment-cdc-version-10-2002-treecalc"))
    result.append(CalculatorInfo(id: "SodiumProteinhtm", title: "Sodium Change in Hyperproteinemia", category: "Electrolytes & Acid-Base", fileName: "SodiumProtein.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/sodium-change-in-hyperproteinemia"))
    result.append(CalculatorInfo(id: "SodiumLipidshtm", title: "Sodium Change in Hypertriglyceridemia", category: "Electrolytes & Acid-Base", fileName: "SodiumLipids.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/sodium-change-in-hypertriglyceridemia"))
    result.append(CalculatorInfo(id: "SodiumHyperglycemiaKatzhtm", title: "Sodium Correction in Hyperglycemia (Katz 1973)", category: "Electrolytes & Acid-Base", fileName: "SodiumHyperglycemiaKatz.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/sodium-correction-in-hyperglycemia-katz-1973"))
    result.append(CalculatorInfo(id: "SodiumDeficithtm", title: "Sodium Deficit in Hyponatremia", category: "Electrolytes & Acid-Base", fileName: "SodiumDeficit.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/sodium-deficit-in-hyponatremia"))
    result.append(CalculatorInfo(id: "SolitaryPulmNodCummingshtm", title: "Solitary pulmonary nodule malignancy risk (Cummings prediction model: Bayesian approach)", category: "Pulmonary", fileName: "SolitaryPulmNod_Cummings.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/solitary-pulmonary-nodule-malignancy-risk-cummings-prediction-model-bayesian-approach"))
    result.append(CalculatorInfo(id: "Specificityhtm", title: "Specificity of a Test", category: "EBM & Statistics", fileName: "Specificity.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/specificity-of-a-test"))
    result.append(CalculatorInfo(id: "Temperaturehtm", title: "Temperature Unit Conversions", category: "Unit Conversions", fileName: "Temperature.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/temperature-unit-conversions"))
    result.append(CalculatorInfo(id: "TIMISTEMIhtm", title: "Thrombolysis in Myocardial Infarction (TIMI) Score for ST Elevation Acute Myocardial Infarction", category: "Cardiovascular", fileName: "TIMI_STEMI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/thrombolysis-in-myocardial-infarction-timi-score-for-st-elevation-acute-myocardial-infarction"))
    result.append(CalculatorInfo(id: "TIMIUANSTEMIhtm", title: "Thrombolysis in Myocardial Infarction (TIMI) Score for Unstable Angina Non ST Elevation Myocardial Infarction", category: "Cardiovascular", fileName: "TIMI_UA_NSTEMI.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/thrombolysis-in-myocardial-infarction-timi-score-for-unstable-angina-non-st-elevation-myocardial-infarction"))
    result.append(CalculatorInfo(id: "TipsRiskhtm", title: "TIPS Risk predictor / Survival predictor (Transjugular Intrahepatic Portosystemic Shunt)", category: "Hepatic", fileName: "TipsRisk.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/tips-risk-predictor-survival-predictor-transjugular-intrahepatic-portosystemic-shunt"))
    result.append(CalculatorInfo(id: "TBW58htm", title: "Total Body Water Estimation Based on Weight Alone", category: "Electrolytes & Acid-Base", fileName: "TBW_58.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/total-body-water-estimation-based-on-weight-alone"))
    result.append(CalculatorInfo(id: "TBWMWatsonhtm", title: "Total Body Water in Men (Watson formula)", category: "Electrolytes & Acid-Base", fileName: "TBW_M_Watson.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/total-body-water-in-men-watson-formula"))
    result.append(CalculatorInfo(id: "TBWWWatsonhtm", title: "Total Body Water in Women (Watson formula)", category: "Electrolytes & Acid-Base", fileName: "TBW_W_Watson.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/total-body-water-in-women-watson-formula"))
    result.append(CalculatorInfo(id: "Transferrinhtm", title: "Transferrin Saturation", category: "Unit Conversions", fileName: "Transferrin.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/transferrin-saturation"))
    result.append(CalculatorInfo(id: "UreaReducPercenthtm", title: "Urea Reduction Percentage in Hemodialysis (PRU)", category: "Renal", fileName: "UreaReducPercent.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/urea-reduction-percentage-in-hemodialysis-pru"))
    result.append(CalculatorInfo(id: "UrinaryProteinExcretionhtm", title: "Urinary Protein Excretion Estimation", category: "Renal", fileName: "UrinaryProteinExcretion.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/urinary-protein-excretion-estimation"))
    result.append(CalculatorInfo(id: "UrineAnionGaphtm", title: "Urine anion gap", category: "Electrolytes & Acid-Base", fileName: "UrineAnionGap.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/urine-anion-gap"))
    result.append(CalculatorInfo(id: "VeryLowDensityLipoproteinhtm", title: "Very Low Density Lipoprotein (VLDL)", category: "Cardiovascular", fileName: "VeryLowDensityLipoprotein.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/very-low-density-lipoprotein-vldl"))
    result.append(CalculatorInfo(id: "VolumeDistUreahtm", title: "Volume of Distribution of Urea", category: "Renal", fileName: "VolumeDistUrea.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/volume-of-distribution-of-urea"))
    result.append(CalculatorInfo(id: "Volumehtm", title: "Volume Unit Conversions", category: "Unit Conversions", fileName: "Volume.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/volume-unit-conversions"))
    result.append(CalculatorInfo(id: "WaterDeficithtm", title: "Water Deficit in Hypernatremia", category: "Electrolytes & Acid-Base", fileName: "WaterDeficit.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/water-deficit-in-hypernatremia"))
    result.append(CalculatorInfo(id: "Weighthtm", title: "Weight Unit Conversions", category: "Unit Conversions", fileName: "Weight.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/weight-unit-conversions"))
    result.append(CalculatorInfo(id: "westleycroupscorehtm", title: "Westley croup severity score (appropriate for use in children ≤ 6 years of age)", category: "Neonatology", fileName: "westleycroupscore.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/westley-croup-severity-score-appropriate-for-use-in-children-6-years-of-age"))
    result.append(CalculatorInfo(id: "WHOInfantHeadCircForAgehtm", title: "WHO Infant Head Circumference for Age Percentiles (< 24 months)", category: "Pediatrics", fileName: "WHOInfantHeadCircForAge.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/who-infant-head-circumference-for-age-percentiles-24-months"))
    result.append(CalculatorInfo(id: "WHOInfantLengthForAgehtm", title: "WHO Infant Length for Age Percentiles (< 24 months)", category: "Pediatrics", fileName: "WHOInfantLengthForAge.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/who-infant-length-for-age-percentiles-24-months"))
    result.append(CalculatorInfo(id: "WHOInfantWeightForAgehtm", title: "WHO Infant Weight for Age Percentiles (< 24 months)", category: "Pediatrics", fileName: "WHOInfantWeightForAge.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/who-infant-weight-for-age-percentiles-24-months"))
    result.append(CalculatorInfo(id: "WHOInfantWeightForLengthhtm", title: "WHO Infant Weight for Length Percentiles (< 24 months)", category: "Pediatrics", fileName: "WHOInfantWeightForLength.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/who-infant-weight-for-length-percentiles-24-months"))
    result.append(CalculatorInfo(id: "WinterFormulahtm", title: "Winter's Formula for Expected PCO2", category: "Electrolytes & Acid-Base", fileName: "WinterFormula.htm", merckPage: "https://www.merckmanuals.com/professional/multimedia/clinical-calculator/winters-formula-for-expected-pco2"))

    return result
}

/// Deduplicated catalog of every calculator, with lookups used by the app, widgets, and watch.
enum MedCalcCatalog {
    static let all: [CalculatorInfo] = dedupe(makeCalculatorList())

    private static func dedupe(_ list: [CalculatorInfo]) -> [CalculatorInfo] {
        var seen = Set<String>()
        return list.filter { seen.insert($0.id).inserted }
    }

    static func calculator(withID id: String) -> CalculatorInfo? {
        all.first { $0.id == id }
    }

    static func calculators(in category: CalculatorCategory) -> [CalculatorInfo] {
        all.filter { $0.category == category.rawValue }
    }
}
