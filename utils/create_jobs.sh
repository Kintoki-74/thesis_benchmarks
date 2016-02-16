#!/bin/bash

NAME="planewave_trans=1_order=1"
COMPILERS=("ifort")
#COMPILERS=("gfortran")

#FLAGS=("-O2 -pg" "-xavx" "-O3" "-ipo" "-O2 -pg -fp-model=precise" "-ipo -fp-model=precise")
FLAGS=("-O2") # -fno-finite-math-only -fmath-errno -ftrapping-math -fsignaling-nans -fno-rounding-math")
#RESOLUTIONS=("120" "360" "400") # Check that amr_module.f90:max1d is set properly 
# TODO: TRESOLUTIONS=(...)

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
            tmpdir="${basedir}/_tmp_${NAME}_${compiler}${flagstring}"
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
                if [[ ! -f $binname ]]
                then
                    echo "=== BUILDING NEW EXECUTABLE! THIS MIGHT TAKE SOME TIME ==="
                    echo -n "Will build $binname with flags \"$flags\" in "
                    for i in {1..1} #{3..1}
                    do
                        echo -n "$i... "
                        sleep 1
                    done
                    echo
                    echo "Building $binname..."
                    make new > /dev/null
                    echo "Done!"
                else
                    echo "Directory $tmpdir already exists. skipping..."
                fi
                cd -
            fi 
            # Skip runs when only "compile" was selected
            if [[ $1 == "make" ]]; then
                continue
            fi
            # Runs
#            for res in "${RESOLUTIONS[@]}";
#            do
                dirname="${basedir}/run_${NAME}_${compiler}${flagstring}"
                mkdir -p $dirname
                cp $tmpdir/* $dirname # Copy modified Makefile and corresponding binary
                cp maketopo.py $dirname # This is needed to create topography files
#                # Change grid resolution in setrun.py and set AMR levels to 1
#                sed -r -e "s/( *clawdata\.num_cells\[[01]\] *= *).*$/\1${res}/g" \
#                       -e "s/( *amrdata.amr_levels_max *= *).*$/\11/g" \
#                    setrun.py > $dirname/setrun.py
                cp setrun.py $dirname/setrun.py
                # Change job file's job name and error and output file names, respectively.
                jobname="${NAME}_${compiler}${flagstring}"
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
                    ln -i -s $dirname
                else
                    echo "Skipping..."
                fi 
#            done
        done
    done
}

if [ $# -ne 1 ] || [ "$1" != "make" ] && \
    [ "$1" != "runs" ] && [ "$1" != "all" ]; then
    usage
fi
main $1
