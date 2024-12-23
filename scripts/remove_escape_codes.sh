#/bin/bash
# removes the ANSI escape codes from the file passed in as arg
sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" $1
