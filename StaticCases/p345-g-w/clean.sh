#!/bin/sh               
         
#SBATCH --job-name=clean
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 2:00:00
#SBATCH -A nca125

for p in $(seq 0 1279)
do
    echo Cleaning proc ${p} directory
    rm -rf processor${p}
    rm data/*-${p}.txt
done
