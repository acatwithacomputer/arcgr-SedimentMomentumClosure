#!/bin/bash
#SBATCH --job-name=h-245w
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 18:00:00
#SBATCH -A nca125

echo "Loading Modules"
module purge
module load cpu/0.15.4
module load gpu/0.15.4
module load gcc/10.2.0
module load intel/19.1.1.217

python makeHistExpanse.py
