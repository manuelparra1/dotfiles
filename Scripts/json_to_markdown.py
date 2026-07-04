import json
import sys
from pathlib import Path


def format_ts(seconds: float) -> str:
    """Convert float seconds to HH:MM:SSs, flooring to whole seconds."""
    total = int(seconds)  # matches your 2.04 -> 00:00:02s behavior
    h = total // 3600
    m = (total % 3600) // 60
    s = total % 60
    return f"{h:02d}:{m:02d}:{s:02d}s"


def json_to_markdown(data) -> str:
    lines = []
    for seg in sorted(data, key=lambda x: x.get("start", 0)):
        ts = format_ts(seg.get("start", 0))
        text = seg.get("text", "").strip()
        if not text:
            continue
        lines.append(f"_**{ts}**_")
        lines.append(text)
        lines.append("")  # blank line between entries
    return "\n".join(lines).strip() + "\n"


if __name__ == "__main__":
    # usage: python convert.py transcript.json > transcript.md
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "transcript.json")
    data = json.loads(path.read_text(encoding="utf-8"))
    md = json_to_markdown(data)
    sys.stdout.write(md)
