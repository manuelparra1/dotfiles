#!/bin/bash

nmcli -t -f SSID,CHAN,SIGNAL,SECURITY device wifi list | \
grep '^[A-Za-z]' | \
awk -F: 'BEGIN { print "[" }
    NR > 1 { printf(",") }
    {
        # Escape double quotes in SSID and SECURITY
        gsub(/"/, "\\\"", $1);
        gsub(/"/, "\\\"", $4);
        printf("{\"ssid\":\"%s\",\"chan\":\"%s\",\"signal\":%d,\"security\":\"%s\",\"active\":false}", $1, $2, $3, $4)
    }
END { print "]" }'
