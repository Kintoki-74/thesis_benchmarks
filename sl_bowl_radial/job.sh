#!/bin/bash
#SBATCH -J DRY_VAN_O2        # job name
#SBATCH -o DRY_VAN_O2_OUT_%j # output file name (%j expands to jobID)
#SBATCH -e DRY_VAN_O2_ERR_%j # error file name (%j expands to jobID)
#SBATCH -N 1                # total number of nodes requested (16 cores/node)
#SBATCH -n 1                # 1 task
#SBATCH -p development # queue (partition) -- normal, development, etc.
#SBATCH -t 00:10:00         # run time (hh:mm:ss)
#SBATCH --mail-user=am4491@columbia.edu
#SBATCH --mail-type=begin   # email me when the job starts
#SBATCH --mail-type=end     # email me when the job finishes

make topo
make data
make output
