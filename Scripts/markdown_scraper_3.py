#!/home/dusts/.miniconda3/envs/scraping/bin/python

import sys
import os
import time
import re
import requests
from urllib.parse import urljoin, urlparse
from lxml import html
from markdownify import markdownify as md
from selenium import webdriver
from selenium.webdriver.chrome.options import Options


def generate_filename(url):
    parsed = urlparse(url)
    # Remove any trailing slashes
    path = parsed.path.rstrip("/")
    # Get the last section of the path
    last_section = path.split("/")[-1]
    # Remove file extension if present
    last_section = os.path.splitext(last_section)[0]
    # Replace hyphens with underscores
    filename = last_section.replace("-", "_") + ".md"
    return filename


def get_main_content(tree, url):
    """
    Try to find the main content element using a broad dynamic XPath.
    If the found element seems insufficient, apply site-specific selectors.
    """
    # Broad dynamic XPath using common keywords
    keywords = [
        "main",
        "body",
        "content",
        "article",
        "maincontent",
        "question",
        "answer",
        "forum",
    ]
    conditions = []
    for kw in keywords:
        conditions.append(
            f"contains(translate(@id, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '{kw.lower()}')"
        )
        conditions.append(
            f"contains(translate(@class, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '{kw.lower()}')"
        )
    xpath_expr = "//*[" + " or ".join(conditions) + "]"
    print(f"Dynamic XPath expression: {xpath_expr}")
    matches = tree.xpath(xpath_expr)

    if matches:
        best_element = max(matches, key=lambda el: len(el.text_content().strip()))
        # Heuristic: require at least 100 characters of text to be considered valid
        if len(best_element.text_content().strip()) > 100:
            print("Main content found using dynamic XPath.")
            return best_element, xpath_expr
        else:
            print("Dynamic XPath found elements, but none have enough content.")
    else:
        print("No elements found using dynamic XPath.")

    # Domain-specific logic for known sites (example for repost.aws)
    parsed_url = urlparse(url)
    domain = parsed_url.netloc.lower()
    if "repost.aws" in domain:
        print("Applying site-specific logic for repost.aws")
        # Try to get the question container first
        question_xpath = "//div[contains(@class, 'QuestionDetail_banner')]"
        question_matches = tree.xpath(question_xpath)
        if question_matches:
            best_question = max(
                question_matches, key=lambda el: len(el.text_content().strip())
            )
            print("Main question found using site-specific selector.")
            return best_question, question_xpath

        # Alternatively, try to capture answer containers
        answer_xpath = "//div[contains(@class, 'ResponseDetail_container')]"
        answer_matches = tree.xpath(answer_xpath)
        if answer_matches:
            best_answer = max(
                answer_matches, key=lambda el: len(el.text_content().strip())
            )
            print("Main answer found using site-specific selector.")
            return best_answer, answer_xpath

    # Fallback: use the entire <body>
    print("Falling back to the <body> element.")
    body = tree.xpath("//body")
    if body:
        return body[0], "//body"
    else:
        print("Error: <body> element not found.")
        sys.exit(1)


if len(sys.argv) != 2:
    print("Usage: python3 html_to_markdown.py <URL>")
    sys.exit(1)

url = sys.argv[1]

# Set up Selenium with headless Chrome.
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")
driver = webdriver.Chrome(options=chrome_options)
driver.get(url)
# Wait for the page to load completely.
time.sleep(3)
html_content = driver.page_source
driver.quit()

# Parse HTML.
tree = html.fromstring(html_content)

# Retrieve main content using our multi-tier approach.
main_element, used_selector = get_main_content(tree, url)
print(f"Using selector: {used_selector}")

# Convert the selected element to HTML and then to Markdown.
element_html = html.tostring(main_element, encoding="unicode")
markdown_text = md(element_html)

# Process images: download them and update their src attributes.
images_dir = "images"
if not os.path.exists(images_dir):
    os.makedirs(images_dir)

for img in main_element.xpath(".//img"):
    src = img.get("src")
    if not src:
        continue
    img_url = urljoin(url, src)
    filename = os.path.basename(urlparse(img_url).path)
    local_path = os.path.join(images_dir, filename)
    if not os.path.exists(local_path):
        try:
            img_response = requests.get(img_url)
            if img_response.status_code == 200:
                with open(local_path, "wb") as f:
                    f.write(img_response.content)
                print(f"Downloaded image: {filename}")
            else:
                print(
                    f"Failed to download image {img_url} (status {img_response.status_code})"
                )
        except Exception as e:
            print(f"Error downloading image {img_url}: {e}")
    # Update the image src to the local path.
    img.set("src", f"./images/{filename}")

# Reconvert the updated element to Markdown.
element_html = html.tostring(main_element, encoding="unicode")
markdown_text = md(element_html)

# Remove unwanted horizontal rules from the markdown.
markdown_text = re.sub(r"---\n\n", "", markdown_text)

# Append source attribution.
markdown_text += f"\n\n---\n\n>  Source: {url}\n"

# Generate output filename based on the URL.
output_filename = generate_filename(url)
with open(output_filename, "w") as f:
    f.write(markdown_text)

print(f"Markdown saved to {output_filename}")
