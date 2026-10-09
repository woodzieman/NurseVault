#!/usr/bin/env python3
"""Generate the watch-sized Drug Reference index.

Output is a plain pipe-delimited text file (one drug per line):

    <generic>|<brand1>|<brand2>|<summary>

Design notes
------------
* **Generic + at most two brand names.** A nurse glancing at a watch wants the
  generic and the one or two brand names they'll actually say out loud. The
  source ``names.txt`` files list up to 333 brands for some drugs; we keep
  only the first two (the most commonly used). No brand name contains a pipe,
  so ``|`` is a safe field separator with no escaping.
* **Combo (hyphenated) drugs are kept as their own entries.** A combination
  like "Acetaminophen-Aspirin" has its *own* brand names (e.g. "Excedrin
  Back and Body") and its *own* combination dosing, which differ from the
  individual components. ~92 combos have no separate entry for a component at
  all. Splitting them into their pieces would lose that distinct, searchable
  info, so they stay whole. (An explicit exceptions list could be added later
  if a specific combo ever proves redundant — none do as of this dataset.)
* **Summary = the nursing "Drug Class" line** — the single highest-value
  at-a-glance fact, kept short for a watch face.

Read by ``WatchDrugLibrary`` in NurseVaultCore. Regenerate after any
``DrugInfo/`` data refresh.
"""
from pathlib import Path

drug_root = Path("/Users/josephwoods/Documents/Nursing app/DrugInfo")
# SPM bundles resources from the target source root (Sources/NurseVaultCore/),
# which is what Package.swift's `.copy("Resources/WatchDrugIndex.txt")` reads.
out_txt = Path("/Users/josephwoods/Documents/Nursing app/Packages/NurseVaultCore/Sources/NurseVaultCore/Resources/WatchDrugIndex.txt")

MAX_BRANDS = 2
MAX_SUMMARY_CHARS = 500


def parse_names(path: Path):
    """Return (generic_name, [brands]) from a names.txt file."""
    generic = None
    brands = []
    if not path.exists():
        return generic, brands
    in_brands = False
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        t = line.strip()
        if t.startswith("Drug:"):
            generic = t.split(":", 1)[1].strip()
        elif t.startswith("Generic name:") and not generic:
            generic = t.split(":", 1)[1].strip()
        elif t.startswith("- ") and in_brands:
            b = t[2:].strip()
            if b:
                brands.append(b)
        elif t.lower().startswith("trade/brand"):
            in_brands = True
    return generic, brands


def drug_class(content: str) -> str:
    """Extract the nursing 'Drug Class' summary line from a drug-information.txt.

    Falls back to the first few non-header lines so every entry has *some*
    at-a-glance text.
    """
    lines = content.splitlines()
    in_block = False
    for line in lines:
        s = line.strip()
        if "NURSING QUICK-REFERENCE SUMMARY" in s:
            in_block = True
            continue
        if not in_block:
            continue
        if s.lower().startswith("auto-generated"):
            continue
        if s.startswith("Drug Class:"):
            return s.split(":", 1)[1].strip()
        # Stop at the first non-summary content line.
        if s and not s.startswith(("Drug Class:", "Routes:", "Common Side Effects",
                                   "In an Overdose:", "Key Nursing Considerations:")):
            break
    # Fallback: first non-empty body line.
    for line in lines:
        s = line.strip()
        if s and not s.startswith(("=", "Source:", "Retrieved:", "NURSING", "Auto-generated")):
            return s[:MAX_SUMMARY_CHARS]
    return ""


def clean(field: str) -> str:
    """Make a field safe for the single-line pipe format."""
    field = field.replace("|", "/").replace("\r", " ").replace("\n", " ")
    while "  " in field:
        field = field.replace("  ", " ")
    return field.strip()


entries = []
for folder in sorted([p for p in drug_root.iterdir() if p.is_dir()]):
    generic, brands = parse_names(folder / "names.txt")
    if not generic:
        generic = folder.name
    brands = brands[:MAX_BRANDS]

    summary = ""
    info = folder / "drug-information.txt"
    if info.exists():
        summary = drug_class(info.read_text(encoding="utf-8", errors="ignore"))[:MAX_SUMMARY_CHARS]

    # Always emit 4 fields: generic, brand1, brand2 (may be empty), summary.
    b1 = clean(brands[0]) if len(brands) > 0 else ""
    b2 = clean(brands[1]) if len(brands) > 1 else ""
    entries.append("|".join([clean(generic), b1, b2, clean(summary)]))

out_txt.parent.mkdir(parents=True, exist_ok=True)
out_txt.write_text("\n".join(entries) + "\n", encoding="utf-8")
size_kb = out_txt.stat().st_size / 1024
print(f"Wrote {len(entries)} drugs to {out_txt}")
print(f"Size: {size_kb/1024:.2f} MB ({size_kb:.0f} KB)")
