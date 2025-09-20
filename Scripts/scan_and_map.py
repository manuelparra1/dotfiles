#!/usr/bin/env python3
import os
import re
import csv
import json
from pathlib import Path
from typing import Optional, Tuple, Dict, List

# Config
SHOW_NAME = "The Office (US)"
MEDIA_EXTS = {".mkv", ".mp4", ".m4v"}
OUTPUT_CSV = "rename_map.csv"
ERROR_LOG = "rename_errors.log"

# Extras output style is fixed to bracketed tokens as requested:
# e.g., [PCOK][WEB-DL][DDP5.1][x264][FLUX]
EXTRAS_STYLE = "brackets"  # fixed to brackets

# LLM config (OpenRouter via OpenAI SDK) - optional
USE_LLM = bool(int(os.environ.get("USE_LLM", "0")))
OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY")
OPENROUTER_BASE_URL = os.environ.get(
    "OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"
)
OPENROUTER_MODEL = os.environ.get(
    "OPENROUTER_MODEL", "meta-llama/llama-3.2-3b-instruct"
)
OPENROUTER_HTTP_REFERER = os.environ.get("OPENROUTER_HTTP_REFERER", "http://localhost")
OPENROUTER_X_TITLE = os.environ.get("OPENROUTER_X_TITLE", "Filename Normalizer")
OPENROUTER_TEMPERATURE = float(os.environ.get("OPENROUTER_TEMPERATURE", "0.0"))

# Provider dictionary (extend as needed). We’ll capture uppercase canonical keys.
PROVIDERS = {
    "PCOK": "PCOK",
    "NF": "NF",
    "AMZN": "AMZN",
    "HULU": "HULU",
    "MAX": "MAX",
    "DSNP": "DSNP",
    "ITUNES": "iTunes",
    "APPLETV": "AppleTV",
    "PEACOCK": "PCOK",  # often PCOK is Peacock; keep PCOK per your samples
    "PARAMOUNT": "PARAMOUNT",
}

# Sources map: normalized as these tokens
SOURCES = {
    "WEB-DL": "WEB-DL",
    "WEBRIP": "WEBRip",
    "BLURAY": "BluRay",
    "BDRIP": "BDRip",
    "HDTV": "HDTV",
}

# Audio patterns and normalization
# We try DDP first; then common other codecs
AUDIO_PATTERNS = [
    # DDP / DD variants -> DDP5.1
    (
        re.compile(r"\b(DDP?)[\s\.]?(\d)[\s\.]?(\d)\b", re.IGNORECASE),
        lambda m: f"DDP{m.group(2)}.{m.group(3)}",
    ),
    (
        re.compile(r"\b(DDP?)(\d)\.(\d)\b", re.IGNORECASE),
        lambda m: f"DDP{m.group(2)}.{m.group(3)}",
    ),
    # Other known audio codecs (leave canonical form)
    (re.compile(r"\bEAC3\b", re.IGNORECASE), lambda m: "EAC3"),
    (re.compile(r"\bAC3\b", re.IGNORECASE), lambda m: "AC3"),
    (
        re.compile(r"\bDTS(?:-HD)?(?:\s?MA)?\b", re.IGNORECASE),
        lambda m: (
            "DTS-HD MA"
            if "HD" in m.group(0).upper() or "MA" in m.group(0).upper()
            else "DTS"
        ),
    ),
    (re.compile(r"\bTRUEHD\b", re.IGNORECASE), lambda m: "TrueHD"),
    (re.compile(r"\bATMOS\b", re.IGNORECASE), lambda m: "Atmos"),
]


# Codec normalization to your preference:
# - HEVC family -> x265
# - AVC family -> x264
# - AV1 -> AV1
def normalize_codec_token(s: str) -> Optional[str]:
    u = s.upper()
    if re.search(r"\bx?265\b", u) or re.search(r"\bH[\.\s]?265\b", u) or "HEVC" in u:
        return "x265"
    if re.search(r"\bx?264\b", u) or re.search(r"\bH[\.\s]?264\b", u) or "AVC" in u:
        return "x264"
    if re.search(r"\bAV1\b", u):
        return "AV1"
    return None


def dedup_spaces(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def strip_ext(basename: str) -> Tuple[str, str]:
    m = re.search(r"\.(mkv|mp4|m4v)$", basename, re.IGNORECASE)
    if not m:
        return basename, ""
    ext = m.group(0)
    return basename[: -len(ext)], ext


def clean_trackers(s: str) -> str:
    # Remove [tags], (tags), {tags}
    s = re.sub(r"\[[^\]]*\]", "", s)
    s = re.sub(r"\([^)]*\)", "", s)
    s = re.sub(r"\{[^}]*\}", "", s)
    return s


def normalize_title_spacing(title: str) -> str:
    title = title.replace(".", " ")
    title = re.sub(r"\bPart\.?(\d)\b", r"Part \1", title, flags=re.IGNORECASE)
    title = re.sub(r"\bPart(\d)\b", r"Part \1", title, flags=re.IGNORECASE)
    title = re.sub(r"\bK\b(?=\s)", "K.", title)  # Dwight K -> K.
    title = title.replace("WUPHF com", "WUPHF.com")
    title = dedup_spaces(title)
    # Guard against stray standalone H at end
    if title == "H":
        return ""
    title = re.sub(r"\s+[Hh]$", "", title)
    return title


def parse_season_episode(name: str) -> Optional[Tuple[int, int, Optional[int], str]]:
    """
    Detects SxxEyy, optional range SxxEyy-Ezz or SxxEyyEzz or SxxEyy.Ezz
    Returns (season, ep_start, ep_end_or_None, remainder)
    """
    m = re.search(
        r"\bS(\d{1,2})E(\d{1,2})(?:[-\. ]?E?(\d{1,2}))?\b", name, re.IGNORECASE
    )
    if not m:
        return None
    s = int(m.group(1))
    e1 = int(m.group(2))
    e2 = int(m.group(3)) if m.group(3) else None
    remainder = name[m.end() :].strip(" -._")
    return s, e1, e2, remainder


def extract_editions(s: str) -> Tuple[bool, str]:
    # Extended flags: EXTENDED, Extended Cut, Superfan (Episodes)
    extended = False
    if re.search(
        r"\b(EXTENDED|Extended Cut|Superfan(?: Episodes)?)\b", s, re.IGNORECASE
    ):
        extended = True
        s = re.sub(r"\bExtended Cut\b", "", s, flags=re.IGNORECASE)
        s = re.sub(r"\bEXTENDED\b", "", s, flags=re.IGNORECASE)
        s = re.sub(r"\bSuperfan(?: Episodes)?\b", "", s, flags=re.IGNORECASE)
    return extended, dedup_spaces(s)


def find_and_remove(pattern: re.Pattern, s: str) -> Tuple[Optional[str], str]:
    m = pattern.search(s)
    if not m:
        return None, s
    val = m.group(0)
    s = s[: m.start()] + s[m.end() :]
    return val, dedup_spaces(s)


def rstrip_token(s: str) -> str:
    return s.strip(" -._")


def extras_from_right(s: str) -> Tuple[Dict[str, Optional[str]], str]:
    """
    Consume extras from the right using dictionaries/patterns.
    Returns comps dict and the remaining string (title-ish).
    comps keys: res, provider, source, audio, video, group
    """
    comps = {
        "res": None,
        "provider": None,
        "source": None,
        "audio": None,
        "video": None,
        "group": None,
    }

    work = s

    # Normalize WEB tokens first to unify source recognition
    work = re.sub(r"\bWEB[- ]?DL\b", "WEB-DL", work, flags=re.IGNORECASE)
    work = re.sub(r"\bWEB[- ]?Rip\b", "WEBRip", work, flags=re.IGNORECASE)

    # 1) Group: attempt to capture trailing -GROUP or trailing token after a dash/dot/space near the end
    # Prefer a -GROUP at the end
    mg = re.search(r"-([A-Za-z0-9]{2,12})\s*$", work)
    if mg:
        comps["group"] = mg.group(1)
        work = work[: work.rfind("-")]
        work = rstrip_token(work)
    else:
        # Sometimes group is last bare token; capture cautiously only if it follows a hyphen or is clearly last segment
        mg2 = re.search(r"(?:^|[\s\.\-])([A-Za-z0-9]{2,12})\s*$", work)
        # We will NOT capture a group this way for now to avoid false positives. Only -GROUP at end.
        pass

    # 2) Video codec: x264/x265/AV1/H 264/H.264/H 265/H.265/HEVC/AVC
    mv = None
    # Find any of the codec forms anywhere; we'll strip the rightmost occurrence
    codec_patterns = [
        r"\bx?264\b",
        r"\bx?265\b",
        r"\bAV1\b",
        r"\bH[\.\s]?264\b",
        r"\bH[\.\s]?265\b",
        r"\bHEVC\b",
        r"\bAVC\b",
    ]
    for pat in codec_patterns:
        mv = re.search(pat, work, flags=re.IGNORECASE)
        if mv:
            # Normalize to your preference
            norm = normalize_codec_token(mv.group(0))
            if norm:
                comps["video"] = norm
            # Remove the matched token
            work = work[: mv.start()] + work[mv.end() :]
            work = dedup_spaces(work)
    # Remove any orphan standalone 'H' created by space splits around codec
    work = re.sub(r"\bH\b$", "", work).strip()

    # 3) Audio: try each pattern; take first match from right
    for pat, fn in AUDIO_PATTERNS:
        m = pat.search(work)
        if m:
            comps["audio"] = fn(m)
            work = work[: m.start()] + work[m.end() :]
            work = dedup_spaces(work)
            break

    # 4) Source: WEB-DL/WEBRip/BluRay/BDRip/HDTV
    for k, v in SOURCES.items():
        ms = re.search(rf"\b{k}\b", work, flags=re.IGNORECASE)
        if ms:
            comps["source"] = v
            work = work[: ms.start()] + work[ms.end() :]
            work = dedup_spaces(work)
            break

    # 5) Provider: from PROVIDERS keys
    for k, v in PROVIDERS.items():
        mp = re.search(rf"\b{k}\b", work, flags=re.IGNORECASE)
        if mp:
            comps["provider"] = v
            work = work[: mp.start()] + work[mp.end() :]
            work = dedup_spaces(work)
            break

    # 6) Resolution: 720p/1080p/2160p etc.
    mr = re.search(r"\b(\d{3,4}p)\b", work, flags=re.IGNORECASE)
    if mr:
        comps["res"] = mr.group(1)
        work = work[: mr.start()] + work[mr.end() :]
        work = dedup_spaces(work)

    title_rem = rstrip_token(work)
    return comps, title_rem


def build_extras_brackets(c: Dict[str, Optional[str]]) -> str:
    """
    Build bracketed extras block in order: [provider][source][audio][video][group?]
    Omit unknown/empty. If nothing, return empty string.
    """
    tokens: List[str] = []
    if c.get("provider"):
        tokens.append(c["provider"])
    if c.get("source"):
        tokens.append(c["source"])
    if c.get("audio"):
        tokens.append(c["audio"])
    if c.get("video"):
        tokens.append(c["video"])
    if c.get("group"):
        tokens.append(c["group"])

    if not tokens and not c.get("res"):
        return ""

    extras = "".join(f"[{t}]" for t in tokens)
    # Place after resolution, with a leading " - "
    if c.get("res"):
        return f" - {c['res']} - {extras}" if extras else f" - {c['res']}"
    else:
        # No resolution detected; still return extras as a block
        return f" - {extras}" if extras else ""


def local_normalize(old_basename: str) -> Optional[str]:
    base, _ext = strip_ext(old_basename)

    # Working copy: unify separators for detection only
    work = base.replace("_", " ")
    work = work.replace(".", " ")
    work = dedup_spaces(work)

    # Normalize known show prefixes at start to a common form for title extraction
    work = re.sub(
        r"^\s*The Office( Superfan Episodes| US|)\s*",
        "The Office ",
        work,
        flags=re.IGNORECASE,
    )

    parsed = parse_season_episode(work)
    if not parsed:
        return None
    s, e1, e2, remainder = parsed

    # Editions
    extended, remainder = extract_editions(remainder)

    # Extras via right-to-left tokenization
    comps, title_raw = extras_from_right(remainder)

    # Episode token
    if e2:
        ep_token = f"S{s:02d}E{e1:02d}-E{e2:02d}"
    else:
        ep_token = f"S{s:02d}E{e1:02d}"

    # Title cleanup
    title = re.sub(r"^\W+|\W+$", "", title_raw).strip()
    title = normalize_title_spacing(title)

    # Build name
    parts = [SHOW_NAME, ep_token]
    if title:
        parts.append(title)
    if extended:
        parts.append("Extended")

    # Extras block
    extras = build_extras_brackets(comps)

    new_base = " - ".join(parts) + extras
    new_base = dedup_spaces(new_base)
    return new_base


def call_llm_bulk(basenames):
    if not OPENROUTER_API_KEY:
        raise RuntimeError("OPENROUTER_API_KEY not set but USE_LLM=1")
    from openai import OpenAI

    client = OpenAI(base_url=OPENROUTER_BASE_URL, api_key=OPENROUTER_API_KEY)
    system = "You normalize TV episode filenames to a strict format. Output JSON mapping: {old_basename: new_basename}."
    user_instr = {
        "target_format": " -  -  -  -  - [provider][source][audio][video][group?]",
        "rules": [
            "Keep the original extension.",
            "Normalize audio: DD 5 1 / DDP5 1 / DDP5.1 -> DDP5.1; also allow AC3, EAC3, DTS, DTS-HD MA, TrueHD, Atmos.",
            "Normalize codec: h264/H.264/x264/AVC -> x264; h265/H.265/HEVC/x265 -> x265; AV1 -> AV1.",
            "Strip [..], (..), {..} tracker tags.",
            "Preserve release group when explicitly present as trailing -GROUP; omit if unknown.",
            "Use WEB-DL/WEBRip/BluRay/BDRip/HDTV as present.",
            "If there is an explicit episode range (e.g., S07E11-E12), keep that in the episode token.",
            "Output extras as [provider][source][audio][video][group?] after the resolution segment.",
        ],
        "examples": [
            [
                "The Office US S07E11-E12 Classy Christmas Extended Cut 1080p PCOK WEB-DL DDP5 1 H 264-FLUX.mkv",
                "The Office (US) - S07E11-E12 - Classy Christmas - Extended - 1080p - [PCOK][WEB-DL][DDP5.1][x264][FLUX].mkv",
            ],
            [
                "The.Office.US.S03E10.Part1.Part2.EXTENDED.1080p.PCOK.WEB-DL.DDP5.1.H.264-TEPES.mkv",
                "The Office (US) - S03E10 - Part 1 Part 2 - Extended - 1080p - [PCOK][WEB-DL][DDP5.1][x264][TEPES].mkv",
            ],
        ],
        "basenames": basenames,
    }
    resp = client.chat.completions.create(
        extra_headers={
            "HTTP-Referer": OPENROUTER_HTTP_REFERER,
            "X-Title": OPENROUTER_X_TITLE,
        },
        model=OPENROUTER_MODEL,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": json.dumps(user_instr)},
        ],
        temperature=OPENROUTER_TEMPERATURE,
    )
    # OpenAI SDK returns list of choices; access message.content
    content = (
        resp.choices[0].message.content
        if hasattr(resp.choices[0], "message")
        else resp.choices[0].text
    )
    try:
        mapping = json.loads(content)
        return mapping if isinstance(mapping, dict) else {}
    except Exception:
        return {}


def main():
    root = Path(".")
    media = []
    for p in root.rglob("*"):
        if p.is_file() and p.suffix.lower() in MEDIA_EXTS:
            media.append(p)

    if not media:
        print("No media files found.")
        return

    old_to_new: Dict[str, str] = {}
    errs = []
    need_llm = []

    for p in media:
        ob = p.name
        nb_base = local_normalize(ob)
        if nb_base:
            old_to_new[str(p)] = nb_base + p.suffix
        else:
            need_llm.append(ob)

    if USE_LLM and need_llm:
        try:
            llm_map = call_llm_bulk(need_llm)
            for p in media:
                if str(p) in old_to_new:
                    continue
                ob = p.name
                nb = llm_map.get(ob)
                if nb:
                    old_to_new[str(p)] = nb
                else:
                    errs.append(f"LLM could not map: {p}")
        except Exception as e:
            errs.append(f"LLM error: {e}")

    # Write CSV with header and quoting
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, quoting=csv.QUOTE_ALL)
        w.writerow(["old_path", "new_basename"])
        for old_path, new_base in sorted(old_to_new.items()):
            w.writerow([old_path, new_base])

    if errs:
        with open(ERROR_LOG, "w", encoding="utf-8") as ef:
            ef.write("\n".join(errs) + "\n")

    print(f"Wrote {OUTPUT_CSV} with {len(old_to_new)} entries.")
    print(f"Errors: {len(errs)} (see {ERROR_LOG} if > 0)")


if __name__ == "__main__":
    main()
