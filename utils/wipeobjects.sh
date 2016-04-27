#!/bin/sh

DIRS=("${CLAW}" "${CLAWUTILS}/..")

for d in "${DIRS[@]}"; do
    echo "Wiping object and module files in directory:" $d
    #rm -f `find ${d} -regex '.*\.\(mod\|o\)$'`
    rm -f `find ${d} -regex '.*\.\(mod\\)$'`
done
