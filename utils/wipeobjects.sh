#!/bin/sh

DIRS=("${CLAW}" "${CLAWUTILS}/..")

for d in "${DIRS[@]}"; do
    echo "Wiping object and module files in directory:" $d
    rm -f `find ${d} -name "*.mod"`
    rm -f `find ${d} -name "*.o"`
done
