#!/usr/bin/env python
# this script converts html to markdown
# usage: ./html_to_md.py <input1.html> <input2.html> ...
# example: ./html_to_md.py input.html another.html
# uses beautifulsoup4 and markdownify
# and saves to <original file name>.md

import sys
import os  # Import the os module for path manipulation

import markdownify
from bs4 import BeautifulSoup


def convert_html_to_md(html_file):
    """
    Converts an HTML file to Markdown and saves it as a new .md file.
    """
    try:
        with open(
            html_file, "r", encoding="utf-8"
        ) as file:  # Added encoding for better compatibility
            html = file.read()
    except FileNotFoundError:
        print(f"Error: File not found: {html_file}", file=sys.stderr)
        return
    except Exception as e:
        print(f"Error reading {html_file}: {e}", file=sys.stderr)
        return

    soup = BeautifulSoup(html, "html.parser")
    md = markdownify.markdownify(str(soup))

    # Ensure the output file has a .md extension and handles cases where input might not end in .html
    base_name, ext = os.path.splitext(html_file)
    output_file = base_name + ".md"

    try:
        with open(
            output_file, "w", encoding="utf-8"
        ) as file:  # Added encoding for better compatibility
            file.write(md)
        print(f"Converted '{html_file}' to '{output_file}'")
    except Exception as e:
        print(f"Error writing to {output_file}: {e}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) < 2:  # Changed condition to allow multiple arguments
        print("Usage: ./html_to_md.py <input1.html> [input2.html ...]")
        sys.exit(1)

    # Iterate over all command-line arguments starting from the second one (index 1)
    for html_arg in sys.argv[1:]:
        # Basic check for .html extension, though os.path.splitext handles it robustly
        if not html_arg.lower().endswith(".html"):
            print(
                f"Warning: Skipping '{html_arg}'. Not an HTML file (does not end with .html).",
                file=sys.stderr,
            )
            continue
        convert_html_to_md(html_arg)
