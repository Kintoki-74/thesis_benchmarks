#!/bin/bash

# Output should be empty (i.e. vector version and original version should not differ)
for i in `(seq -f "%04g" 00 18)`; do
    diff -q run_ifort_O2_pg/_output/fort.q$i run_ifort_O3/_output/fort.q$i;
done;
