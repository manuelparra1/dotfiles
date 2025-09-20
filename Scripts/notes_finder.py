#!/usr/bin/env python3

import os
import re
import shutil
from datetime import datetime

# Configuration
search_root = "."  # starting directory
target_root = "./Notes-Found"
date_format = "%Y-%m-%dT%H:%M:%S"
start_date = datetime(2025, 8, 25)
end_date = datetime(2025, 8, 29)

# Regular expression to find the created date
created_re = re.compile(r"created:\s*([0-9T:-]+)")


def find_and_copy_notes():
    for dirpath, _, filenames in os.walk(search_root):
        for fname in filenames:
            if not fname.endswith(".md"):
                continue
            filepath = os.path.join(dirpath, fname)
            with open(filepath, "r", encoding="utf-8") as f:
                for line in f:
                    m = created_re.match(line.strip())
                    if m:
                        created_str = m.group(1)
                        try:
                            created_dt = datetime.strptime(created_str, date_format)
                        except ValueError:
                            continue
                        if start_date <= created_dt <= end_date:
                            weekday = created_dt.strftime("%A")
                            target_dir = os.path.join(target_root, weekday)
                            os.makedirs(target_dir, exist_ok=True)
                            shutil.copy2(filepath, target_dir)
                        break  # Found the created line, can stop reading this file


if __name__ == "__main__":
    find_and_copy_notes()
    print("Done!")
