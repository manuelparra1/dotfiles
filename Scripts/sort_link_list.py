#!/usr/bin/env python3

import re
import sys


def main():
    # Check if the correct number of arguments is provided
    if len(sys.argv) != 2:
        print("Usage: python sort_link_list.py <input_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = input_file.replace(".md", "_sorted.md")

    # Read the input file
    with open(input_file, "r") as file:
        text = file.read()

    # Extract header-link pairs
    entries = re.findall(r"### (.*?)\n(https?://.*?)(?=\n### |\Z)", text, re.DOTALL)

    # Sort by header text
    sorted_entries = sorted(entries, key=lambda x: x[0].lower())

    # Reconstruct sorted text
    sorted_text = "\n".join(f"### {header}\n{link}" for header, link in sorted_entries)

    # Write the sorted text to the output file
    with open(output_file, "w") as file:
        file.write(sorted_text)


if __name__ == "__main__":
    main()
