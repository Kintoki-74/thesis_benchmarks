#!/bin/bash
#SBATCH -J WET_AVX_500        # job name
#SBATCH -o WET_AVX_500_OUT_%j # output file name (%j expands to jobID)
#SBATCH -e WET_AVX_500_ERR_%j # error file name (%j expands to jobID)
#SBATCH -N 1                # total number of nodes requested (16 cores/node)
#SBATCH -n 1                # 1 task
#SBATCH -p serial # queue (partition) -- normal, development, etc.
#SBATCH -t 00:30:00         # run time (hh:mm:ss)
#SBATCH --mail-user=andreemalcher@gmail.com
#SBATCH --mail-type=begin   # email me when the job starts
#SBATCH --mail-type=end     # email me when the job finishes

make topo
make data
make output
