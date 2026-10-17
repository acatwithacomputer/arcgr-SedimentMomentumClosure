#!/bin/bash

#SBATCH --job-name=ibamrPost
#SBATCH -N 2
#SBATCH -p debug_queue
#SBATCH --ntasks-per-node=44
#SBATCH --time=04:00:00

module load python/3.9.6
python testvtkparallel.py

# matlab processing
#module load matlab/2019a
#matlab -nodesktop -nosplash -singleCompThread -r integrate -logfile integrate.out