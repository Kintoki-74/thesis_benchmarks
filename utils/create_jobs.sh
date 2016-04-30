#!/bin/bash

NAME="chile_soa_papi_precise_inlinerp"
#NAME="chile_vanilla_fp_precise_max1d60"
COMPILERS=("ifort")

FLAGS=("-O2 -ipo -xavx -qopenmp-simd -align array32byte -fp-model=precise -DUSEPAPI") 
RESOLUTIONS=("900" "700" "500" "300" "100" "050") # Check that amr_module.f90:max1d is set properly 
#RESOLUTIONS=("30")
amrlevels=1

# GCC: -fno-finite-math-only -fmath-errno -ftrapping-math -fsignaling-nans -fno-rounding-math"
function usage
{
    echo "Usage: ./create_jobs [all|make|runs]"
    exit 0
}

function main
{
    basedir="$WORK/${PWD##*/}"
# TODO: Check if files exist: Makefile, setrun.py, job.sh and maketopo.py
    for compiler in "${COMPILERS[@]}";
    do
        for flags in "${FLAGS[@]}";
        do
            # Replace dashes by underscores and trim whitespaces for file names
            flagstring=`echo $flags | sed -r -e "s/ *-| /_/g" -e "s/=/_/g"`
            # Binary name containing compiler name and flags
            binname="xgeoclaw_${compiler}${flagstring}"
            # Create temporary directory, copy Makefile to it, sed executable name and flags and build binary
            tmpdir="${basedir}/_tmp_${compiler}${flagstring}"
            mkdir -p $tmpdir
            # We need to escape the directory string in order to use it with sed.
            here=$(echo "`pwd`" | sed -r -e 's/\//\\\//g')
            sed -r -e "s/^EXE.*/EXE = ${binname}/" \
                   -e "s/^FFLAGS.*/FFLAGS = ${flags}/" \
                   -e "s/(^CLAW_PKG.*$)/FC=${compiler}\t# Set by script, do not change\n\1/" \
                   -e "s/^HERE.*/HERE = ${here}/" \
                Makefile > $tmpdir/Makefile

            # If "all" or "compile" was selected, compile if no binary exists
            if [[ $1 == "all" || $1 == "make" ]]; then
                cd $tmpdir
                yesno="y"
                if [[ -f $binname ]]; then
                    echo "Directory $tmpdir already exists. Rebuild?"
                    read yesno
                    if [[ $yesno != "y" ]]; then
                        echo "Skipping..."
                        skip=true
                    fi
                fi

                if [[ $yesno == "y" ]]; then
                    echo "=== BUILDING NEW EXECUTABLE! THIS MIGHT TAKE SOME TIME ==="
                    echo -n "Will build $binname with flags \"$flags\" in "
                    for i in {1..1} #{3..1}
                    do
                        echo -n "$i... "
                        sleep 1
                    done
                    echo
                    echo "Building $binname..."
                    if make new > /dev/null
                    then
                        echo "Done!"
                    else
                        echo "Build error. Aborting."
                        exit
                    fi
                fi
                cd -
            fi 

            # Skip runs when only "compile" was selected
            if [[ $1 == "make" ]]; then
                continue
            fi
            # Runs --- Run for different resolutions
            for res in "${RESOLUTIONS[@]}";
            do
                dirname="${basedir}/run_${NAME}_${res}_${flagstring}"
                mkdir -p $dirname
                cp $tmpdir/* $dirname # Copy modified Makefile and corresponding binary
                cp maketopo.py $dirname # This is needed to create topography files
                # Change grid resolution in setrun.py and set AMR levels to 1
                sed -r -e "s/( *clawdata\.num_cells\[[01]\] *= *).*$/\1${res}/g" \
                       -e "s/( *amrdata.amr_levels_max *= *).*$/\1${amrlevels}/g" \
                    setrun.py > $dirname/setrun.py

                # Change job file's job name and error and output file names, respectively.
                jobname="${res}_${NAME}_${flagstring}"
                sed -r -e "s/(^#SBATCH +-J +)(\w*)(#*.*$)/\1${jobname}\3/" \
                       -e "s/(^#SBATCH +-o +)(\w*)(#*.*$)/\1${jobname^^}_OUT\3/" \
                       -e "s/(^#SBATCH +-e +)(\w*)(#*.*$)/\1${jobname^^}_ERR\3/" \
                    job.sh > $dirname/job.sh

                # SLURM Job submit
                echo -n "Submit job ${jobname}? 'y' for yes, other key to skip: "
                read yesno
                if [[ $yesno == "y" ]]; then
                    echo "SUBMITTING JOB \"${jobname}\"..."
                    # Submit job, hide stdout
                    cd $dirname
                    sbatch job.sh 1> SBATCH_${jobname} & 
                    cd -
                    mkdir -p runs
                    cd runs
                    ln -i -s $dirname
                    cd -
                else
                    echo "Skipping..."
                fi 
            done
        done
    done
}

if [ $# -ne 1 ] || [ "$1" != "make" ] && \
    [ "$1" != "runs" ] && [ "$1" != "all" ]; then
    usage
fi
main $1
