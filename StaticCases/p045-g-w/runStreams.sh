#!/bin/bash
#SBATCH --job-name=s-045w
#SBATCH --partition=large-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 1:00:00
#SBATCH --mem=300G
#SBATCH -A nca125

useModule="false"

echo "Loading Modules"
module purge
module load cpu/0.17.3b
module load aocc/3.2.0/
module load slurm
module load openmpi/4.1.3/

useModule=False

if $useModule
   then
       echo "Loading OpenFOAM 12 module and sourcing bashrc"
       module load openfoam/12
       source /nas/sycamore/apps/openfoam/12/OpenFOAM-12/etc/bashrc
   else
       echo "Sourcing OpenFOAM 10"               
       source /home/bshepherd/OpenFOAM/OpenFOAM-10/etc/bashrc
fi

postProcess -func "streamlinesPatch(patch=x0,nPoints=10,fields=(U))"
