Merck Manual Professional Edition - Clinical Calculators (offline working copies)
=================================================================================

Retrieved: from the live site on 2026-09-26.
Source:   https://www.merckmanuals.com/professional/pages-with-widgets/clinical-calculators?mode=list

What this is
------------
All 174 clinical calculators from the Merck Manual Professional Edition,
downloaded as the exact self-contained HTML files the Manual itself serves
in iframes (https://www.merckmanuals.com/iframe/manual/medical-calculators/<name>.htm).
No reverse engineering was required: the site's widget files are plain,
standalone HTML with inline JavaScript and are directly downloadable.


HOW TO OPEN (important)
-----------------------
These are JavaScript web pages. They will NOT work in Quick Look
(spacebar in Finder) or the Preview app - those render HTML but never
execute JavaScript (you can type, but nothing computes, and clicking
a link opens another preview).

To use a calculator, open the file in a real web browser:

  1. Double-click "Open Calculators.command" in this folder -> opens the
     full catalog (index.html) in Safari; click any calculator name.
  2. Or drag any .htm file onto a Safari/Chrome/Firefox window.
  3. Or make .htm files always open in Safari: right-click any .htm
     -> Get Info -> "Open with:" -> Safari -> "Change All...".

Everything runs 100% offline from this folder; no internet needed.
The calculators are the Manual's own (EBMcalc engine, inline JS); if
you ever want the canonical/current version, index.html links to each
live page.

Usage
-----
Open index.html in a browser (double-click), then pick a calculator.
Or open any individual .htm file directly. Everything works fully offline;
no internet or API access is needed.

Files
-----
  index.html            - catalog of all 174 calculators (use this)
  <name>.htm            - the calculator (172 files; 2 calculators share each of 2 files)
  medcalcstyles.css     - shared stylesheet, "EBMcalc primary style sheet,
                          Copyright 1998-2020 EBMcalc, LLC"
  disclaimer-en.htm     - the Manual's calculator disclaimer (linked from each)
  pubmed.gif, ncbi.gif, worldcat.gif
                        - reference-link icons
  manifest.json         - machine-readable list: title, file, live page URL

Provenance note
---------------
The Manual's June 2024 site migration deleted medcalcstyles.css, ncbi.gif and
worldcat.gif from the live media library (the live calculators therefore render
unstyled today). Those three files were restored from the Wayback Machine
snapshots of 2024-06-09 / 2025-04-12 of the same /iframe/ URLs.

Retrieval script: workspace merck-tools/calculators_worker.py
(master list: merck-tools/data/calculator_list.json, 174 docs from the
clinical-calculators page's embedded SearchStax response).

Disclaimer: the calculators are the Manual's, including its disclaimer and
source citations. For personal/educational use; consult the live Manual for
the canonical, current version.
