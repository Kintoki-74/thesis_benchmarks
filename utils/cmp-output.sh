#!/bin/bash
if [ $# -ne 3 ]; then
    echo "Usage: ./create_jobs.sh <dir1> <dir2> <numfiles>"
    exit
fi
# Output should be empty (i.e. vector version and original version should not differ)
for i in `(seq -f "%04g" 00 $3)`; do
    diff -q $1/fort.q$i $2/fort.q$i;
done;
