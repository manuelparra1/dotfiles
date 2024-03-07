#!/bin/bash

input_file="Guide.md"

find /usr/share/pandoc/data/templates -type f -name "*.tex" -print0 | while IFS= read -r -d '' template; do
  template_name="$(basename -- "$template")"
  template_name="${template_name%.tex}"
  pandoc --pdf-engine=xelatex -f markdown -t pdf --template="$template" "$input_file" -o "Guide_$template_name.pdf"
done
