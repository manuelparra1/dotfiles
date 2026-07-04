import re
import sys


def extract_headings(input_file):
    output_file = f"{input_file.rsplit('.', 1)[0]}_headings.md"

    with open(input_file, "r", encoding="utf-8") as infile, open(
        output_file, "w", encoding="utf-8"
    ) as outfile:

        for line in infile:
            if re.match(r"^\s*#+", line):
                outfile.write(line)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python find_markdown_headings.py <file_name>")
        sys.exit(1)

    extract_headings(sys.argv[1])
