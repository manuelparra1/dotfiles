#!/usr/bin/env python3
import argparse
import json
import logging
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import urlparse

# Try importing the client; handle error if not installed
try:
    from parallel import Parallel
except ImportError:
    print("❌ Error: 'parallel' library not found. Install it with: uv add parallel")
    sys.exit(1)

# --- Configuration & Constants ---
OUTPUT_BASE_DIR = Path("./Scraped_Articles/")
RAW_DUMP_FILE = "response_dump.json"

# Setup basic logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


def setup_arguments() -> argparse.Namespace:
    """Configures and parses command line arguments."""
    parser = argparse.ArgumentParser(
        description="CLI tool for Parallel.ai Extract API. Fetches excerpts or full content from URLs.",
        epilog='Example: python extract_cli.py "Summarize pricing" -f links.txt',
    )

    # Positional Argument: Prompt (Objective)
    # nargs='?' makes it optional (allows running just -v without a prompt)
    parser.add_argument(
        "prompt",
        nargs="?",
        help="The objective/prompt for the extraction (Required for excerpts, optional for full content).",
    )

    # Flags
    parser.add_argument(
        "urls",
        nargs="*",
        help="Direct URLs to process (e.g. http://site.com). Ignored if -f is used.",
    )

    parser.add_argument(
        "-f",
        "--file",
        type=Path,
        help="Path to a text file containing a list of URLs (one per line).",
    )

    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Fetch FULL content instead of just excerpts.",
    )

    args = parser.parse_args()
    return args


def validate_inputs(args: argparse.Namespace) -> List[str]:
    """Validates logic rules between flags and gathers the URL list."""

    # --- FIX START: Detect if 'prompt' is actually a URL ---
    # When running 'script.py -v http://site.com', argparse assigns the URL to args.prompt
    #
    # Check if the thing argparse THINKS is a prompt is actually a URL
    if args.prompt and (
        args.prompt.startswith("http://") or args.prompt.startswith("https://")
    ):
        # It's a URL, so move it from prompt to the urls list
        if args.urls is None:
            args.urls = []
        args.urls.insert(0, args.prompt)
        args.prompt = None  # Clear the prompt
    # --- FIX END ---

    # Rule 1: Prompt is required unless verbose (full content) is on
    if not args.prompt and not args.verbose:
        logger.error("A prompt/objective is REQUIRED when extracting excerpts.")
        logger.error('Usage: python extract_cli.py "<prompt>" [urls...]')
        sys.exit(1)

    urls = []

    # Source 1: File input
    if args.file:
        if not args.file.exists():
            logger.error(f"File not found: {args.file}")
            sys.exit(1)

        with open(args.file, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip()]
            urls.extend(lines)

    # Source 2: Direct arguments
    if args.urls:
        urls.extend(args.urls)

    # Final Validation
    if not urls:
        logger.error("No URLs provided. Use -f <file> or provide URLs as arguments.")
        sys.exit(1)

    # Basic URL structure check
    valid_urls = []
    for u in urls:
        parsed = urlparse(u)
        if parsed.scheme and parsed.netloc:
            valid_urls.append(u)
        else:
            logger.warning(f"Skipping invalid URL format: {u}")

    if not valid_urls:
        logger.error("No valid URLs found to process.")
        sys.exit(1)

    return valid_urls


def sanitize_filename(title: str) -> str:
    """
    Converts a title to a safe filename:
    1. Lowercase
    2. Replace spaces with underscores
    3. Remove non-alphanumeric characters (except underscore)
    """
    if not title:
        return "untitled"

    # Lowercase
    clean = title.lower()
    # Remove illegal chars (allow alphanumeric and space)
    clean = re.sub(r"[^a-z0-9\s]", "", clean)
    # Replace spaces with underscores
    clean = re.sub(r"\s+", "_", clean)
    # Truncate to avoid filesystem errors
    return clean[:100]


def save_markdown(
    result_item: Any, output_dir: Path, is_verbose: bool, objective: Optional[str]
):
    """Generates and saves the Markdown file."""

    title = getattr(result_item, "title", "untitled") or "untitled"
    url = getattr(result_item, "url", "unknown_url")
    pub_date = getattr(result_item, "publish_date", "unknown_date")

    clean_name = sanitize_filename(title)

    # Determine Content Type
    if is_verbose:
        # Full Content Mode
        suffix = "full"
        content = getattr(result_item, "full_content", "") or ""
        type_tag = "full_content"
    else:
        # Excerpt Mode
        suffix = "excerpt"
        excerpts = getattr(result_item, "excerpts", [])
        content = (
            "\n\n---\n\n".join(excerpts)
            if isinstance(excerpts, list)
            else str(excerpts)
        )
        type_tag = "excerpt"

    if not content:
        logger.warning(
            f"No content found for '{title}' ({url}). Skipping file creation."
        )
        return

    filename = f"{clean_name}_{suffix}.md"
    filepath = output_dir / filename

    # YAML Frontmatter
    md_content = f"""---
title: "{title}"
url: "{url}"
date: "{pub_date}"
type: "{type_tag}"
objective: "{objective or 'N/A'}"
---

# {title}

{content}
"""

    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(md_content)
        logger.info(f"Saved: {filepath}")
    except IOError as e:
        logger.error(f"Failed to write file {filepath}: {e}")


def main():
    # 1. Setup & Validation
    args = setup_arguments()
    urls = validate_inputs(args)

    # 2. Check API Key
    api_key = os.getenv("PARALLEL_API_KEY")
    if not api_key:
        logger.critical("PARALLEL_API_KEY environment variable is not set.")
        sys.exit(1)

    # 3. Initialize Client
    client = Parallel(api_key=api_key)

    # 4. Define API Parameters
    # Verbose flag (-v) turns ON full_content.
    # Default is Excerpts only (full_content=False).
    params = {
        "urls": urls,
        "full_content": args.verbose,
        "excerpts": not args.verbose,  # If verbose is on, we usually don't need excerpts
    }

    # Add objective if provided
    if args.prompt:
        params["objective"] = args.prompt

    logger.info(f"Sending request to Parallel API for {len(urls)} URLs...")
    logger.info(f"Mode: {'Full Content' if args.verbose else 'Excerpts'}")

    # 5. Execute Request
    try:
        response = client.beta.extract(**params)
    except Exception as e:
        logger.critical(f"API Request Failed: {e}")
        sys.exit(1)

    # 6. Save Raw Dump (Safety Net)
    OUTPUT_BASE_DIR.mkdir(parents=True, exist_ok=True)
    dump_path = OUTPUT_BASE_DIR / RAW_DUMP_FILE

    # Handle response conversion to dict
    try:
        if hasattr(response, "model_dump"):
            data_dict = response.model_dump()
        elif hasattr(response, "dict"):
            data_dict = response.dict()
        else:
            # Fallback manual dict creation
            data_dict = {"results": [r.__dict__ for r in response.results]}

        with open(dump_path, "w", encoding="utf-8") as f:
            json.dump(data_dict, f, indent=2, default=str)
        logger.info(f"Raw API response saved to {dump_path}")

    except Exception as e:
        logger.warning(f"Could not save raw dump: {e}")

    # 7. Process Results -> Markdown
    results = (
        data_dict.get("results", [])
        if isinstance(data_dict, dict)
        else getattr(response, "results", [])
    )

    for item in results:
        # If item is a dict (from model_dump), wrap it in a simple object for dot notation
        # or just access via dict. Here we ensure we can handle both.
        if isinstance(item, dict):

            class ItemWrapper:
                def __init__(self, d):
                    self.__dict__ = d

            item = ItemWrapper(item)

        save_markdown(item, OUTPUT_BASE_DIR, args.verbose, args.prompt)

    logger.info("Processing complete.")


if __name__ == "__main__":
    main()
