#!/bin/bash

replace_line() { printf "\r\e[K$1 " "${@:2}"; }
wait_enter() { read -s -n 1 key; }

now() { echo $( date +%s.%N ); }

time_format() {
    a=$( printf "%.2f " "$1" )
    m=$( printf "%d" "$( echo "$a" / 60 | bc )" )
    if [ "$m" -ne "0" ]; then
        s=$( printf "%05.2f" "$( echo "$a" % 60 | bc )" )
        replace_line "%s:%s " "$m" "$s"
    else
        s=$( printf "%.2f" "$( echo "$a" % 60 | bc )" )
        replace_line "%s " "$s"
    fi
}

eechoo() {
    while sleep 0.05; do
        d=$( echo "$(now) - $1" | bc )
        replace_line "%s " "$( time_format "$d" )"
    done
}

t=$( now )
eechoo "$t" &
echo "Press Enter to pause/resume, 'q' to quit."
while wait_enter; do
    if [ "$key" = "q" ]; then
        kill %%
        echo "Quitting..."
        exit 0
    fi
    kill %%
    d=$( echo "$(now) - $t" | bc )
    replace_line "%s PAUSED " "$( time_format "$d" )"
    wait_enter
    d2=$( echo "$(now) - $t" | bc )
    t=$( echo "$t + $d2 - $d" | bc )
    eechoo "$t" &
done 2>/dev/null
