#!/bin/bash
#SBATCH --job-name=m3-p225
#SBATCH --partition=large-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 3:00:00
#SBATCH -A nca125
#SBATCH --mem=300G

logdir=logs
mkdir ${logdir}
useModule="false"
stepone="false"
steptwo="false"
stepthree="true"

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

if $stepone
then
    echo "Running blockMesh"
    which blockMesh
    blockMesh > ${logdir}/log.blockMesh
    echo " "
    
    echo "Prepare to decompose for the run."
    nPx=16
    nPy=10
    nPz=8
    nProcs=1280 #1056 #528
    sed -i "18s/.*/numberOfSubdomains  ${nProcs};/" ./system/decomposeParDict
    sed -i "24s/.*/    n           (${nPx} ${nPy} ${nPz});/" ./system/decomposeParDict


    echo "Running decomposePar: " ${nProcs}
    which decomposePar
    decomposePar > ${logdir}/log.decomposeParMesh
    echo " "
else
    echo "Skipping step one"
fi

if $steptwo
then
    nProcs=1280
    echo "Running checkMesh"
    which checkMesh
    mpirun -np ${nProcs} checkMesh -parallel > ${logdir}/log.checkMeshBlock
    echo " "
    
    echo "Running snappyHexMesh"
    which snappyHexMesh
    mpirun -np ${nProcs} snappyHexMesh -overwrite -parallel > ${logdir}/log.snappyHexMesh
    echo " "

    echo "Running checkMesh"
    which checkMesh
    mpirun -np ${nProcs} checkMesh -parallel > ${logdir}/log.checkMeshSnappy
    echo " "
else
    echo "Skipping step two"
fi

if $stepthree
   then
       echo "Reconstructing the mesh."
       which reconstructParMesh
       reconstructParMesh -constant > ${logdir}/log.reconstructParMesh
       echo " "
else
    echo "skipping step three"
fi
echo "Done."
