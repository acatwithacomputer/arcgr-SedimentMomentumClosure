#!/bin/bash
#SBATCH --job-name=MV
#SBATCH -N 1
#SBATCH --tasks-per-node=48
#SBATCH -p small
#SBATCH -t 12:00:00
#SBATCH --mem=256G

useModule="false"

echo "Loading OpenMPI 5.0.6"
module load openmpi_5.0.6/gcc_13.3.0
export UCX_TLS=^ud
#export OMPI_MCA_coll_hcoll_enable=0

if $useModule
   then
       echo "Loading OpenFOAM 12 module and sourcing bashrc"
       module load openfoam/12
       source /nas/sycamore/apps/openfoam/12/OpenFOAM-12/etc/bashrc
   else
       echo "Sourcing OpenFOAM 10"               
       source /nas/sycamore/home/breizh/OpenFOAM/OpenFOAM-10/etc/bashrc
fi


echo "Run the thing"
which simpleFoamMod
bash ./Allrun
echo " "
echo "Done!"