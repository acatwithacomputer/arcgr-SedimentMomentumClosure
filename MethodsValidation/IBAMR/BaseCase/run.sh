#!/bin/bash

#SBATCH --job-name=ib
#SBATCH -p debug_queue
#SBATCH -N 2
#SBATCH --ntasks-per-node=44
#SBATCH --time=4:00:00

module load openmpi_4.0.1/gcc_11.2.0
module load python/3.9.6
source $HOME/autoibamr/configuration/enable.sh

mpirun -np 88 ./main2d input2d