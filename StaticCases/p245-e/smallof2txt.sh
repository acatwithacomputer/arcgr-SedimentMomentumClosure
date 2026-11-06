#!/bin/sh               
         
#SBATCH --job-name=of2txt
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -t 0:20:00
#SBATCH -A nca125

alreadyDone="true"
logdir=logs
#mkdir ${logdir}
useModule="false"

echo "Loading Modules"
module purge
module load cpu/0.15.4
module load gpu/0.15.4
module load gcc/10.2.0
module load intel/19.1.1.217
       
if $useModule
   then
       echo "Loading OpenFOAM 12 module and sourcing bashrc"
       module load openfoam/12
       source /nas/sycamore/apps/openfoam/12/OpenFOAM-12/etc/bashrc
   else
       echo "Sourcing OpenFOAM 10"               
       source /home/bshepherd/OpenFOAM/OpenFOAM-10/etc/bashrc
fi

mv processor604 processor0
mv processor605 processor1
mv processor606 processor2
mv processor607 processor3
mv processor608 processor4
mv processor609 processor5

python of2txt.py
