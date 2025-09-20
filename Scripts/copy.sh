#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 source destination"
  exit 1
fi

src="$1"
dest="$2"

rsync -avh --progress --partial --info=progress2 "$src" "$dest"
