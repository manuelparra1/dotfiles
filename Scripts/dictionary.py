#!/usr/bin/env python3

import re
import subprocess
import sys


def get_definition(word):
    # Call sdcv and capture output
    try:
        sdcv_output = subprocess.run(
            ["sdcv", word], capture_output=True, text=True, check=True
        )
        return sdcv_output.stdout
    except subprocess.CalledProcessError:
        print("Error: sdcv failed or word not found.")
        sys.exit(1)


def extract_definitions(sdcv_output):
    # Extract content within <li> tags
    definitions = re.findall(r"<li>(.*?)</li>", sdcv_output)
    # Clean any remaining HTML tags
    definitions = [
        re.sub(r"<.*?>", "", definition).strip() for definition in definitions
    ]
    return "\n".join(definitions)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: dictionary.py <word>")
        sys.exit(1)

    word = sys.argv[1]
    sdcv_output = get_definition(word)
    cleaned_definitions = extract_definitions(sdcv_output)
    print(cleaned_definitions)
