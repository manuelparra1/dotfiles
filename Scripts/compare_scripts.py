#!/usr/bin/env python3
import difflib
import json
import os
import urllib.request
from pathlib import Path

# --- Configuration ---
DIR_A = Path.home() / "Scripts"
DIR_B = Path.home() / "Github" / "dotfiles" / "Scripts"
API_URL = "https://openrouter.ai/api/v1/chat/completions"
MODEL = "deepseek/deepseek-v4-flash"

# Retrieve API key from environment
API_KEY = os.environ.get("OPENROUTER_API_KEY")


def get_llm_analysis(filename, content_a, content_b, diff_text):
    """Sends the diff and full contents to OpenRouter to analyze which version is better."""
    if not API_KEY:
        print(
            "⚠️  Error: OPENROUTER_API_KEY environment variable not found. Skipping LLM analysis."
        )
        return None

    # Triple-quotes perfectly safely encapsulate your markdown backticks
    prompt = f"""
        You are an expert developer assisting in resolving a code divergence between two versions of a script named '{filename}'.
        One version is from a live local directory (Version A), and the other is from a dotfiles git repository (Version B).

        Here is the unified diff between them:

        ```diff
        {diff_text}

        ```

        For context, here is the full content of Version A (~/Scripts):

        ```text
        {content_a}
        ```

        For context, here is the full content of Version B (~/Github/dotfiles/Scripts):

        ```text
        {content_b}
        ```

        Analyze both versions. Determine which version is functionally superior, more complete, or safer to keep.
        Provide a concise summary of the critical differences and explicitly state which version (A or B) you recommend keeping and why.
    """

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/local/script-comparator",  # Optional OpenRouter identification
    }

    data = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": prompt,
            }
        ],
    }

    req = urllib.request.Request(
        API_URL, data=json.dumps(data).encode("utf-8"), headers=headers
    )

    try:
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode("utf-8"))
            return res_data["choices"][0]["message"]["content"]
    except Exception as e:
        return f"Error communicating with OpenRouter: {e}"


def compare_directories():
    if not DIR_A.exists() or not DIR_B.exists():
        print(f"❌ Ensure both directories exist:\n- {DIR_A}\n- {DIR_B}")
    return


files_a = {f.name for f in DIR_A.iterdir() if f.is_file()}
files_b = {f.name for f in DIR_B.iterdir() if f.is_file()}
all_files = sorted(files_a.union(files_b))

for filename in all_files:
    path_a = DIR_A / filename
    path_b = DIR_B / filename

    # Case 1: File only exists in ~/Scripts
    if path_a.exists() and not path_b.exists():
        print(f"--- \nℹ️  [Only in ~/Scripts]: {filename}")
        continue

    # Case 2: File only exists in ~/Github/dotfiles/Scripts
    if not path_a.exists() and path_b.exists():
        print(f"--- \nℹ️  [Only in dotfiles]: {filename}")
        continue

    # Case 3: File exists in both, check for differences
    try:
        with open(path_a, "r", errors="ignore") as f:
            lines_a = f.readlines()
        with open(path_b, "r", errors="ignore") as f:
            lines_b = f.readlines()
    except Exception as e:
        print(f"Skipping {filename} due to read error: {e}")
        continue

    # Generate a standard unified diff
    diff = list(
        difflib.unified_diff(
            lines_a,
            lines_b,
            fromfile=f"~/Scripts/{filename}",
            tofile=f"~/Github/dotfiles/Scripts/{filename}",
            lineterm="",
        )
    )

    if diff:
        print(f"\n==================================================")
        print(f"💥 DIVERGENCE FOUND: {filename}")
        print(f"==================================================")

        diff_text = "\n".join(diff)
        content_a = "".join(lines_a)
        content_b = "".join(lines_b)

        print("🤖 Querying DeepSeek flash for analysis...")
        analysis = get_llm_analysis(filename, content_a, content_b, diff_text)

        print("\n📊 LLM Analysis & Recommendation:")
        print(analysis)
        print("-" * 50)
    else:
        # Files match perfectly
        pass

if __name__ == "__main__":
    compare_directories()
