#!/usr/bin/env python3
"""
weekly_update.py v2
Find Obsidian notes created last workweek (Mon–Fri) based on YAML frontmatter
and copy them into week-based folders with a subfolder per day.

Output structure:
~/Downloads/Found-Files-Weekly-Update/
  2026-W15_2026-04-07_to_2026-04-11/
    Monday-04-07/
    Tuesday-04-08/
    Wednesday-04-09/
    Thursday-04-10/
    Friday-04-11/
"""

import re
import shutil
from pathlib import Path
from datetime import date, timedelta

# --- CONFIG ---
VAULT_DIR = Path.home() / "aston/Notes/Obsidian/aston"
DEST_BASE = Path.home() / "Downloads/Found-Files-Weekly-Update"
# --------------

def get_prev_workweek():
    today = date.today()
    this_monday = today - timedelta(days=today.weekday())
    prev_monday = this_monday - timedelta(days=7)
    prev_friday = prev_monday + timedelta(days=4)
    return prev_monday, prev_friday

def parse_created(content: str):
    m = re.search(r'^---\s*\n(.*?)\n---', content, re.DOTALL | re.MULTILINE)
    if not m:
        return None
    front = m.group(1)
    cm = re.search(r'^created:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})', front, re.MULTILINE)
    if not cm:
        return None
    try:
        return date.fromisoformat(cm.group(1))
    except ValueError:
        return None

def main():
    prev_mon, prev_fri = get_prev_workweek()
    iso_year, iso_week, _ = prev_mon.isocalendar()

    # Week folder using ISO week number
    week_folder = DEST_BASE / f"{iso_year}-W{iso_week:02d}_{prev_mon}_to_{prev_fri}"
    week_folder.mkdir(parents=True, exist_ok=True)

    # Create day subfolders
    day_map = {}
    for i in range(5):
        d = prev_mon + timedelta(days=i)
        day_dir = week_folder / f"{d.strftime('%A')}-{d.strftime('%m-%d')}"
        day_dir.mkdir(parents=True, exist_ok=True)
        day_map[d] = day_dir

    print(f"Previous workweek: {prev_mon} (Mon) to {prev_fri} (Fri) — ISO Week {iso_year}-W{iso_week:02d}")
    print(f"Destination: {week_folder}")

    found = []
    for md_file in VAULT_DIR.rglob("*.md"):
        try:
            text = md_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        created = parse_created(text)
        if created and prev_mon <= created <= prev_fri:
            # preserve relative vault path inside the day folder to avoid collisions
            rel = md_file.relative_to(VAULT_DIR)
            target_dir = day_map[created]
            target = target_dir / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(md_file, target)
            found.append((created, rel))

    # Summary
    print(f"\nCopied {len(found)} file(s):")
    for d in sorted(day_map):
        day_files = [rel for c, rel in found if c == d]
        day_name = day_map[d].name
        print(f"  {day_name}/ ({len(day_files)} files)")
        for f in sorted(day_files):
            print(f"    - {f}")

if __name__ == "__main__":
    main()
