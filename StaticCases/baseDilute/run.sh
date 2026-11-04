#!/bin/bash

#SBATCH --job-name=dilute
#SBATCH -N 4
#SBATCH -p 528_queue
#SBATCH --ntasks-per-node=44
#SBATCH --time=4:00:00

echo "Sourcing OF-10 bashrc"
source ~/OpenFOAM/OpenFOAM-10/etc/bashrc

./Allrun
