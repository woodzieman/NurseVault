#!/usr/bin/env python3
"""Generate the watch-sized Merck Manual index.

Output: a **zlib-compressed** pipe-delimited text file, one topic per line:

    <id>|<title>|<specialty>|<subspecialty>|<summary>

* The plain text is zlib-compressed before it is bundled, so the on-watch
  footprint stays small (~0.6 MB instead of ~2.7 MB). `WatchMerckLibrary`
  decompresses it with `NSData.decompressed(using: .zlib)` at load time.
* Pipe is the field separator — no field contains a pipe, so
  `maxSplits: 4` yields exactly five fields.
* `summary` is the first paragraph of each topic, kept short for a watch.

Regenerate after any `MerckTopics/` data refresh.
"""
import zlib
from pathlib import Path

merck_root = Path("/Users/josephwoods/Documents/Nursing app/MerckTopics")
out_zlib = Path(
    "/Users/josephwoods/Documents/Nursing app/Packages/NurseVaultCore/Sources/NurseVaultCore/Resources/WatchMerckIndex.txt.zlib"
)

MAX_SUMMARY_CHARS = 600


def clean(field: str) -> str:
    field = field.replace("|", "/").replace("\r", " ").replace("\n", " ")
    while "  " in field:
        field = field.replace("  ", " ")
    return field.strip()


def first_paragraph(text: str) -> str:
    for para in text.split("\n\n"):
        para = para.strip()
        if para:
            return para
    return text.strip()


entries = []
for specialty_dir in sorted([p for p in merck_root.iterdir() if p.is_dir()]):
    specialty = specialty_dir.name
    for sub in sorted(specialty_dir.iterdir()):
        if not sub.is_dir():
            continue
        subspecialty = sub.name
        for file in sorted(sub.iterdir()):
            if not (file.is_file() and file.suffix.lower() == ".txt"):
                continue
            title = file.stem
            try:
                text = file.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                text = ""
            summary = clean(first_paragraph(text))[:MAX_SUMMARY_CHARS]
            entries.append(
                "|".join(
                    [
                        clean(f"{specialty}/{subspecialty}/{title}"),
                        clean(title),
                        clean(specialty),
                        clean(subspecialty),
                        summary,
                    ]
                )
            )

out_zlib.parent.mkdir(parents=True, exist_ok=True)
plain = ("\n".join(entries) + "\n").encode("utf-8")
compressed = zlib.compress(plain)  # zlib-wrapped; matches NSData .zlib
out_zlib.write_bytes(compressed)

plain_kb = len(plain) / 1024
comp_kb = len(compressed) / 1024
print(f"Wrote {len(entries)} topics")
print(f"Plain: {plain_kb/1024:.2f} MB  ->  zlib: {comp_kb/1024:.2f} MB ({comp_kb:.0f} KB)")
