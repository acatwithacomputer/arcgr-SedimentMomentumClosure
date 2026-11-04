#!/bin/bash
#SBATCH --job-name=s1-p1-.6
#SBATCH -p small
#SBATCH -t 02:00:00
#SBATCH -n 2
#SBATCH --mem=300G

nPx=10
nPy=10
nPz=20
nProcs=2000
sed -i "18s/.*/numberOfSubdomains  ${nProcs};/" ./system/decomposeParDict
sed -i "24s/.*/    n           (${nPx} ${nPy} ${nPz});/" ./system/decomposeParDict

logdir=logs
mkdir ${logdir}

echo "Loading OF-12 module and sourcing bashrc"
module load openfoam/12
source /nas/sycamore/apps/openfoam/12/OpenFOAM-12/etc/bashrc 

mkdir ${logdir}
echo "Running blockMesh"
which blockMesh
blockMesh > ${logdir}/log.blockMesh
echo "Running decomposePar"
which decomposePar
decomposePar > ${logdir}/log.decomposePar
echo "Done. Move to step 2."
