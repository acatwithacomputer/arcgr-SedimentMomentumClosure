#!/bin/sh               
         
#SBATCH --job-name=of2txt
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH -t 1:00:00
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

dirs_=( p025 p045 p045-w p060 
        p125 p125-cv p125nm-w p125-w 
        p145 p145-w p160 
        p225 p225-w p260
        p245 p245-cv p245cv-w p245-w
        p325-15 p345-cv p345-w p360)

if ${alreadyDone}
then
  dirs_=( p045 p045-w p060 
          p125-cv p125nm-w p125-w 
          p145-w p160 p225-w p260
          p245cv-w p245-w p360)
  let nd=3+3+4+3-1
else
  dirs_=( p025 p045 p045-w p060 
        p125 p125-cv p125nm-w p125-w 
        p145 p145-w p160 
        p225 p225-w p260
        p245 p245-cv p245cv-w p245-w
        p325-15 p345-cv p345-w p360)
  let nd=6-1
fi


python of2txt.py
