#!/bin/sh                                                                                        
#SBATCH --job-name=postPrep
#SBATCH --partition=compute
#SBATCH --nodes=10
#SBATCH --ntasks-per-node=128
#SBATCH -t 6:00:00
#SBATCH -A nca125

proc10="true"
logdir=logs
#mkdir ${logdir}
useModule="false"

echo "Loading Modules"
module purge
module load cpu/0.17.3b
module load aocc/3.2.0/
module load slurm
module load openmpi/4.1.3/
       
if $useModule
   then
       echo "Loading OpenFOAM 12 module and sourcing bashrc"
       module load openfoam/12
       source /nas/sycamore/apps/openfoam/12/OpenFOAM-12/etc/bashrc
   else
       echo "Sourcing OpenFOAM 10"               
       source /home/bshepherd/OpenFOAM/OpenFOAM-10/etc/bashrc
fi

if ${proc10}
then
  dirs_=( p025 p045 p060 p145 p160 p260 p345-cv
        p125nm-w p125-cv p125-w
        p245-cv p245cv-w
        p045-w p145-w p225-w p345-w)
  let nd=7+3+2+4-1
  nProc=1280
else
  dirs_=( p125 p225 p245 p325-15 p360 p245-w)
  let nd=6-1
  nProc=1920
fi

echo Dir list: ${dirs_[@]}
echo Number of dirs: ${nd}
echo Number of procs: ${nProc}

for d in $(seq 9 ${nd})
do
    cased=${dirs_[$d]}
    echo "for d =" $d ", case is:" ${cased}
    cd ${cased}                                                                                                                                                                              
    #mpirun -np ${nProc} foamFormatConvert -parallel 
    mpirun -np ${nProc} postProcess -parallel -func writeCellCentres
    cd ..  
done
