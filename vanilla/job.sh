#!/bin/bash
#SBATCH -J CHILE2010_VANILLA # job name
#SBATCH -o CHILE2010_OUT_%j # output file name (%j expands to jobID)
# #SBATCH -e CHILE2010_ERR_%j # error file name (%j expands to jobID)
#SBATCH -N 1                # total number of nodes requested (16 cores/node)
#SBATCH -n 1                # 1 task
#SBATCH -p development      # queue (partition) -- normal, development, etc.
#SBATCH -t 00:30:00         # run time (hh:mm:ss)
#SBATCH --mail-user=andreemalcher@gmail.com
#SBATCH --mail-type=fail   # email me when the job fails

make topo
make data
make output
