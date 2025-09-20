#!/usr/bin/env python3

import argparse
import os
from datetime import datetime


def find_files_in_date_range_robust(start_date_str, end_date_str):
    """
    Recursively and robustly finds all markdown files in the current directory
    and its subdirectories that were created within the specified date range.

    This version is designed to handle common errors like invalid YAML and
    non-text files.

    Args:
        start_date_str (str): The start date of the range in YYYY-MM-DD format.
        end_date_str (str): The end date of the range in YYYY-MM-DD format.
    """
    try:
        start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
        end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date()
    except ValueError:
        print("Error: Please use the YYYY-MM-DD format for dates.")
        return

    print(
        f"Recursively searching for notes created between {start_date_str} and {end_date_str}...\n"
    )

    found_files = []
    current_directory = os.getcwd()

    for dirpath, _, filenames in os.walk(current_directory):
        for filename in filenames:
            if filename.endswith(".md"):
                filepath = os.path.join(dirpath, filename)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        # Ensure the file starts with a YAML block
                        if f.readline().strip() != "---":
                            continue

                        created_timestamp = None
                        # Read through the frontmatter line by line
                        for line in f:
                            # Stop if we've reached the end of the frontmatter
                            if line.strip() == "---":
                                break

                            # Look for the 'created' key
                            if line.strip().startswith("created:"):
                                # Split only once to be safe
                                parts = line.strip().split(":", 1)
                                if len(parts) == 2:
                                    created_timestamp = parts[1].strip()
                                    # We found what we need, so we can stop reading the frontmatter
                                    break

                        if created_timestamp:
                            try:
                                created_date = datetime.fromisoformat(
                                    created_timestamp
                                ).date()
                                if start_date <= created_date <= end_date:
                                    relative_path = os.path.relpath(
                                        filepath, current_directory
                                    )
                                    found_files.append(relative_path)
                            except (ValueError, TypeError):
                                print(
                                    f"Warning: Could not parse timestamp '{created_timestamp}' in file: {filepath}"
                                )

                except UnicodeDecodeError:
                    print(
                        f"Warning: Could not read file (likely not a text file): {filepath}"
                    )
                except Exception as e:
                    print(
                        f"Error: An unexpected error occurred with file: {filepath}. Details: {e}"
                    )

    print("-" * 20)  # Separator for clarity
    if found_files:
        print("\nFound the following files:")
        # Sort the files alphabetically for consistent output
        for file in sorted(found_files):
            # MODIFICATION: Print only the relative path
            print(file)
    else:
        print("\nNo files found in the specified date range.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Search for Obsidian notes created within a specific date range."
    )
    parser.add_argument("start_date", help="The start date of the range (YYYY-MM-DD).")
    parser.add_argument("end_date", help="The end date of the range (YYYY-MM-DD).")
    args = parser.parse_args()

    find_files_in_date_range_robust(args.start_date, args.end_date)
