#!/usr/bin/env python3

import os
import sys


def shorten_path(path):
    parts = path.split(os.sep)
    parts = [p for p in parts if p]  # Remove empty parts
    if len(parts) > 2:
        return f"...{os.sep}{os.sep.join(parts[-2:])}"
    return os.sep.join(parts)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(shorten_path(sys.argv[1]))
    else:
        print("No path provided")
