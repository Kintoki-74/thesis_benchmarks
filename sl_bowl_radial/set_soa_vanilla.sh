#!/bin/bash

if [ $# -ne 1 ]; then
   echo "Usage: ./set_soa_vanilla.sh <soa|vanilla>"
   exit
fi

if [ $1 == "soa" ]; then
    echo "Pointing to SOA source and Makefile"
    ln -fs Makefile_soa Makefile
    ln -fs job_soa.sh job.sh
    rm src
    ln -s ../soa_step2/src src
elif [ $1 == "vanilla" ]; then
    echo "Pointing to VANILLA source and Makefile"
    ln -fs Makefile_vanilla Makefile
    ln -fs job_vanilla.sh job.sh
    rm src
    ln -s ../vanilla_papi/src src
else
    echo "Wrong parameter."
    exit
fi
