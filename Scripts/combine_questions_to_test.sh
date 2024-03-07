#!/bin/bash

# Get the list of question files and count them (case-insensitive)
shopt -s nocaseglob
question_files=(*question*.txt)
shopt -u nocaseglob
num_files=${#question_files[@]}

# Define the output file
output_file="Test_1.txt"

# Iterate through each question file
for ((i=0; i<num_files; i++)); do
    input_file="${question_files[i]}"
    
    # Append the question number to the output file
    echo "Question $((i+1)):" >> "$output_file"
    
    # Append the content of the question file to the output file
    cat "$input_file" >> "$output_file"
    
    # Add a newline to separate questions
    echo >> "$output_file"
done
