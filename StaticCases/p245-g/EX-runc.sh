#!/bin/bash
#SBATCH --job-name=rc-p245
#SBATCH --partition=compute
#SBATCH --nodes=15
#SBATCH --ntasks-per-node=128
#SBATCH -t 1-00:00:00
#SBATCH -A nca125

logdir=logs
mkdir ${logdir}
useModule="false"
nProcs=1920 #640

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

echo "Finally run the thing"
which simpleFoamMod
bash ./AllrunSMc ${logdir} ${nProcs}
#srun simpleFoamMod -parallel > ${logdir}/log.simpleFoamMod
echo " "
echo "Done!"
