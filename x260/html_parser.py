from bs4 import BeautifulSoup

# Read HTML content from the file
with open("html_element.txt", "r", encoding="utf-8") as file:
    html_content = file.read()

# Parse HTML using BeautifulSoup
soup = BeautifulSoup(html_content, "html.parser")

# Find all <p> elements containing questions
question_paragraphs = soup.find_all("p")

# Extract and print the text content and choices of each question
for index, paragraph in enumerate(question_paragraphs):
    if paragraph.find(
        "span", class_="blue"
    ):  # Check if the paragraph contains a question
        question_text = (
            paragraph.find("span", class_="blue")
            .get_text(strip=True)
            .split("-", 1)[-1]
            .strip()
        )
        print(f"Question {index + 1}: {question_text}")
        input_elements = paragraph.find_all("input", type="radio")

        # Multiple choice a through d
        choice_letters = ["a", "b", "c", "d"]

        # Extract the value attribute for each choice and print with choice_letters
        for input_element in input_elements:
            choice_text = input_element.next_sibling.strip()
            print(
                f"{choice_letters[input_elements.index(input_element)]}. {choice_text}"
            )
        print("")
