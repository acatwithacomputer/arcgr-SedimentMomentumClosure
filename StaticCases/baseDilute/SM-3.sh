#!/bin/bash
#SBATCH --job-name=ip2-.6
#SBATCH -p small
#SBATCH -t 02:00:00
#SBATCH -n 2
#SBATCH --mem=400G

nPx=10
nPy=10
nPz=20
nProcs=2000
sed -i "18s/.*/numberOfSubdomains  ${nProcs};/" ./system/decomposeParDict
sed -i "24s/.*/    n           (${nPx} ${nPy} ${nPz});/" ./system/decomposeParDict

logdir=logs

echo "Sourcing OF-10 bashrc"
source ~/OpenFOAM/OpenFOAM-10/etc/bashrc
decomposePar > ${logdir}/log.decomposePar2
#mpirun -np ${nProcs} topoSet -parallel > ${logdir}/log.topoSet
#bash Allrun ${nProcs} ${logdir}
#./runParallel.sh

