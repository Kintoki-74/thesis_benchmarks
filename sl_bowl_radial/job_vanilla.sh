#!/bin/bash
#SBATCH -J WET_VANILLA        # job name
#SBATCH -o WET_VANILLA_OUT_%j # output file name (%j expands to jobID)
#SBATCH -e WET_VANILLA_ERR_%j # error file name (%j expands to jobID)
#SBATCH -N 1                # total number of nodes requested (16 cores/node)
#SBATCH -n 1                # 1 task
#SBATCH -p serial           # queue (partition) -- serial,normal, development, etc.
#SBATCH -t 00:30:00         # run time (hh:mm:ss)
#SBATCH --mail-user=andreemalcher@gmail.com
#SBATCH --mail-type=begin   # email me when the job starts
#SBATCH --mail-type=end     # email me when the job finishes

make topo
make data
make output
#gprof ./xgeoclaw _output/gmon.out > WET_VANILLA_GPROF
