#!/usr/bin/env python3
"""Build the on-watch "full reference": a tiny in-RAM index + a seekable content store.

The watch keeps the *full* article text (drugs + Merck Manual) on its own disk,
but never loads it all at once. Two files are produced per dataset:

  <name>.content
      Every entry's text, individually brotli-compressed (quality 11),
      concatenated into one blob in order. Each entry is prefixed with an
      8-byte little-endian uncompressed size, because Apple's libcompression
      cannot infer the inflated size — the app needs it to size its buffer.
      Brotli (not zlib) because in the Swift 6.4 / SDK 27 toolchain
      libcompression's zlib decode silently passes input through; brotli is
      the decode path verified to round-trip (and it compresses text ~25%
      better: 355 MB raw -> 37 MB for drugs). Per-entry compression still
      lets the app seek to one entry's byte range and read *just that
      entry* — the rest of the blob never enters RAM.

  <name>.index
      A plain-text, pipe-delimited manifest, one line per entry:

          <title>|<preview>|<startByte>|<endByte>|<extra>

      `startByte`/`endByte` are offsets into the *compressed* blob. `preview`
      is a short one-line snippet; `extra` carries brand names (drugs) or
      specialty/subspecialty (Merck). The whole index is a few hundred KB,
      so the *entire* list fits in RAM for paging + search. Plain text (not
      zlib) so loading the index can never depend on the inflate path.

Usage:
    python3 scripts/build_watch_reference.py [merck|drugs|all]

The generated files land in `Sources/Watch/Resources/WatchReference/`, which
the Xcode filesystem-synchronized `Sources/Watch` group picks up automatically
as watch-app resources. Regenerate after any `MerckTopics/` / `DrugInfo/`
refresh, then rebuild.
"""
import brotli
import random
import sys
import zlib  # only used for round-trip verification of the brotli stream
from pathlib import Path

ROOT = Path("/Users/josephwoods/Documents/Nursing app")
OUT_DIR = ROOT / "Sources" / "Watch" / "Resources" / "WatchReference"

# How long the per-row preview snippet is (kept short so it fits a watch row).
PREVIEW_MAX_CHARS = 80

# Lines that are metadata, never content, and must be skipped when picking a
# preview (Merck metadata header + the auto-generated drug summary header).
HEADER_PREFIXES = (
    "===",
    "Section:",
    "Source:",
    "Retrieved:",
    "NURSING QUICK-REFERENCE SUMMARY",
    "Auto-generated",
)


def clean_one_line(value: str) -> str:
    """Collapse a field to a single line with a single-space run of whitespace."""
    value = value.replace("|", "/").replace("\r", " ")
    return " ".join(value.split()).strip()


def strip_metadata_header(text: str) -> str:
    """Drop the leading metadata block (=== / Section: / Source: / Retrieved:)
    and any leading blank lines, returning the body."""
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
    """A short one-line preview for the list row.

    Skips metadata headers and the drug summary banner, skips
    '(See also ...)' cross-references, and takes the first real paragraph
    (or a line starting with `prefer_prefix`, e.g. 'Drug Class:').
    Whitespace-collapsed and capped at PREVIEW_MAX_CHARS.
    """
    body = strip_metadata_header(text)
    for para in body.split("\n\n"):
        para = para.strip()
        if not para:
            continue
        one = clean_one_line(para)
        if prefer_prefix and one.startswith(prefer_prefix):
            one = one[len(prefer_prefix):].lstrip(": ").strip()
        if len(one.split()) < 4:
            continue  # too short — likely a section header, keep looking
        if one.lower().startswith("(see also"):
            continue
        return one[:PREVIEW_MAX_CHARS]
    # Fallback: first non-empty chunk of the body.
    fallback = clean_one_line(body)
    return fallback[:PREVIEW_MAX_CHARS] if fallback else "(no preview)"


def merck_specialty(file: Path) -> str:
    """'Specialty/Subspecialty' from the file's path (or the specialty alone)."""
    parts = file.relative_to(ROOT / "MerckTopics").parent.parts
    if not parts:
        return ""
    if len(parts) == 1:
        return parts[0]
    return f"{parts[0]}/{parts[-1]}"


def drug_brands(folder: Path) -> str:
    """At most the first two trade names from names.txt, comma-joined."""
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
                break  # left the brand list
    return ", ".join(brands)


def collect_merck():
    """Yield (title, preview, extra, raw_bytes) for every Merck topic."""
    for file in sorted((ROOT / "MerckTopics").rglob("*.txt")):
        raw = file.read_bytes()
        text = raw.decode("utf-8", errors="ignore")
        yield (
            clean_one_line(file.stem),
            make_preview(text),
            clean_one_line(merck_specialty(file)),
            raw,
        )


def collect_drugs():
    """Yield (title, preview, extra, raw_bytes) for every drug.

    DrugInfo/ is one folder per drug: `<generic> and <brand>/` containing
    `names.txt` and `drug-information.txt`.
    """
    for folder in sorted(p for p in (ROOT / "DrugInfo").iterdir() if p.is_dir()):
        content = folder / "drug-information.txt"
        if not content.is_file():
            continue
        raw = content.read_bytes()
        text = raw.decode("utf-8", errors="ignore")
        generic = folder.name.split(" and ")[0].strip()
        yield (
            clean_one_line(generic),
            make_preview(text, prefer_prefix="Drug Class:"),
            clean_one_line(drug_brands(folder)),
            raw,
        )


COLLECTORS = {"merck": collect_merck, "drugs": collect_drugs}


def build(dataset: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    content_path = OUT_DIR / f"{dataset}.content"
    index_path = OUT_DIR / f"{dataset}.index"

    blob = bytearray()
    records = []
    for title, preview, extra, raw in COLLECTORS[dataset]():
        start = len(blob)
        blob += len(raw).to_bytes(8, "little")  # inflated size; libcompression can't infer it
        blob += brotli.compress(raw, quality=11)  # per-entry: keeps seek + compress
        end = len(blob)
        records.append((
            "|".join([title, preview, str(start), str(end), extra]),
            raw,
        ))

    content_path.write_bytes(bytes(blob))
    index_plain = ("\n".join(r[0] for r in records) + "\n").encode("utf-8")
    index_path.write_bytes(index_plain)  # plain text: no runtime inflate needed

    # Round-trip verification: seek back into the blob a handful of times
    # (first, middle, last, plus a few random) and confirm the size prefix +
    # inflate reproduce the original bytes.
    samples = [0, len(records) // 2, len(records) - 1]
    samples += [random.randrange(len(records)) for _ in range(5)]
    for i in samples:
        line, original = records[i]
        _, _, start, end, _ = line.split("|")
        chunk = bytes(blob[int(start):int(end)])
        size = int.from_bytes(chunk[:8], "little")
        assert size == len(original), f"[{dataset}] entry {i} size prefix mismatch"
        assert brotli.decompress(chunk[8:]) == original, f"[{dataset}] entry {i} round-trip mismatch"

    content_mb = len(blob) / (1024 * 1024)
    raw_mb = sum(len(r[1]) for r in records) / (1024 * 1024)
    print(f"[{dataset}] {len(records)} entries")
    print(f"  content: {raw_mb:.1f} MB raw -> {content_mb:.1f} MB per-entry brotli "
          f"({100 - content_mb / max(raw_mb, 1e-9) * 100:.0f}% smaller) -> {content_path}")
    print(f"  index:   {index_path.stat().st_size / 1024:.0f} KB plain text -> {index_path}")
    print("  round-trip verified for", len(set(samples)), "sampled entries")
    for i in samples[:3]:
        print("   ", records[i][0][:120])


if __name__ == "__main__":
    dataset = sys.argv[1] if len(sys.argv) > 1 else "all"
    if dataset == "all":
        for name in ("merck", "drugs"):
            build(name)
    elif dataset in COLLECTORS:
        build(dataset)
    else:
        sys.exit(f"Unknown dataset '{dataset}'. Options: merck, drugs, all")
