#!/home/dusts/.miniconda3/bin/python3

import sys
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from lxml import html
from markdownify import markdownify as md
from openai import OpenAI

# Initialize the OpenAI client (ensure your API key is set in your environment)
client = OpenAI()

# Transformation instructions as a system message.
prompt_instructions = """
You are provided with a markdown document generated from an HTML scraper. Transform the document as follows:

1. **Remove Useless Navigation:** Delete any navigation content (e.g. numbered lists or links like "[Home](/)", "[PAN-OS](/content/techdocs/...)") that does not belong to the main content.
2. **Process Image References:** Remove all full image paths. For every image reference, extract only the base image file name and replace its path with a local destination (`./images/`).  
   *Example:*  
   `![Filter icon](/content/dam/techdocs/en_US/images/icons/css/filter.svg)`  
   should become  
   `![](./images/filter.svg)`
3. **Improve Markdown Structure:**  
   - Ensure that the main title is a top-level header using `#`  
   - Use nested header levels (e.g., `##`, `###`) appropriately to structure the content.
4. **Preserve Content Integrity:** Keep all meaningful text, descriptions, and lists, and format them using best-practice markdown (e.g., use block quotes for descriptive text).
"""

if len(sys.argv) != 2:
    print("Usage: python3 selenium_html_to_markdown.py <URL>")
    sys.exit(1)

url = sys.argv[1]

# Set up Selenium with headless Chrome
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")

# Initialize webdriver (ensure chromedriver is in PATH or specify its location)
driver = webdriver.Chrome(options=chrome_options)
driver.get(url)

# Optional: wait for the page to load completely
time.sleep(3)  # adjust the sleep time as needed

# Get the page source
html_content = driver.page_source
driver.quit()

# Parse HTML using lxml
tree = html.fromstring(html_content)

# Build a dynamic XPath expression based on keywords.
keywords = ["main", "body", "content", "article", "maincontent"]
conditions = []
for kw in keywords:
    # For case-insensitive search, we use translate() on the attributes.
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

# Convert the best element to HTML string and then to Markdown.
element_html = html.tostring(best_element, encoding="unicode")
markdown_text = md(element_html)

output_filename = "output.md"

# Send the markdown to GPT‑4o‑mini for transformation.
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role": "system", "content": prompt_instructions},
        {"role": "user", "content": markdown_text},
    ],
    temperature=0.75,
    max_tokens=8000,
    top_p=1,
    frequency_penalty=0,
    presence_penalty=0,
)

# Retrieve the transformed markdown.
transformed_markdown = response.choices[0].message.content

# Save the final markdown output.
with open(output_filename, "w") as f:
    f.write(transformed_markdown)

print(f"Markdown saved to {output_filename}")
