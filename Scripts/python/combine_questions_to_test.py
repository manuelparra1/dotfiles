#!/usr/bin/env python3
import os


def add_question_number(input, output, question_number):
    with open(input, "r", encoding="utf-8") as f:
        content = f.read()

    with open(output, "a", encoding="utf-8") as f:
        f.write(f"Question {question_number}:\n")
        f.write(content)
        f.write("\n\n")


# Define the output file name
output_file = "Test_1.txt"

# Get the list of question files in the directory ending with ".txt"
question_files = [
    file
    for file in os.listdir()
    if file.startswith("Question") and file.endswith(".txt")
]

# Iterate through each question file
for i, input_file in enumerate(question_files, start=1):
    add_question_number(input_file, output_file, i)
