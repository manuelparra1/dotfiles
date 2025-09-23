#!/usr/bin/env bash

for f in *.sh; do
  [ -f "$f" ] && sed -i '1s@^#!/bin/env bash$@#!/usr/bin/env bash@' "$f"
done
