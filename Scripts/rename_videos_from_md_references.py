#!/home/dusts/.miniconda3/envs/scraping/bin/python3

import os
import re

from natsort import natsorted


def get_new_filenames_from_markdown(md_file_path):
    """
    Reads a markdown file and extracts all .mp4 filenames from
    <source src="..."> tags, in the order they appear.
    """
    try:
        with open(md_file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # This regex finds all strings inside src="..." that end with .mp4
        # It's robust enough to handle various HTML formatting.
        regex = r'<source src="([^"]+\.mp4)"'

        # findall returns a list of all captured groups, in order.
        new_names = re.findall(regex, content)

        if not new_names:
            print(f"  [!] Warning: No .mp4 filenames found in {md_file_path}")

        return new_names
    except FileNotFoundError:
        print(f"  [!] Error: Markdown file not found at {md_file_path}")
        return []
    except Exception as e:
        print(f"  [!] An error occurred while reading {md_file_path}: {e}")
        return []


def rename_videos_in_directory(dir_path):
    """
    Renames all .mp4 files in a single directory based on names
    found in the corresponding .md file.
    """
    print(f"\nProcessing directory: {dir_path}")

    # 1. Find the markdown file in the current directory
    # It should have the same name as the directory itself.
    dir_name = os.path.basename(dir_path)
    md_filename = f"{dir_name}.md"
    md_file_path = os.path.join(dir_path, md_filename)

    if not os.path.exists(md_file_path):
        print(f"  [!] Skipping: No markdown file named '{md_filename}' found.")
        return

    # 2. Extract the ordered list of NEW filenames from the markdown file
    new_filenames = get_new_filenames_from_markdown(md_file_path)
    if not new_filenames:
        print(f"  [!] Skipping: Could not extract new filenames.")
        return

    # 3. Get a sorted list of all OLD .mp4 files in the directory
    try:
        # Use a generator expression for efficiency
        old_filenames_unsorted = (f for f in os.listdir(dir_path) if f.endswith(".mp4"))

        # Use natsorted to handle numbers in filenames correctly
        # (e.g., 'file-2.mp4' comes before 'file-10.mp4')
        old_filenames_sorted = natsorted(old_filenames_unsorted)

    except Exception as e:
        print(f"  [!] Error listing or sorting video files in {dir_path}: {e}")
        return

    # 4. Safety Check: Ensure the number of videos matches the number of new names
    if len(old_filenames_sorted) != len(new_filenames):
        print(f"  [!] Mismatch Error in '{dir_name}':")
        print(
            f"      Found {len(old_filenames_sorted)} .mp4 files but extracted {len(new_filenames)} names from markdown."
        )
        print(
            f"      Please check the directory and the markdown file for consistency."
        )
        # Uncomment the lines below if you want to see the lists for debugging
        # print("      Files found:", old_filenames_sorted)
        # print("      Names extracted:", new_filenames)
        return

    # 5. Rename the files
    print(f"  [*] Found {len(old_filenames_sorted)} videos to rename.")
    for old_name, new_name in zip(old_filenames_sorted, new_filenames):
        old_path = os.path.join(dir_path, old_name)
        new_path = os.path.join(dir_path, new_name)

        # Prevent renaming a file to itself
        if old_path == new_path:
            print(f"  - Skipping (already named correctly): '{new_name}'")
            continue

        try:
            os.rename(old_path, new_path)
            print(f"  - Renamed: '{old_name}' -> '{new_name}'")
        except OSError as e:
            print(f"  [!] Error renaming file '{old_name}': {e}")


def main():
    """
    Main function to walk through the root path and process each
    relevant subdirectory.
    """
    # --- IMPORTANT ---
    # Set this to the path of the folder containing all your '019 - ...' directories.
    # Use '.' if the script is in the same folder as those directories.
    ROOT_PATH = "."

    abs_root_path = os.path.abspath(ROOT_PATH)
    print(f"Starting video rename process in: {abs_root_path}")

    # Get all items in the root directory
    for item_name in os.listdir(abs_root_path):
        item_path = os.path.join(abs_root_path, item_name)

        # Process only directories that start with a number, indicating a course section
        if os.path.isdir(item_path) and item_name[:1].isdigit():
            rename_videos_in_directory(item_path)

    print("\nProcess finished.")


if __name__ == "__main__":
    # To run this script, you may need to install the 'natsort' library first:
    # pip install natsort
    try:
        main()
    except NameError:
        print("\n[ERROR] The 'natsort' library is required.")
        print("Please install it by running: pip install natsort")
