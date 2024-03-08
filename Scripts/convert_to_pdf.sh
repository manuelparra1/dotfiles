#!/bin/bash

pandoc --pdf-engine=xelatex -f markdown -t pdf --template="orangeheart" "Test_04_Attempt_02.md" -o "Test_04_Attempt_02.pdf"
