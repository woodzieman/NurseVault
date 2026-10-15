#!/usr/bin/env python3
"""Build a filtered on-watch Drug Reference containing only high-priority nursing drugs.

Instead of bundling all 2,383 drugs (~35 MB), this selects ~500-600 drugs across
the therapeutic categories nurses reference most often: cardiac/emergency,
antibiotics, pain management, sedation, anticoagulants, diabetes, respiratory,
GI/antiemetics, electrolytes, and common psychiatric agents.

The output files replace the full-drug watch reference in
Sources/Watch/Resources/WatchReference/drugs.{index,content}.

Usage:
    python3 scripts/build_watch_drugs.py          # build filtered drug reference
    python3 scripts/build_watch_drugs.py --list   # list selected drugs without building
"""
import brotli
import random
import sys
from pathlib import Path

ROOT = Path("/Users/josephwoods/Documents/Nursing app")
OUT_DIR = ROOT / "Sources" / "Watch" / "Resources" / "WatchReference"
DRUG_INFO = ROOT / "DrugInfo"

PREVIEW_MAX_CHARS = 80

HEADER_PREFIXES = (
    "===",
    "Section:",
    "Source:",
    "Retrieved:",
    "NURSING QUICK-REFERENCE SUMMARY",
    "Auto-generated",
)


# High-priority therapeutic categories for nursing practice.
# Each category has keywords matched against the drug's generic name and
# its Drug Class description line (case-insensitive).
CATEGORIES = {
    "Cardiac / Emergency": [
        # Antiarrhythmics
        "amiodarone", "adenosine", "lidocaine", "procainamide", "sotalol",
        "dofetilide", "flecainide", "propafenone", "ibutilide", "quinidine",
        # Vasopressors / Inotropes
        "epinephrine", "norepinephrine", "dopamine", "dobutamine", "milrinone",
        "vasopressin", "phenylephrine", "isoproterenol", "levophed",
        # AV nodal blockers / Rate control
        "atropine", "metoprolol", "esmolol", "diltiazem", "verapamil",
        "propranolol", "atenolol", "carvedilol", "bisoprolol", "nadolol",
        # Nitrates / Antianginal
        "nitroglycerin", "nitroprusside", "isosorbide", "ranolazine",
        # Diuretics (cardiac use)
        "furosemide", "bumetanide", "torsemide", "ethacrynic acid",
        # Digoxin / Heart failure
        "digoxin", "milrinone", "sacubitril", "valsartan", "entresto",
    ],
    "Antibiotics / Antimicrobials": [
        # Beta-lactams
        "penicillin", "amoxicillin", "ampicillin", "piperacillin", "ticarcillin",
        "cefazolin", "cephalexin", "cefaclor", "cefuroxime", "ceftriaxone",
        "cefotaxime", "ceftazidime", "cefepime", "cefpodoxime", "cefdinir",
        "cefixime", "ertapenem", "meropenem", "imipenem", "doripenem",
        # Aminoglycosides
        "gentamicin", "tobramycin", "amikacin", "netilmicin",
        # Fluoroquinolones
        "ciprofloxacin", "levofloxacin", "moxifloxacin", "gemifloxacin",
        # Macrolides / Lincosamides
        "azithromycin", "clarithromycin", "erythromycin", "clindamycin",
        # Tetracyclines
        "doxycycline", "tetracycline", "minocycline", "tigecycline",
        # Others
        "vancomycin", "linezolid", "daptomycin", "metronidazole",
        "trimethoprim-sulfamethoxazole", "sulfamethoxazole", "nitrofurantoin",
        "fosfomycin", "colistin", "polymyxin", "bacitracin", "neomycin",
        # Antifungals (common)
        "fluconazole", "voriconazole", "caspofungin", "micafungin",
        "amphotericin", "echinocandin", "nystatin", "ketoconazole",
        # Antivirals (common)
        "acyclovir", "valacyclovir", "ganciclovir", "oseltamivir",
        "remdesivir", "sofosbuvir", "tenofovir", "emtricitabine",
    ],
    "Pain Management / Opioids": [
        # Opioids
        "morphine", "fentanyl", "hydromorphone", "oxycodone", "hydrocodone",
        "codeine", "meperidine", "methadone", "buprenorphine", "naloxone",
        "naltrexone", "tramadol", "tapentadol", "levorphanol",
        # NSAIDs / Analgesics
        "acetaminophen", "ibuprofen", "ketorolac", "naproxen", "aspirin",
        "diclofenac", "indomethacin", "celecoxib", "meloxicam", "tenoxicam",
        # Adjuvant analgesics
        "gabapentin", "pregabalin", "ketamine", "dexmedetomidine",
    ],
    "Sedation / Anesthesia": [
        "midazolam", "propofol", "dexmedetomidine", "ketamine",
        "lorazepam", "diazepam", "zolpidem", "eszopiclone",
        "remifentanil", "sufentanil", "alfentanil",
    ],
    "Anticoagulants / Antiplatelets": [
        # Anticoagulants
        "heparin", "enoxaparin", "dalteparin", "fondaparinux", "warfarin",
        "apixaban", "rivaroxaban", "edoxaban", "dabigatran", "argatroban",
        "bivalirudin", "lepirudin",
        # Antiplatelets
        "aspirin", "clopidogrel", "prasugrel", "ticagrelor", "dipyridamole",
        "cilostazol", "tirofiban", "eptifibatide", "abciximab",
        # Reversal agents
        "protamine", "vitamin k", "phytonadione", "andexanet alfa",
        "idarucizumab", "tranexamic acid", "aminocaproic acid",
    ],
    "Diabetes / Endocrine": [
        # Insulins
        "insulin", "glargine", "lispro", "aspart", "glulisine", "detemir",
        "degludec", "regular insulin", "nph insulin",
        # Oral agents
        "metformin", "glipizide", "glyburide", "glimepiride", "pioglitazone",
        "rosiglitazone", "sitagliptin", "linagliptin", "saxagliptin",
        "empagliflozin", "dapagliflozin", "canagliflozin", "semaglutide",
        "liraglutide", "dulaglutide", "exenatide", "pramlintide",
        # Glucose management
        "dextrose", "glucagon", "octreotide",
    ],
    "Respiratory": [
        # Bronchodilators
        "albuterol", "levalbuterol", "ipratropium", "tiotropium",
        "formoterol", "salmeterol", "umeclidinium", "glycopyrrolate",
        # Corticosteroids (respiratory)
        "methylprednisolone", "prednisone", "prednisolone", "dexamethasone",
        "beclomethasone", "budesonide", "fluticasone", "triamcinolone",
        # Others
        "theophylline", "aminophylline", "roflumilast", "acetazolamide",
    ],
    "GI / Antiemetics": [
        # Antiemetics
        "ondansetron", "metoclopramide", "prochlorperazine", "promethazine",
        "granisetron", "palonosetron", "aprepitant", "dexamethasone",
        # Acid suppression
        "pantoprazole", "omeprazole", "lansoprazole", "esomeprazole",
        "rabeprazole", "famotidine", "ranitidine", "cimetidine",
        "sucralfate", "misoprostol",
        # Laxatives / Bowel
        "senna", "bisacodyl", "polyethylene glycol", "docusate",
        "magnesium hydroxide", "mineral oil", "lactulose",
        # Antidiarrheals
        "loperamide", "bismuth subsalicylate", "octreotide",
    ],
    "Electrolytes / IV Fluids": [
        "potassium chloride", "magnesium sulfate", "calcium gluconate",
        "calcium chloride", "sodium bicarbonate", "sodium chloride",
        "dextrose 5%", "lactated ringer", "normal saline", "half normal saline",
        "phosphate", "potassium phosphate", "magnesium oxide",
    ],
    "Psychiatric (Common)": [
        # Antipsychotics
        "haloperidol", "quetiapine", "risperidone", "olanzapine",
        "aripiprazole", "ziprasidone", "clozapine", "lurasidone",
        # Anxiolytics / Sedatives
        "lorazepam", "alprazolam", "clonazepam", "diazepam", "buspirone",
        # Antidepressants (common)
        "sertraline", "fluoxetine", "paroxetine", "citalopram",
        "escitalopram", "venlafaxine", "duloxetine", "bupropion",
        "mirtazapine", "trazodone",
    ],
    "Neurologic / Seizure": [
        # Anticonvulsants
        "phenytoin", "fosphenytoin", "levetiracetam", "valproic acid",
        "lacosamide", "topiramate", "gabapentin", "pregabalin",
        "carbamazepine", "oxcarbazepine", "lamotrigine", "brivaracetam",
        # Status epilepticus
        "lorazepam", "diazepam", "midazolam", "phenobarbital",
    ],
    "Allergy / Anaphylaxis": [
        "epinephrine", "diphenhydramine", "cetirizine", "loratadine",
        "fexofenadine", "ranitidine", "famotidine", "methylprednisolone",
        "hydrocortisone", "albuterol",
    ],
}


def clean_one_line(value: str) -> str:
    value = value.replace("|", "/").replace("\r", " ")
    return " ".join(value.split()).strip()


def strip_metadata_header(text: str) -> str:
    lines = text.split("\n")
    i = 0
    for line in lines:
        t = line.strip()
        if not t or t.startswith(HEADER_PREFIXES):
            i += 1
            continue
        break
    return "\n".join(lines[i:])


def make_preview(text: str, prefer_prefix: str = "") -> str:
    body = strip_metadata_header(text)
    for para in body.split("\n\n"):
        para = para.strip()
        if not para:
            continue
        one = clean_one_line(para)
        if prefer_prefix and one.startswith(prefer_prefix):
            one = one[len(prefer_prefix):].lstrip(": ").strip()
        if len(one.split()) < 4:
            continue
        if one.lower().startswith("(see also"):
            continue
        return one[:PREVIEW_MAX_CHARS]
    fallback = clean_one_line(body)
    return fallback[:PREVIEW_MAX_CHARS] if fallback else "(no preview)"


def drug_brands(folder: Path) -> str:
    names_file = folder / "names.txt"
    if not names_file.is_file():
        return ""
    brands = []
    in_brands = False
    for line in names_file.read_text(encoding="utf-8", errors="ignore").splitlines():
        t = line.strip()
        if t.lower().startswith("trade/brand"):
            in_brands = True
            continue
        if in_brands:
            if t.startswith("- "):
                brands.append(t[2:].strip())
                if len(brands) >= 2:
                    break
            elif t and not t.startswith("-"):
                break
    return ", ".join(brands)


def drug_matches_categories(generic_name: str, class_text: str) -> bool:
    """Check if a drug matches any high-priority category."""
    name_lower = generic_name.lower()
    class_lower = class_text.lower()
    
    for keywords in CATEGORIES.values():
        for keyword in keywords:
            # Match against generic name (substring, case-insensitive)
            if keyword in name_lower:
                return True
            # Match against drug class description
            if keyword in class_lower:
                return True
    return False


def get_drug_class_text(content_path: Path) -> str:
    """Extract the Drug Class line from a drug's content file."""
    try:
        text = content_path.read_text(encoding="utf-8", errors="ignore")
        for line in text.splitlines():
            if line.strip().lower().startswith("drug class:"):
                return line.strip()
    except Exception:
        pass
    return ""


def collect_drugs_filtered():
    """Yield (title, preview, extra, raw_bytes) for high-priority drugs only."""
    selected = []
    skipped = 0
    
    for folder in sorted(p for p in DRUG_INFO.iterdir() if p.is_dir()):
        content = folder / "drug-information.txt"
        if not content.is_file():
            continue
        
        generic = folder.name.split(" and ")[0].strip()
        class_text = get_drug_class_text(content)
        
        if drug_matches_categories(generic, class_text):
            raw = content.read_bytes()
            text = raw.decode("utf-8", errors="ignore")
            selected.append((
                clean_one_line(generic),
                make_preview(text, prefer_prefix="Drug Class:"),
                clean_one_line(drug_brands(folder)),
                raw,
            ))
        else:
            skipped += 1
    
    print(f"Selected {len(selected)} drugs from {len(selected) + skipped} total "
          f"(skipped {skipped})")
    
    # Report by category (approximate — a drug may match multiple categories)
    for cat_name, keywords in CATEGORIES.items():
        count = 0
        for title, _, _, _ in selected:
            if any(kw in title.lower() for kw in keywords):
                count += 1
        if count > 0:
            print(f"  {cat_name}: ~{count}")
    
    return iter(selected)


def build(list_only=False):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    content_path = OUT_DIR / "drugs.content"
    index_path = OUT_DIR / "drugs.index"

    blob = bytearray()
    records = []
    for title, preview, extra, raw in collect_drugs_filtered():
        if list_only:
            print(f"  {title}")
            continue
        start = len(blob)
        blob += len(raw).to_bytes(8, "little")
        blob += brotli.compress(raw, quality=11)
        end = len(blob)
        records.append((
            "|".join([title, preview, str(start), str(end), extra]),
            raw,
        ))

    if list_only:
        return

    content_path.write_bytes(bytes(blob))
    index_plain = ("\n".join(r[0] for r in records) + "\n").encode("utf-8")
    index_path.write_bytes(index_plain)

    # Round-trip verification on sampled entries
    samples = [0, len(records) // 2, len(records) - 1]
    if len(records) > 3:
        samples += [random.randrange(len(records)) for _ in range(5)]
    for i in set(samples):
        line, original = records[i]
        _, _, start, end, _ = line.split("|")
        chunk = bytes(blob[int(start):int(end)])
        size = int.from_bytes(chunk[:8], "little")
        assert size == len(original), f"entry {i} size prefix mismatch"
        assert brotli.decompress(chunk[8:]) == original, f"entry {i} round-trip mismatch"

    content_mb = len(blob) / (1024 * 1024)
    raw_mb = sum(len(r[1]) for r in records) / (1024 * 1024)
    print(f"\n[drugs] {len(records)} entries")
    print(f"  content: {raw_mb:.1f} MB raw -> {content_mb:.1f} MB brotli "
          f"({100 - content_mb / max(raw_mb, 1e-9) * 100:.0f}% smaller)")
    print(f"  index:   {index_path.stat().st_size / 1024:.0f} KB")
    print("  round-trip verified for", len(set(samples)), "sampled entries")


if __name__ == "__main__":
    list_only = "--list" in sys.argv
    build(list_only=list_only)
