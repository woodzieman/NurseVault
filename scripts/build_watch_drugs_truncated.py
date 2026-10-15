#!/usr/bin/env python3
"""Build watch drug reference with truncated content for all drugs.

Instead of filtering to ~600 high-priority drugs, include all 2,383 drugs
but truncate each drug-information.txt to a small prefix (default 8 KB)
containing the Nursing Quick-Reference Summary. This keeps the watch
dataset small enough for RAM while providing full coverage.

Usage:
    python3 scripts/build_watch_drugs_truncated.py --size 8   # 8 KB per entry
    python3 scripts/build_watch_drugs_truncated.py --size 16  # 16 KB per entry
"""
import brotli
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


def truncate_utf8(raw: bytes, max_bytes: int) -> bytes:
    """Truncate to a valid UTF-8 prefix of at most `max_bytes` bytes."""
    if len(raw) <= max_bytes:
        return raw
    # Decode/re-encode through Python's UTF-8 to guarantee a valid boundary.
    # `errors="ignore"` drops any incomplete trailing multi-byte sequence.
    return raw[:max_bytes].decode("utf-8", errors="ignore").encode("utf-8")


def build(truncate_kb: int = 8):
    truncate_bytes = truncate_kb * 1024
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    content_path = OUT_DIR / "drugs.content"
    index_path = OUT_DIR / "drugs.index"

    blob = bytearray()
    records = []
    count = 0
    for folder in sorted(p for p in DRUG_INFO.iterdir() if p.is_dir()):
        content_file = folder / "drug-information.txt"
        if not content_file.is_file():
            continue
        raw = content_file.read_bytes()
        truncated = truncate_utf8(raw, truncate_bytes)
        generic = folder.name.split(" and ")[0].strip()
        title = clean_one_line(generic)
        text = truncated.decode("utf-8", errors="ignore")
        preview = make_preview(text, prefer_prefix="Drug Class:")
        extra = clean_one_line(drug_brands(folder))
        start = len(blob)
        blob += len(truncated).to_bytes(8, "little")
        blob += brotli.compress(truncated, quality=11)
        end = len(blob)
        records.append(f"{title}|{preview}|{start}|{end}|{extra}")
        count += 1

    content_path.write_bytes(bytes(blob))
    index_path.write_bytes(("\n".join(records)+"\n").encode("utf-8"))
    print(f"Built {count} drugs with {truncate_kb} KB truncation")
    print(f"Content size: {len(blob)/1024/1024:.2f} MB")
    print(f"Index size: {index_path.stat().st_size/1024:.0f} KB")


if __name__ == "__main__":
    size = 8
    if "--size" in sys.argv:
        idx = sys.argv.index("--size")
        try:
            size = int(sys.argv[idx + 1])
        except Exception:
            pass
    build(truncate_kb=size)
