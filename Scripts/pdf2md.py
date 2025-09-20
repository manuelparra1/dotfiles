import sys
import pytesseract
from pdf2image import convert_from_path

# Get PDF file path from command line arguments
pdf_path = sys.argv[1]

# Convert PDF to images (each page as an image)
images = convert_from_path(pdf_path)

# Apply OCR on each image and store results
ocr_text = [pytesseract.image_to_string(image) for image in images]

# Combine all text from each page into a single Markdown-formatted string
md_text = "\n\n".join(
    f"### Page {i+1}\n\n{page_text}" for i, page_text in enumerate(ocr_text)
)

# Generate output file name by removing the old extension
output_path = pdf_path.rsplit('.', 1)[0] + '.md'

# Save the result to the new Markdown file
with open(output_path, "w") as file:
    file.write(md_text)

print(f"OCR completed. Markdown saved to {output_path}")
