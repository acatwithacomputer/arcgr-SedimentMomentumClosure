#!/bin/bash

#===================================================================#
# DEMrun script for ErgunTestMPI_restart testcase
# init ErgunTestMPI_restart
# Daniel Queteschiner - June 2014, DCS Computing GmbH
#===================================================================#

#- source CFDEM env vars
. ~/.bashrc

#- include functions
source $CFDEM_PROJECT_DIR/etc/functions.sh

#--------------------------------------------------------------------------------#
#- define variables
casePath="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"
logpath="$casePath"
headerText="run_liggghts"
logfileName="log_$headerText"
solverName="in.liggghts_run"
nrProcs="1"
machineFileName="none"   # yourMachinefileName | none
seed=$1
postProc=$2
#--------------------------------------------------------------------------------#

#- call function to run DEM case
#bash setParams.sh $seed
parDEMrun $logpath $logfileName $casePath $headerText $solverName $nrProcs $machineFileName

# Create in.particles
#cd $casePath/ICs
#/usr/local/bin/matlab -nodisplay -nosplash -nodesktop -r convertIC

# Create paraview viewable?
#if $postProc 
#then
#    cd $casePath/DEM/post
#    python2 -i $CFDEM_LPP_DIR/lpp.py  dump.liggghts_run
#    cd ../..
#fi
