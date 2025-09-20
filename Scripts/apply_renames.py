#!/usr/bin/env python3
import csv
from pathlib import Path

CSV_FILE = "rename_map.csv"
DRY_RUN = False  # set False to actually rename


def main():
    p = Path(CSV_FILE)
    if not p.exists():
        print(f"{CSV_FILE} not found.")
        return

    total = 0
    conflicts = 0
    renamed = 0

    with p.open("r", encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            old_path = Path(row["old_path"])
            new_base = row["new_basename"]
            if not old_path.is_file():
                print(f"Skip (not a file): {old_path}")
                continue

            target = old_path.with_name(new_base)
            total += 1

            if target.exists():
                print(f"Skip (target exists): {target}")
                conflicts += 1
                continue

            print(f"{'DRY-RUN ' if DRY_RUN else ''}Rename: {old_path} -> {target}")
            if not DRY_RUN:
                old_path.rename(target)
                renamed += 1

    print(
        f"Entries: {total}, Conflicts: {conflicts}, {'Would rename' if DRY_RUN else 'Renamed'}: {total - conflicts}"
    )


if __name__ == "__main__":
    main()
