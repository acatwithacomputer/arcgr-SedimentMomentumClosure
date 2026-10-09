#!/bin/bash

#SBATCH --job-name=lowReSimple
#SBATCH -N 2
#SBATCH -p debug_queue
#SBATCH --ntasks-per-node=44
#SBATCH --time=4:00:00

./Allrun
