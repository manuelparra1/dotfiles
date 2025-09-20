#!/bin/bash
# this script finds all `.docx` files in the current directory 
# and converts them to `.md` files using pandoc
# ouput file name is orginal file name + `.md`
#
 
for file in *.docx; do
  pandoc "$file" -t markdown -o "${file%.docx}.md"
done
