#!/usr/bin/env python3
import argparse
import re
import os

def extract_image_links(md_text):
    pattern = re.compile(r'!\[.*?\]\((.*?)\)', re.DOTALL)
    return pattern.findall(md_text)

def main():
    parser = argparse.ArgumentParser(description='Extract markdown image links.')
    parser.add_argument('markdown_file', help='Path to the markdown file')
    parser.add_argument('-o', '--output', help='Output text file (default: <input>_links.txt)')
    args = parser.parse_args()

    with open(args.markdown_file, 'r', encoding='utf-8') as f:
        md_text = f.read()

    links = extract_image_links(md_text)

    output_path = args.output
    if not output_path:
        base, _ = os.path.splitext(args.markdown_file)
        output_path = f"{base}_links.txt"

    with open(output_path, 'w', encoding='utf-8') as out:
        for link in links:
            out.write(link + '\n')

    print(f"Extracted {len(links)} links to {output_path}")

if __name__ == "__main__":
    main()
