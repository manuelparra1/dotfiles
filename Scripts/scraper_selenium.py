import selenium as sel

driver = sel.webdriver.Chrome()


> Using a list of links how Can I use a loop for selenium to copy the contents of a html div tag?
> 
> 
> "css path":
> ```html
> 
> html#html body.wp-singular.post-template-default.single.single-post.postid-552.single-format-standard.wp-theme-networklessons.has-site-notification-bar.widget-area-in-view div#page.site div.site-content.container div.site-content-row.row div#primary.content-area.col-md-8 main#main.site-main
> 
> ```
> 
> "xpath":
> ```html
> //*[@id="main"]
> ```
> 
> "css selector":
> ```html
> #main
> ```

```python
links = ["https://example.com/page1", "https://example.com/page2", "https://example.com/page3"]

for link in links:
    driver.get(link)
    content = driver.find_element("css selector", "#main").text
    # save as html file
    # later use another script that converts the html file to markdown
```

Use `driver.get(url)` to navigate, then `find_element()` with your CSS selector `#main` to grab the div's text content. The `.text` attribute extracts visible text; use `.get_attribute("innerHTML")` if you need the raw HTML.

> Can you provide the entire code for achieving?

```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

# List of URLs to scrape
links = [
    "https://example.com/page1",
    "https://example.com/page2",
    "https://example.com/page3"
]

# Initialize Chrome driver
driver = webdriver.Chrome()

try:
    for index, link in enumerate(links, start=1):
        # Navigate to the page
        driver.get(link)
        
        # Wait for the #main div to load (up to 10 seconds)
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "#main"))
        )
        
        # Find the div and extract HTML content
        main_div = driver.find_element(By.CSS_SELECTOR, "#main")
        html_content = main_div.get_attribute("innerHTML")
        
        # Save to HTML file
        filename = f"page_{index}.html"
        with open(filename, "w", encoding="utf-8") as file:
            file.write(html_content)
        
        print(f"Saved: {filename}")
        time.sleep(1)  # Polite delay between requests

finally:
    driver.quit()
```

This script navigates each URL, waits for `#main` to load, extracts its HTML, and saves it to numbered files. The `WebDriverWait` ensures the element exists before scraping, preventing errors on slow-loading pages.
