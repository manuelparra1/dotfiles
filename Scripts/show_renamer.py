#!/usr/bin/env python3
import os
import re
import json
import argparse
import subprocess
from pathlib import Path

VIDEO_EXTS = {
    ".mkv",
    ".mp4",
    ".m4v",
    ".avi",
    ".mov",
    ".wmv",
    ".ts",
    ".mpeg",
    ".mpg",
    ".flv",
    ".webm",
}


def natural_sort_key(s):
    import re

    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", s)]


def list_videos():
    print("Listing videos...")
    files = [
        p for p in Path(".").iterdir() if p.is_file() and p.suffix.lower() in VIDEO_EXTS
    ]
    print(f"Found {len(files)} videos.")
    return sorted(files, key=lambda p: natural_sort_key(p.name))


def normalize_resolution(text):
    if not text:
        return ""
    t = text.lower()
    if any(k in t for k in ("4320", "4320p", "8k")):
        return "8K"
    if any(k in t for k in ("2160", "2160p", "4k")):
        return "4K"
    if any(k in t for k in ("1440", "1440p", "2k")):
        return "2K"
    if any(k in t for k in ("1080", "1080p")):
        return "1080p"
    if any(k in t for k in ("720", "720p")):
        return "720p"
    m = re.search(r"(\d{3,4}[pi])", t)
    return m.group(1) if m else ""


def norm_video_codec(text):
    if not text:
        return ""
    t = text.lower()
    if any(k in t for k in ("hevc", "h265", "x265")):
        return "x265"
    if any(k in t for k in ("avc", "h264", "x264")):
        return "x264"
    return ""


def norm_audio_codec(text):
    if not text:
        return ""
    t = text.lower()
    if re.search(r"(e[-_ ]?ac-?3|ddp|dd\+|dolbydigitalplus)", t):
        return "E-AC-3"
    if re.search(r"(ac-?3|dd\b|dolbydigital\b)", t):
        return "AC-3"
    if re.search(r"(dts[-_ ]?hd|dts[-_ ]?ma|dtsma)", t):
        return "DTS-HD"
    if re.search(r"\bdts\b", t):
        return "DTS"
    if re.search(r"(true[-_ ]?hd|truehd)", t):
        return "TrueHD"
    if "flac" in t:
        return "FLAC"
    if "aac" in t:
        return "AAC"
    return ""


def parse_scene_name(name):
    # Extract season/episode
    se = ""
    m = re.search(r"[Ss](\d{1,2})[Ee](\d{1,3})", name)
    if m:
        se = f"S{int(m.group(1)):02d}E{int(m.group(2)):02d}"

    # Show name candidate (before SxxEyy or before a year)
    show_raw = name
    if se and se in name:
        show_raw = name.split(se, 1)[0]
    else:
        show_raw = re.split(r"([12][09]\d{2})", name)[0]
    show_raw = re.sub(r"[._]+", " ", show_raw).strip(" -._")

    # Country suffix -> parentheses
    m = re.search(r"(.*)\b(US|UK|AU|CA|JP|KR)$", show_raw)
    if m:
        show = f"{m.group(1).rstrip()} ({m.group(2)})"
    else:
        show = show_raw

    # Resolution candidate
    m = re.search(
        r"(4320p|2160p|1440p|1080p|720p|4320|2160|1440|1080|720|4K|8K)", name, re.I
    )
    res = normalize_resolution(m.group(1) if m else "")

    # Source / type
    src, srctype = "", ""
    if re.search(r"blu[- ]?ray|bdrip|brrip", name, re.I):
        src = "BluRay"
    if re.search(r"web[- .]?dl|web[- .]?rip|web", name, re.I):
        src, srctype = "WEB", "DL"
    if re.search(r"hdtv|hdrip", name, re.I):
        src = "HDTV"
    if re.search(r"dvdrip|dvd", name, re.I):
        src = "DVD"

    # Codecs
    m = re.search(r"(hevc|h\.?265|x265|avc|h\.?264|x264)", name, re.I)
    vcodec = norm_video_codec(m.group(1) if m else "")
    m = re.search(
        r"(eac3|e[-_ ]?ac-?3|ddp|dd\+|ac3|dd|dts[-_ ]?hd|dts[-_ ]?ma|dts|true[-_ ]?hd|truehd|aac|flac)",
        name,
        re.I,
    )
    acodec = norm_audio_codec(m.group(1) if m else "")

    # Group
    group = ""
    m = re.search(r"-([A-Za-z0-9]+)$", name)
    if m:
        group = m.group(1)
    if not group:
        m = re.search(r"\[([A-Za-z0-9]+)\]$", name)
        if m:
            group = m.group(1)
    if not group:
        m = re.search(r"(RARBG|TGx|YIFY|NTb|CAKES|AMZN|NF|WEB)$", name, re.I)
        if m:
            group = m.group(1)

    return {
        "show": show,
        "se": se,
        "resolution": res,
        "source": src,
        "source_type": srctype,
        "audio": acodec,
        "video": vcodec,
        "group": group,
    }


def build_target(meta, ext):
    # Omit empty fields; omit “Extra Info” by design
    parts = [meta["show"]]
    if meta["se"]:
        parts.append(meta["se"])
    if meta["resolution"]:
        parts.append(meta["resolution"])
    bracket = ""
    if meta["source"]:
        bracket += f"[{meta['source']}]"
        if meta["source_type"]:
            bracket += f"[{meta['source_type']}]"
    if meta["audio"]:
        bracket += f"[{meta['audio']}]"
    if meta["video"]:
        bracket += f"[{meta['video']}]"
    if meta["group"]:
        bracket += f"[{meta['group']}]"
    if bracket:
        parts.append(bracket)
    return " - ".join(parts) + ext


def make_llm_prompt(items):
    # Provide policy and examples; ask model to return a clean JSON mapping
    policy = """
You are given a list of video filenames with extracted metadata. Normalize to:
<show name> - <season info> <parts of episodes if relevant> <editions or releases if relevant> - <resolution> - [<source>][<source type>][<audio codec>][<video codec>][<release group>].<ext>

Rules:
- Normalize video codecs: hevc/h265/x265 -> x265; avc/h264/x264 -> x264.
- Normalize audio codecs to: E-AC-3, AC-3, DTS-HD, DTS, TrueHD, AAC, FLAC when detected; else omit.
- Resolution normalization: ≥2160p -> 4K; ≥1440p -> 2K; ≥1080p -> 1080p; ≥720p -> 720p.
- Omit extra tracker/website/bitrate and unrelated info.
- Preserve extension.
- Convert suffix country code in show title to parentheses: "The Office US" -> "The Office (US)".
- Season/episode as SxxEyy; support multi-episodes like S01E01E02 -> S01E01-02 if needed.
- If a field is unknown, omit it rather than guessing.

Return strictly JSON: {"mappings": [{"old": "<oldname>", "new": "<newname>"}]}
"""
    examples = [
        {
            "old": "The.Office.US.S09E23.1080p.BluRay.x265-RARBG.mp4",
            "new": "The Office (US) - S09E23 - 1080p - [BluRay][x265][RARBG].mp4",
        }
    ]
    payload = {"policy": policy, "examples": examples, "items": items}
    return json.dumps(payload, ensure_ascii=False, indent=2)


def call_mistral(prompt_json, model="mistral-small-latest"):
    api_key = os.environ.get("MISTRAL_API_KEY", "")
    if not api_key:
        raise RuntimeError("MISTRAL_API_KEY is not set in environment.")
    data = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": "You are a precise filename normalization assistant.",
            },
            {"role": "user", "content": prompt_json},
        ],
        "response_format": {"type": "json_object"},
    }
    # Use curl to minimize dependency; you can switch to requests if preferred
    cmd = [
        "curl",
        "-sS",
        "--location",
        "https://api.mistral.ai/v1/chat/completions",
        "--header",
        "Content-Type: application/json",
        "--header",
        "Accept: application/json",
        "--header",
        f"Authorization: Bearer {api_key}",
        "--data-binary",
        json.dumps(data),
    ]
    out = subprocess.check_output(cmd, text=True)
    # The API returns { choices: [ { message: { content: "<json>" } } ] }
    obj = json.loads(out)
    content = obj["choices"][0]["message"]["content"]
    return json.loads(content)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--apply", action="store_true", help="Apply renames (otherwise dry-run)."
    )
    parser.add_argument(
        "--no-llm", action="store_true", help="Skip LLM refinement; use local mapping."
    )
    args = parser.parse_args()

    print("Scanning for videos...")
    files = list_videos()
    items = []
    local_mappings = []
    print("Parsing listing...")
    for p in files:
        name = p.name
        stem, ext = os.path.splitext(name)
        meta = parse_scene_name(name)
        newname = build_target(meta, ext)
        items.append({"old": name, "parsed": meta, "proposed": newname})
        if name != newname:
            local_mappings.append({"old": name, "new": newname})

    print("Finished parsing, created local mapping..")
    mappings = local_mappings
    if not args.no_llm:
        print("Refining with LLM...")
        prompt_json = make_llm_prompt(items)
        try:
            print("Calling LLM...")
            llm = call_mistral(prompt_json)
            print("LLM call succeeded.")
            mappings = llm.get("mappings", local_mappings)
            print("Parsing LLM results...")
        except Exception as e:
            print(f"LLM call failed, falling back to local mapping: {e}")

    print("Proposed rename plan:")
    for m in mappings:
        print(f"  {m['old']}\n  -> {m['new']}\n")

    if not args.apply:
        print("(Dry-run) Use --apply to rename.")
        return

    for m in mappings:
        old = m["old"]
        new = m["new"]
        if old == new:
            continue
        if Path(new).exists():
            print(f"Skip (target exists): {new}")
            continue
        os.rename(old, new)
    print("Done.")


if __name__ == "__main__":
    main()
