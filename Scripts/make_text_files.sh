#!/bin/bash

for file in *.mp4; do
  filename="${file%.mp4}.txt"
  touch "$filename"
done
