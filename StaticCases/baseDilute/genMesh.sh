#!/bin/bash

#SBATCH --job-name=denseMesh
#SBATCH -N 1
#SBATCH -p debug_queue
#SBATCH --ntasks-per-node=1
#SBATCH --time=4:00:00

echo "Sourcing OF-10 bashrc"
source ~/OpenFOAM/OpenFOAM-10/etc/bashrc

blockMesh
snappyHexMesh -overwrite
