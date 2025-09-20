#!/usr/bin/env python3

import os
import sys


def clean_markdown_images(directory="."):
    """
    Removes lines starting with '!' (Markdown image syntax) from all .md files
    in the specified directory.
    """
    print(f"Starting to clean Markdown files in '{os.path.abspath(directory)}'...")

    found_files = False
    for filename in os.listdir(directory):
        if filename.lower().endswith(".md"):
            filepath = os.path.join(directory, filename)
            found_files = True

            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    lines = f.readlines()

                cleaned_lines = [
                    line for line in lines if not line.strip().startswith("!")
                ]

                if len(cleaned_lines) < len(lines):
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.writelines(cleaned_lines)
                    print(
                        f"  Cleaned: {filename} ({len(lines) - len(cleaned_lines)} lines removed)"
                    )
                else:
                    print(f"  Skipped: {filename} (no lines starting with '!' found)")
            except Exception as e:
                print(f"  Error processing {filename}: {e}", file=sys.stderr)

    if not found_files:
        print(f"No .md files found in '{os.path.abspath(directory)}'.")
    else:
        print("Cleaning complete.")


if __name__ == "__main__":
    if len(sys.argv) > 2:
        print("Usage: ./clean_md_images.py [directory]", file=sys.stderr)
        print(
            "  If no directory is provided, it cleans files in the current directory.",
            file=sys.stderr,
        )
        sys.exit(1)

    target_directory = sys.argv[1] if len(sys.argv) == 2 else "."
    clean_markdown_images(target_directory)
