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

# --- Scraping Functions ---


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
    Attempts to find the main content element using a broad dynamic XPath.
    If the found element seems too sparse, it falls back to domain‐specific selectors.
    """
    # Prioritize article elements first
    article_xpath = "//article"
    article_matches = tree.xpath(article_xpath)
    if article_matches:
        best_article = max(
            article_matches, key=lambda el: len(el.text_content().strip())
        )
        if len(best_article.text_content().strip()) > 100:
            print("Main content found using article element.")
            return best_article, article_xpath

    # Then try the specific CSS path structure
    gatsby_xpath = "//div[@id='___gatsby']//article//div[contains(@class, 'Grid')]//div[contains(@class, 'Cell')]"
    gatsby_matches = tree.xpath(gatsby_xpath)
    if gatsby_matches:
        best_gatsby = max(gatsby_matches, key=lambda el: len(el.text_content().strip()))
        if len(best_gatsby.text_content().strip()) > 100:
            print("Main content found using Gatsby structure.")
            return best_gatsby, gatsby_xpath

    # Continue with your existing dynamic approach
    keywords = [
        "article",  # Moved to top for priority
        "main",
        "body",
        "content",
        "maincontent",
        "question",
        "answer",
        "forum",
    ]
    # Rest of your function remains the same...
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
        # Heuristic: require at least 100 characters of text
        if len(best_element.text_content().strip()) > 100:
            print("Main content found using dynamic XPath.")
            return best_element, xpath_expr
        else:
            print("Dynamic XPath found elements, but none have enough content.")
    else:
        print("No elements found using dynamic XPath.")

    # Domain-specific fallback (example: repost.aws)
    parsed_url = urlparse(url)
    domain = parsed_url.netloc.lower()
    if "repost.aws" in domain:
        print("Applying site-specific logic for repost.aws")
        question_xpath = "//div[contains(@class, 'QuestionDetail_banner')]"
        question_matches = tree.xpath(question_xpath)
        if question_matches:
            best_question = max(
                question_matches, key=lambda el: len(el.text_content().strip())
            )
            print("Main question found using site-specific selector.")
            return best_question, question_xpath
        answer_xpath = "//div[contains(@class, 'ResponseDetail_container')]"
        answer_matches = tree.xpath(answer_xpath)
        if answer_matches:
            best_answer = max(
                answer_matches, key=lambda el: len(el.text_content().strip())
            )
            print("Main answer found using site-specific selector.")
            return best_answer, answer_xpath

    # Fallback: use entire <body>
    print("Falling back to the <body> element.")
    body = tree.xpath("//body")
    if body:
        return body[0], "//body"
    else:
        print("Error: <body> element not found.")
        sys.exit(1)


def scrape_markdown(url):
    # Set up Selenium with headless Chrome.
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    driver = webdriver.Chrome(options=chrome_options)
    driver.get(url)
    time.sleep(3)  # Wait for full page load
    html_content = driver.page_source
    driver.quit()

    tree = html.fromstring(html_content)
    main_element, used_selector = get_main_content(tree, url)
    print(f"Using selector: {used_selector}")

    # Convert element to HTML then to Markdown.
    element_html = html.tostring(main_element, encoding="unicode")
    markdown_text = md(element_html)

    # Process images: download and update src attributes.
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
        img.set("src", f"./images/{filename}")

    # Reconvert the updated element to Markdown.
    element_html = html.tostring(main_element, encoding="unicode")
    markdown_text = md(element_html)
    markdown_text = re.sub(r"---\n\n", "", markdown_text)
    markdown_text += f"\n\n---\n\n>  Source: {url}\n"
    return markdown_text


# --- LLM Cleaning Function (Google GenAI) ---


def clean_markdown_with_llm(markdown_text):
    """
    Sends the scraped markdown to Google Gemini Flash
    Returns the cleaned markdown text.
    """
    from google import genai
    from google.genai import types

    client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
    model = "gemini-2.0-flash"
    # model = "gemini-2.0-flash-lite"

    # Combine instructions and input into one message since system role is not supported.
    cleaning_instructions = (
        "You are provided with a markdown document generated from an HTML scraper. Transform the document as follows:\n\n"
        '1. **Remove Useless Navigation:** Delete any navigation content (e.g. numbered lists or links like "[Home](/)", "[PAN-OS](/content/techdocs/...)""Related sections with links to other pages in articles or forum posts", "related questions and sections in forum posts", "remove sections named related") that does not belong to the main content.\n'
        "2. **Process Image References:** Remove all full image paths. For every image reference, extract only the base image file name and replace its path with a local destination (`./images/`).\n"
        "   *Example:* `![Filter icon](/content/dam/techdocs/en_US/images/icons/css/filter.svg)` should become `![](./images/filter.svg)`\n"
        "3. **Improve Markdown Structure:** Ensure that the main title is a top-level header using `#` and use nested header levels (`##`, `###`) appropriately to structure the content.\n"
        "4. **Preserve Content Integrity:** Keep all meaningful text, descriptions, and lists, and format them using best-practice markdown (e.g., use block quotes for descriptive text when appropriate).\n"
        "5. **Extra Clean-Up:** Remove author information, article date, and about-the-author footer info.\n\n"
        "**Important:** Do not remove or modify the final line that starts with `>  Source:`. Ensure that this source attribution remains exactly as is at the bottom of the transformed markdown.\n\n"
        "Please transform the following markdown document accordingly\n\n"
        "**Important:** Please output the markdown content not encapsulated with codeblocks because it will saved directly as markdown:\n\n"
    )

    final_message = cleaning_instructions + markdown_text

    contents = [
        types.Content(role="user", parts=[types.Part.from_text(text=final_message)]),
    ]

    generate_content_config = types.GenerateContentConfig(
        temperature=0.6,
        top_p=0.95,
        top_k=40,
        max_output_tokens=8192,
        response_modalities=["text"],
        response_mime_type="text/plain",
    )

    cleaned_text = ""
    for chunk in client.models.generate_content_stream(
        model=model,
        contents=contents,
        config=generate_content_config,
    ):
        if (
            not chunk.candidates
            or not chunk.candidates[0].content
            or not chunk.candidates[0].content.parts
        ):
            continue

        cleaned_text += chunk.candidates[0].content.parts[0].text or ""

    return cleaned_text


# --- Main Script ---

if len(sys.argv) != 2:
    print("Usage: python3 script.py <URL>")
    sys.exit(1)

url = sys.argv[1]

# 1. Scrape the page and generate initial markdown.
print("Scraping content from the URL...")
markdown_text = scrape_markdown(url)
output_filename = generate_filename(url)
# with open(output_filename, "w") as f:
#     f.write(markdown_text)
# print(f"Initial markdown saved to {output_filename}")

# 2. Clean the markdown using the LLM.
print("Sending markdown to LLM for cleaning...")
cleaned_markdown = clean_markdown_with_llm(markdown_text)
# clean_output_filename = output_filename.replace(".md", "_clean.md")
with open(output_filename, "w") as f:
    f.write(cleaned_markdown)
# print(f"Cleaned markdown saved to {clean_output_filename}")
print(f"Cleaned markdown saved to {output_filename}")
