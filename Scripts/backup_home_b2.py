#!/usr/bin/env python3

import os
import time
import json
from pathlib import Path
from datetime import datetime

import b2sdk.v2 as b2

from dotenv import load_dotenv

# Configuration: update these as needed.
DIRECTORIES_TO_BACKUP = [
    str(Path.home() / "Documents"),
    str(Path.home() / "Pictures"),
    # add more directories as desired
]
BUCKET_NAME = "my-backup-bucket"  # change to your B2 bucket name
STATE_FILE = Path("backup_state.json")
SCAN_INTERVAL_SECONDS = 600  # check every 10 minutes

def load_state():
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading state: {e}")
    return {}  # file path -> { "mtime": <float>, "size": <int> }

def save_state(state):
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(state, f)
    except Exception as e:
        print(f"Error saving state: {e}")

def get_all_files(directories):
    all_files = []
    for dir_path in directories:
        p = Path(dir_path)
        if p.exists() and p.is_dir():
            # recursively list all files
            for file in p.rglob("*"):
                if file.is_file():
                    all_files.append(file)
        else:
            print(f"Warning: {dir_path} is not a valid directory.")
    return all_files

def initialize_b2():
    load_dotenv()  # load from .env file if present
    key_id = os.getenv("B2_KEY_ID")
    application_key = os.getenv("B2_APPLICATION_KEY")
    if not key_id or not application_key:
        raise ValueError("B2_KEY_ID and B2_APPLICATION_KEY must be set in the environment.")
    info = b2.InMemoryAccountInfo()
    b2_api = b2.B2Api(info)
    b2_api.authorize_account("production", key_id, application_key)
    bucket = b2_api.get_bucket_by_name(BUCKET_NAME)
    return bucket

def file_has_changed(file_path: Path, state_entry: dict) -> bool:
    try:
        stat = file_path.stat()
        # Compare modification time and size
        return (stat.st_mtime != state_entry.get("mtime") or stat.st_size != state_entry.get("size"))
    except Exception as e:
        print(f"Could not stat {file_path}: {e}")
        return False

def upload_file(bucket, file_path: Path):
    try:
        # Use relative path (or file name) as destination name.
        dest_name = str(file_path.relative_to(Path.home()))
        print(f"Uploading {file_path} as {dest_name}...")
        result = bucket.upload_local_file(
            local_file=str(file_path.resolve()),
            file_name=dest_name,
            file_infos={}  # add extra metadata if needed
        )
        download_url = bucket.get_download_url_for_fileid(result.id_)
        print(f"Uploaded successfully. File URL: {download_url}")
        return result
    except Exception as e:
        print(f"Failed to upload {file_path}: {e}")
        return None

def main():
    print("Initializing B2 connection...")
    try:
        bucket = initialize_b2()
    except Exception as e:
        print(f"Error initializing B2: {e}")
        return

    state = load_state()

    while True:
        print(f"Scanning for changes at {datetime.now().isoformat()}...")
        all_files = get_all_files(DIRECTORIES_TO_BACKUP)
        for file_path in all_files:
            file_str = str(file_path.resolve())
            stat = file_path.stat()
            # If file not in state or has changed, upload it
            if file_str not in state or file_has_changed(file_path, state[file_str]):
                result = upload_file(bucket, file_path)
                if result is not None:
                    # Update state with new mtime and size
                    state[file_str] = {"mtime": stat.st_mtime, "size": stat.st_size}
        # Save the state to disk after each scan
        save_state(state)
        print(f"Scan complete. Sleeping for {SCAN_INTERVAL_SECONDS} seconds...\n")
        time.sleep(SCAN_INTERVAL_SECONDS)

if __name__ == "__main__":
    main()
