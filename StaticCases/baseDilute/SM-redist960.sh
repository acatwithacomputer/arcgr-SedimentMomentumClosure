#!/bin/bash
#SBATCH --job-name=rd-160-960
#SBATCH -n 2
#SBATCH -p small
#SBATCH -t 08:00:00
#SBATCH --mem=800G

logdir=logs
mkdir ${logdir}
useModule="true"

echo "Loading OpenMPI 5.0.6"
module load openmpi_5.0.6/gcc_13.3.0
export UCX_TLS=^ud
       
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

#reconstructPar -latestTime

rm -rf processor*

echo "Prepare to decompose for the run."
nPx=8
nPy=10
nPz=12
nProcs=960 #1056 #528
sed -i "18s/.*/numberOfSubdomains  ${nProcs};/" ./system/decomposeParDict
sed -i "24s/.*/    n           (${nPx} ${nPy} ${nPz});/" ./system/decomposeParDict

echo "Running decomposePar: " ${nProcs}
which decomposePar 
decomposePar > ${logdir}/log.decomposeParRun
echo " "

echo " "
echo "Done!"
