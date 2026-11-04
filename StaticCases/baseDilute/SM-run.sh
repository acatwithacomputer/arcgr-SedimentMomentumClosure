#!/bin/bash
#SBATCH --job-name=r-p1-.60
#SBATCH -N 5
#SBATCH --tasks-per-node=192
#SBATCH -p batch
#SBATCH -t 1-00:00:00
#SBATCH --mem=256G

logdir=logs
mkdir ${logdir}
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
       source /nas/longleaf/home/breizh/OpenFOAM/OpenFOAM-10/etc/bashrc
fi

echo " "

#echo "Prepare to decompose for the run."
#nPx=10
#nPy=10
#nPz=10
#nProcs=1056
#sed -i "18s/.*/numberOfSubdomains  ${nProcs};/" ./system/decomposeParDict
#sed -i "24s/.*/    n           (${nPx} ${nPy} ${nPz});/" ./system/decomposeParDict

#echo "Running decomposePar: " ${nProcs}
#which decomposePar
#decomposePar > ${logdir}/log.decomposeParRun
#echo " "

#echo "Renumber the mesh"
#which renumberMesh
#srun renumberMesh -overwrite -parallel > ${logdir}/log.renumberMesh
#echo " "

#echo "Run topoSet"
#which topoSet
#srun topoSet -parallel > ${logdir}/log.topoSet
#echo " "

#echo "Check mesh one last time"
#which checkMesh
#srun checkMesh -parallel > ${logdir}/log.checkMeshRuna
#echo " "

echo "Finally run the thing"
which simpleFoamMod
bash ./AllrunSM ${logdir}
#srun simpleFoamMod -parallel > ${logdir}/log.simpleFoamMod
echo " "
echo "Done!"
