#!/usr/bin/env python
# STUDENT VERSION
# This script converts a Udemy practice test results HTML file into a clean
# practice test, OMITTING the correct answers and explanations.
#
# usage: ./html_to_practice_test.py <input1.html> <input2.html> ...
# example: ./html_to_practice_test.py "results.html"
#
# Requires: beautifulsoup4, markdownify
# Install with: pip install beautifulsoup4 markdownify

import sys
import os
import re
from urllib.parse import urlparse
import markdownify
from bs4 import BeautifulSoup


def add_inline_code(text):
    """
    Finds and wraps potential code elements like IP addresses and commands in backticks.
    This version is careful not to re-format text already in code blocks or links.
    """
    # Patterns for IPs, MACs, etc.
    patterns = [
        r"\b(?:\d{1,3}\.){3}\d{1,3}(?:/\d{1,2})?\b",  # IPv4
        r"\b(?:[0-9a-fA-F]{1,4}:){1,7}[:0-9a-fA-F]+\b(?::/\d{1,3})?",  # IPv6
        r"\b(?:[0-9a-fA-F]{2,4}[\.:-]){2,7}[0-9a-fA-F]{2,4}\b",  # MAC
    ]
    combined_pattern = re.compile("|".join(patterns))

    def replacer(match):
        return f"`{match.group(0)}`"

    # Split the text by existing code blocks and links to avoid double-formatting
    parts = re.split(r"(`[^`]+`|\[[^\]]+\]\([^\)]+\))", text)
    processed_parts = []
    for i, part in enumerate(parts):
        # If the part is a captured delimiter (already formatted), leave it as is
        if i % 2 == 1:
            processed_parts.append(part)
        else:
            # Otherwise, apply the inline code formatting
            processed_parts.append(re.sub(combined_pattern, replacer, part))

    return "".join(processed_parts)


def process_and_clean_images(html_snippet_soup):
    """
    1. Removes the hidden duplicate <img> tag that precedes the visible one.
    2. Rewrites the src of the remaining visible <img> tag to a local path.
    Returns the modified soup snippet.
    """
    if not html_snippet_soup:
        return None

    # FIX FOR DUPLICATE IMAGES
    for span_wrapper in html_snippet_soup.find_all(
        "span", class_="ud-component--base-components--open-full-size-image"
    ):
        prev_sibling = span_wrapper.find_previous_sibling()
        if (
            prev_sibling
            and prev_sibling.name == "img"
            and "display: none" in prev_sibling.get("style", "")
        ):
            prev_sibling.decompose()

    # Rewrite remaining image URLs
    for img in html_snippet_soup.find_all("img"):
        if img.get("src"):
            try:
                url = img["src"]
                filename = os.path.basename(urlparse(url).path)
                img["src"] = f"./images/{filename}"
                if img.has_attr("style"):
                    del img["style"]
            except Exception:
                pass
    return html_snippet_soup


def format_as_markdown(data):
    """Takes a dictionary of parsed question data and formats it into clean markdown."""
    if not data:
        return ""

    processed_question = add_inline_code(data["text"])
    processed_options = [add_inline_code(opt) for opt in data["options"]]
    # We no longer need to process these for the student version
    # processed_explanation = add_inline_code(data['explanation'])
    processed_resources = add_inline_code(data["resources"])

    md_parts = [f"## Question {data['number']}\n", f"### {processed_question}\n"]

    if processed_options:
        for i, option in enumerate(processed_options):
            md_parts.append(f"{chr(ord('A') + i)}. {option}")
        md_parts.append("\n")

    # --- STUDENT VERSION MODIFICATION: Omit the Correct Answer section ---
    # if data['correct_answers']:
    #     md_parts.append("#### Correct Answer\n")
    #     md_parts.append(f"**{', '.join(sorted(data['correct_answers']))}**\n")

    # --- STUDENT VERSION MODIFICATION: Omit the Explanation section ---
    # if data['explanation'].strip():
    #     md_parts.append("> #### Overall explanation")
    #     md_parts.append(">\n")
    #     for line in data['explanation'].split('\n'):
    #         stripped_line = line.strip()
    #         md_parts.append(f"> {stripped_line}" if stripped_line else ">")
    #     md_parts.append("\n")

    if processed_resources.strip():
        md_parts.append("#### Resources\n")
        md_parts.append(f"{processed_resources.strip()}\n")

    if data["domain"].strip():
        md_parts.append("#### Domain\n")
        md_parts.append(f"_**{data['domain']}**_")

    return "\n".join(md_parts)


def parse_html_and_convert(html_file):
    """
    Reads an HTML file, parses it for structured quiz data, and saves formatted Markdown.
    """
    try:
        with open(html_file, "r", encoding="utf-8") as file:
            soup = BeautifulSoup(file, "html.parser")
    except Exception as e:
        print(f"Error reading or parsing {html_file}: {e}", file=sys.stderr)
        return

    all_questions_data = []
    question_containers = soup.find_all(
        "div", class_=re.compile(r"result-pane--question-result-pane--")
    )

    for container in question_containers:
        data = {
            "number": "N/A",
            "text": "",
            "options": [],
            "correct_answers": [],
            "explanation": "",
            "resources": "",
            "domain": "",
        }

        q_num_tag = container.find("span", string=re.compile(r"Question \d+"))
        if q_num_tag:
            data["number"] = re.search(r"(\d+)", q_num_tag.string).group(1)

        q_text_tag = container.find("div", id="question-prompt")
        if q_text_tag:
            q_text_soup = process_and_clean_images(q_text_tag)
            data["text"] = markdownify.markdownify(str(q_text_soup)).strip()

        answer_tags = container.find_all("div", attrs={"data-purpose": "answer"})
        temp_options = []
        correct_texts = set()

        for tag in answer_tags:
            option_text_tag = tag.find("div", id="answer-text")
            if not option_text_tag:
                continue

            option_text = markdownify.markdownify(str(option_text_tag)).strip()
            temp_options.append(option_text)

            is_correct_by_class = "answer-result-pane--answer-correct--" in str(
                tag.get("class", "")
            )
            is_correct_by_text = tag.find(
                "span",
                string=re.compile(
                    r"Your (answer|selection) is correct|Correct (answer|selection)",
                    re.IGNORECASE,
                ),
            )

            if is_correct_by_class or is_correct_by_text:
                correct_texts.add(option_text)

        data["options"] = temp_options
        for correct_text in correct_texts:
            if correct_text in data["options"]:
                letter = chr(ord("A") + data["options"].index(correct_text))
                if letter not in data["correct_answers"]:
                    data["correct_answers"].append(letter)

        explanation_tag = container.find("div", id="overall-explanation")
        if explanation_tag:
            explanation_soup = process_and_clean_images(explanation_tag)
            data["explanation"] = markdownify.markdownify(str(explanation_soup)).strip()

        resources_tag = container.find("div", id="resources")
        if resources_tag:
            data["resources"] = markdownify.markdownify(str(resources_tag)).strip()

        domain_pane = container.find("div", attrs={"data-purpose": "domain-pane"})
        if domain_pane:
            domain_text_tag = domain_pane.find("div", class_="ud-text-md")
            if domain_text_tag:
                data["domain"] = domain_text_tag.get_text(strip=True)

        all_questions_data.append(data)

    # --- Format and Save ---
    final_markdown = "\n\n".join([format_as_markdown(q) for q in all_questions_data])

    # Generate a descriptive output filename
    base_name, _ = os.path.splitext(html_file)
    output_file = f"practice_{base_name}.md"

    try:
        with open(output_file, "w", encoding="utf-8") as file:
            file.write(final_markdown)
        print(f"Successfully created practice test '{output_file}'")
    except Exception as e:
        print(f"Error writing to {output_file}: {e}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./html_to_practice_test.py <input1.html> [input2.html ...]")
        sys.exit(1)

    for html_arg in sys.argv[1:]:
        if not html_arg.lower().endswith((".html", ".htm")):
            print(f"Warning: Skipping '{html_arg}'. Not an HTML file.", file=sys.stderr)
            continue
        parse_html_and_convert(html_arg)
