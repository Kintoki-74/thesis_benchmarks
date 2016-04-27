#!/bin/bash
#SBATCH -J CHILE_SOA        # job name
#SBATCH -o CHILE_SOA_OUT_%j # output file name (%j expands to jobID)
#SBATCH -e CHILE_SOA_ERR_%j # error file name (%j expands to jobID)
#SBATCH -N 1                # total number of nodes requested (16 cores/node)
#SBATCH -n 1                # 1 task
#SBATCH -p normal           # queue (partition) -- normal, development, etc.
#SBATCH -t 05:00:00         # run time (hh:mm:ss)
#SBATCH --mail-user=andreemalcher@gmail.com
#SBATCH --mail-type=fail    # email me when the job fails

make topo
make data
make output
