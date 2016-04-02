#!/bin/bash
rm src/*.{o,mod}
rm `find $CLAW -name "*.o"`
rm `find $CLAW -name "*.mod"`
module load gcc/4.9.1
export MKLROOT=/opt/apps/intel/15/composer_xe_2015.2.164/mkl
export FC=gfortran
