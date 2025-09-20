import re
import sys


def extract_definitions(sdcv_output):
    # Extract content within <li> tags
    definitions = re.findall(r"<li>(.*?)</li>", sdcv_output)

    # Remove any remaining HTML tags inside <li> content (like <i> or <small>)
    definitions = [
        re.sub(r"<.*?>", "", definition).strip() for definition in definitions
    ]

    # Join definitions into a readable format
    return "\n".join(definitions)


# Read sdcv output from standard input
sdcv_output = sys.stdin.read()
cleaned_definitions = extract_definitions(sdcv_output)
print(cleaned_definitions)
