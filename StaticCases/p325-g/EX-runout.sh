#!/bin/bash
#SBATCH --job-name=r-p245w
#SBATCH --partition=compute
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH -t 00:25:00
#SBATCH -A nca125

logdir=logs
mkdir ${logdir}
useModule="false"
nProcs=256 #1920 #640

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

echo " "

echo "Run topoSet"
which topoSet
srun topoSet -parallel > ${logdir}/log.topoSet
echo " "


echo "Finally run the thing"
which simpleFoamMod
bash ./AllrunSM ${logdir} ${nProcs}
#srun simpleFoamMod -parallel > ${logdir}/log.simpleFoamMod
echo " "
echo "Done!"
