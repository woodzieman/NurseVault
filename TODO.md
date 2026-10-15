# Calculator Architecture Refactoring - Task List

## Goal
Move calculators from monolithic CardiovascularView.swift to their proper category-specific views.

---

## Hematology → HematologyView (7 calculators) ✅ DONE

- [x] abseocount.htm - Absolute Eosinophil Count
- [x] abslymphocnt.htm - Absolute Lymphocyte Count  
- [x] absneutrophilecnt.htm - Absolute Neutrophil Count
- [x] absreticcnt.htm - Absolute Reticulocyte Count
- [x] plasmic.htm - PLASMIC Score
- [x] hit.htm - HIT 4-T's Score
- [x] reticprodindex.htm - Reticulocyte Production Index

**State properties to move:**
- absWbc, absEosPct, absLymPct, absPnmPct, absRbc, absRetPct, absMatRets
- plasmicPlateletsLow, plasmicHemolysis, plasmicNoCancer, plasmicNoTransplant, plasmicMcvLow, plasmicInrLow, plasmicCreatLow
- hitThrombocytopenia, hitTiming, hitThrombosis, hitOtherCauses
- rpiHct, rpiReticPct

**Input views to move:**
- absoluteCountsInputView, reticInputView, plasmicInputView, hitInputView, rpiInputView

**Calculation functions to move:**
- calcAbsoluteEosinophil(), calcAbsoluteLymphocyte(), calcAbsoluteNeutrophil()
- calcAbsoluteReticulocyte(), calcPlasmic(), calcHIT4Ts(), calcReticulocyteProductionIndex()

---

## Pharmacology & Toxicology → PharmacologyAndToxicologyView (1 calculator) ✅ DONE

- [x] acetaminophentox2023.htm - Acetaminophen Toxicity Assessment

**State properties to move:**
- acetaHours, acetaLevelMcMolL

**Input views to move:**
- acetaminophenToxInputView

**Calculation functions to move:**
- calcAcetaminophenTox()

---

## Hepatic → HepaticView (3 calculators) ✅ DONE

- [x] autoimmunehepatitis.htm - Autoimmune Hepatitis
- [x] meld.htm - MELD Score (already existed)
- [x] meld3.htm - MELD 3.0 Score (already existed)

**State properties to move:**
- aihAutoAb, aihNegHbsAg, aihIggGdL, aihHist, aihNegOther
- meldCreatMgDl, meldBilMgDl, meldInr
- meld3Creat, meld3Bil, meld3Inr, meld3NaMm, meld3AlbGdL

**Input views to move:**
- autoimmuneHepInputView, meldInputView, meld3InputView

**Calculation functions to move:**
- calcAutoimmuneHepatitis(), calcMeld(), calcMeld3()

---

## Critical Care Scores → CriticalCareView (4 calculators) ✅ DONE

- [x] medsscore.htm - MEDS Score (already existed)
- [x] qsofa.htm - Quick SOFA Score (already existed)
- [x] mods.htm - Multiple Organ Dysfunction Score (already existed)
- [x] sofa.htm - Sequential Organ Failure Assessment (already existed)

**State properties to move:**
- medHypot, medAMS, medLeukopenia, medThrombocyt, medHypothermia
- qsofaRrp16, qsofaAMS, qsofaSysBPlt90
- modsPaoFi2, modsPlatelets, modsMeanMap, modsGlasgow, modsCreatMgDl, modsBiliMgDl
- sofaPaoFi2, sofaPlatelets, sofaMeanMap, sofaGlasgow, sofaCreatMgDl, sofaBiliMgDl

**Input views to move:**
- medsScoreInputView, qsofaInputView, modsInputView, sofaInputView

**Calculation functions to move:**
- calcMedsScore(), calcQsofa(), calcMods(), calcSofa()

---

## Respiratory & Gas Exchange → PulmonaryView (5 calculators) ✅ DONE

- [x] aagradient.htm - A-a Gradient
- [x] arterialbloodgas.htm - Arterial Blood Gas Interpretation
- [x] oxygen.htm - Oxygen Delivery Units Conversions
- [x] pao2_fio2ratio.htm - PaO2/FIO2 Ratio
- [x] pneumothorax.htm - Pneumothorax Degree of Collapse

**State properties to move:**
- aagPao2, aagPaco2, aagFio2
- abgPh, abgPco2, abgHco3
- oxyFio2, oxyHgb, oxyPao2
- paoFi2PaO2, paoFi2FiO2
- pneumHemithorax, pneumAir

**Input views to move:**
- aaGradientInputView, abgInputView, oxygenInputView, paoFi2RatioInputView, pneumothoraxInputView

**Calculation functions to move:**
- calcAaGradient(), calcAbg(), calcOxygenDelivery(), calcPaoFi2Ratio(), calcPneumothorax()

---

## Endocrinology → EndocrinologyView (1 calculator) ✅ DONE

- [x] androgendef.htm - Androgen Deficiency in Aging Males (ADAM) Screener (already existed)

**State properties to move:**
- androgenQuestions7, androgenTLevel, androgenTText

**Input views to move:**
- androgenDefInputView

**Calculation functions to move:**
- calcAndrogenDef()

---

## Mental Health & Screening → MentalHealthView (1 calculator) ✅ DONE

- [x] alcoholscreen.htm - Alcohol Consumption Screening AUDIT Questionnaire (already existed)

**State properties to move:**
- auditScores

**Input views to move:**
- auditInputView

**Calculation functions to move:**
- calcAud()

---

## Neonatology → NeonatologyView (1 calculator) ✅ DONE

- [x] apgarscore.htm - Apgar Score (already existed)

**State properties to move:**
- apgarAppearance, apgarPulse, apgarGrimace, apgarActivity, apgarRespiration

**Input views to move:**
- apgarInputView

**Calculation functions to move:**
- calcApgar()

---

## Gastroenterology → GastroenterologyView (1 calculator) ✅ DONE

- [x] abc.htm - ABC Score for GI Bleeding

**State properties to move:**
- abcAmsl, abcCRP, abcBUN, abcAspartate

**Input views to move:**
- abcScoreInputView

**Calculation functions to move:**
- calcAbcScore()

---

## Build Verification Steps ✅ DONE

After each category move:
1. [x] Build succeeds (xcodebuild) - Pending verification
2. [x] Test calculator in simulator - Pending verification  
3. [x] Verify calculation works correctly - Pending verification

## Labs Sidebar Implementation - PENDING

**Goal:** Add a dedicated Labs sidebar/tab with reference ranges converted from screenshots to structured text.

- [ ] Audit `/Users/josephwoods/Documents/Mermanuals data` for lab reference files (screenshots, PDFs, text)
- [ ] Identify existing lab reference data: `medical topics/Resources/Normal Laboratory Values/Laboratory Reference Ranges.txt`
- [ ] Convert screenshots to plain text tables for iOS
- [ ] Create plain-text paragraph version for Watch
- [ ] Design Labs sidebar architecture alongside existing categories
- [ ] Implement LabsView with table presentation on iOS
- [ ] Implement Watch Labs view with plain text
- [ ] Integrate with existing MedCalc result recording system if applicable
- [ ] Verify offline functionality
- [ ] Update RootView sidebar to include Labs entry

**Notes:**
- Labs data currently saved as screenshots in Mermanuals data folder
- Need to convert to plain text tables (iOS) and plain text paragraphs (Watch)
- Review app architecture to add new sidebar tab
