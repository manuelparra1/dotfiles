#!/usr/bin/env python3
import os
import re
import sys

if len(sys.argv) != 2:
    sys.exit("Usage: replace_images.py <markdown_file>")

md_file = sys.argv[1]
with open(md_file, "r", encoding="utf-8") as f:
    text = f.read()


def repl(match):
    alt = match.group(1)
    url = match.group(2)
    name = os.path.basename(url)
    return f"![{alt}](./images/{name})"


new_text = re.sub(r"!\[([^\]]*)\]\(([^)]+)\)", repl, text)

with open(md_file, "w", encoding="utf-8") as f:
    f.write(new_text)
