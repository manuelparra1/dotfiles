#!/bin/sh

for file in *.jpg; do
    echo "Text extracted from $file:"
    tesseract "$file" stdout > "${file%.jpg}.txt"
done
