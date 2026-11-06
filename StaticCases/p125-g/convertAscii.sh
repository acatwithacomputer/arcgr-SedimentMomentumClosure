#!/bin/bash
#SBATCH --job-name=ca-p125
#SBATCH --partition=compute
#SBATCH --nodes=15
#SBATCH --ntasks-per-node=128
#SBATCH -t 4:00:00
#SBATCH -A nca125

logdir=logs
mkdir ${logdir}
useModule="false"
stepone="false"
steptwo="true"
stepthree="false"

echo "Loading Modules"
module purge
module load cpu/0.17.3b
module load aocc/3.2.0/
module load slurm
module load openmpi/4.1.3
       
if $useModule
   then
       echo "Loading OpenFOAM 12 module and sourcing bashrc"
       module load openfoam/12
       source /nas/sycamore/apps/openfoam/12/OpenFOAM-12/etc/bashrc
   else
       echo "Sourcing OpenFOAM 10"               
       source /home/bshepherd/OpenFOAM/OpenFOAM-10/etc/bashrc
fi

echo " "

    nProcs=1920
    echo "Running convert"
    which foamFormatConvert
    mpirun -np ${nProcs} foamFormatConvert -parallel > ${logdir}/log.foamFormatConvert
    echo " "    

echo "Done."
