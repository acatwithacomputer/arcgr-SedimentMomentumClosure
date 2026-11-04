#!/bin/bash
#SBATCH --job-name=s2-p2-.6
#SBATCH -p batch
#SBATCH -t 08:00:00
#SBATCH -n 2000
#SBATCH --mem-per-cpu=3G

logdir=logs
nProcs=2000
mkdir ${logdir}
export UCX_TLS=^ud

echo "Loading OF-12 module and sourcing bashrc"
module load openfoam/12
source /nas/sycamore/apps/openfoam/12/OpenFOAM-12/etc/bashrc 

echo "Running snappyHexMesh"
which snappyHexMesh
mpirun -np ${nProcs} snappyHexMesh -overwrite -parallel > ${logdir}/log.snappyHexMesh
echo "Running checkMesh"
which checkMesh
mpirun -np ${nProcs} checkMesh -parallel > ${logdir}/log.checkMesh
