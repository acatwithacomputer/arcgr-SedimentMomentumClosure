#!/bin/bash

#SBATCH --job-name=ibMove2
#SBATCH -p 528_queue
#SBATCH -N 3
#SBATCH --ntasks-per-node=44
#SBATCH --time=2-00:00:00

#module load openmpi/4.0.5-gcc10.2.0 
#module load python/3.8.6
#source /jet/home/bshepher/autoibamr/configuration/enable.sh

module load openmpi_4.0.1/gcc_11.2.0
module load python/3.9.6
source $HOME/autoibamr/configuration/enable.sh

mpirun -np 132 ./main3d input3d -stokes_ksp_monitor_true_residual -stokes_ksp_error_if_not_converged
