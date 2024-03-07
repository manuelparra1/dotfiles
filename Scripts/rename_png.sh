#!/bin/bash

# Get a list of PNG files in the directory and sort them
png_files=$(ls -1 *.png | sort)

# Initialize a counter
counter=1

# Iterate over the sorted files and rename them
for file in $png_files; do
    # Pad the counter with zeros to make it three digits
    counter_padded=$(printf "%03d" $counter)
    # Construct the new file name
    new_name="Question_${counter_padded}.png"
    # Rename the file
    mv "$file" "$new_name"
    echo "Renamed $file to $new_name"
    # Increment the counter
    ((counter++))
done
