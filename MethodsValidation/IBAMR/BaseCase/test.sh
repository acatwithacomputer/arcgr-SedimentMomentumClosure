#!/bin/bash

#SBATCH --job-name=ibamrTest
#SBATCH -N 2
#SBATCH -p debug_queue
#SBATCH --ntasks-per-node=44
#SBATCH --time=04:00:00

module load openmpi_4.0.1/gcc_11.2.0
module load python/3.9.6

source /nas/longleaf/home/breizh/autoibamr/configuration/enable.sh

mpirun -np 88 ./main3d input3d
