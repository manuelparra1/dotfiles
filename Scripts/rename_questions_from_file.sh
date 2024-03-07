#!/bin/bash

# Initial gather of files to process.
files_to_process=(Question_*.txt)
processed_files=()
skipped_files=()

# Function to attempt renaming files.
rename_files() {
    local current_files=("$@")
    local filename question_number new_filename

    for filename in "${current_files[@]}"; do
        if [ -f "$filename" ]; then
            # Extract the question number from the file's first line.
            question_number=$(head -n 1 "$filename" | grep -o '[0-9]\+')

            if [[ ! -z $question_number ]]; then
                new_filename="Question_$(printf "%03d" $question_number).txt"

                # Prevent overwriting files.
                if [[ -e "$new_filename" && "$new_filename" != "$filename" ]]; then
                    echo "Conflict detected for $filename. Will retry later."
                    skipped_files+=("$filename")
                else
                    mv "$filename" "$new_filename"
                    echo "Renamed $filename to $new_filename."
                    processed_files+=("$filename")
                fi
            else
                echo "Skipping $filename, no question number found."
                processed_files+=("$filename") # Technically processed, as it can't be renamed.
            fi
        else
            echo "Skipping $filename, file not found."
            processed_files+=("$filename")
        fi
    done
}

# First attempt to rename all files.
rename_files "${files_to_process[@]}"

# Attempt to process skipped files after the first attempt.
if [[ ${#skipped_files[@]} -gt 0 ]]; then
    echo "Attempting to process previously skipped files..."
    # Re-initialize files_to_process with those skipped earlier and clear skipped_files for a fresh start.
    files_to_process=("${skipped_files[@]}")
        skipped_files=() # Clear the skipped files as we're preparing for a retry
        rename_files "${files_to_process[@]}"
    fi

# Final report
if [[ ${#skipped_files[@]} -gt 0 ]]; then
    echo "Final attempt completed. The following files remain unresolved due to conflicts:"
    printf '%s\n' "${skipped_files[@]}"
else
    echo "All files have been successfully processed and renamed, if necessary."
fi
