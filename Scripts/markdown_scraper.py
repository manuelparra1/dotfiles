#!/home/dusts/.miniconda3/bin/python3

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

# Parse HTML using lxml.
tree = html.fromstring(html_content)

# Build a dynamic XPath expression based on keywords.
keywords = ["main", "body", "content", "article", "maincontent"]
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

# Find all matching elements.
matches = tree.xpath(xpath_expr)
if not matches:
    print("Error: No elements found matching dynamic XPath.")
    sys.exit(1)


# Choose the candidate with the most text content as a simple heuristic.
def score_element(el):
    return len(el.text_content().strip())


best_element = max(matches, key=score_element)
print("Best matching element selected based on text length.")

# Convert the best element to an HTML string and then to Markdown.
element_html = html.tostring(best_element, encoding="unicode")
markdown_text = md(element_html)

# Process images: download them and update their src attributes.
images_dir = "images"
if not os.path.exists(images_dir):
    os.makedirs(images_dir)

# Update img tags in the best_element
for img in best_element.xpath(".//img"):
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
    # Update image src to local path.
    img.set("src", f"./images/{filename}")

# Convert the updated best element to Markdown again.
element_html = html.tostring(best_element, encoding="unicode")
markdown_text = md(element_html)

# Post-process the markdown: remove any occurrences of "---\n\n"
markdown_text = re.sub(r"---\n\n", "", markdown_text)

# Append source information at the bottom.
markdown_text += f"\n\n---\n\n>  Source: {url}\n"

output_filename = "output.md"
with open(output_filename, "w") as f:
    f.write(markdown_text)

print(f"Markdown saved to {output_filename}")
