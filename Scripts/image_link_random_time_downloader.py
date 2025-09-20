#!/usr/bin/env python3
import argparse, os, random, time, urllib.parse, requests


def main(file_path):
    os.makedirs("images", exist_ok=True)
    with open(file_path) as f:
        links = [line.strip() for line in f if line.strip()]
    for link in links:
        try:
            resp = requests.get(link, timeout=10)
            resp.raise_for_status()
            parsed = urllib.parse.urlparse(link)
            fname = os.path.basename(parsed.path)
            if not fname:
                fname = "downloaded_image"
            out_path = os.path.join("images", fname)
            with open(out_path, "wb") as out:
                out.write(resp.content)
            print(f"Downloaded {link} → {out_path}")
        except Exception as e:
            print(f"Failed {link}: {e}")
        time.sleep(random.uniform(0.25, 3.0))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download images from a list of URLs.")
    parser.add_argument("file", help="Path to text file containing URLs")
    args = parser.parse_args()
    main(args.file)
