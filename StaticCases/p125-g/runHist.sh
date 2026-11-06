#!/bin/bash
#SBATCH --job-name=txt-p125nm
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH -t 12:00:00
#SBATCH -A nca125

echo "Loading Modules"
module purge
module load cpu/0.15.4
module load gpu/0.15.4
module load gcc/10.2.0
module load intel/19.1.1.217

python of2txt.py
