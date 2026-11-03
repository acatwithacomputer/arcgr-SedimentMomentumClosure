# Introduction

The following repository contains all of the data for the sediment transport momentum closure work published in Shepherd, Bowers et al. 2026, found [here](https://janeway.uncpress.org/ARC-GR/article/id/4973/). 

## Software

To reproduce results from this data, all that is required is Python 3. To reproduce the data, the following software is required. 

Required CFD software includes:
* OpenFOAM 10 [Link](https://openfoam.org/download/10-source/ "OpenFOAM-10")
* autoibamr [Link](https://github.com/IBAMR/autoibamr "autoibamr") 

Optional software includes:
* SALOME 
* MATLAB 2020a or Octave

The SALOME meshes are relatively small and are included in this repository. The MATLAB scripts used are also included, but have been rewritten in Python 3 in case of license issues. 

## OpenFOAM Modification

The pimpleFoam and simpleFoam solvers have been lightly modified for post processing. These modified solvers are contained in the `Mods` directory.

# Methods Validation

The methods validation simulates single cylinder cases using a moving particle solver, IBAMR, and a static solver, OpenFOAM. The fits, errors and plots may be reproduced with the MATLAB script `ViewResults.m` found in the `MethodsValidation/Analysis` directory.

## OpenFOAM

The OpenFOAM case is contained `MethodsValidation/OpenFOAM` and the various pressures are handled with a loop in `Allrun`. The cylinder mesh is already contained in the `constant/geometry` directory. 

The cases were originally run on UNC's Dogwood cluster with the `DW-run.sh` batch script, but a batch script for the current (as of this writing) parallel computing cluster at UNC, Sycamore, is also included with `SM-run.sh`. Furthermore, the Sycamore cluster was found to reproducte the original run exactly or to machine epsilon precision.

Data from the runs are found in the directories `MethodsValidation/OpenFOAM/post?`. The data is concatinated for the MATLAB script using the `condenseOF.py` script, producing the files `volOF.dat` and `surfOF.dat`. These are the files used by the `ViewResults` scripts.

## IBAMR

The script `MethodsValidation/IBAMR/PrepBaseCases.sh` will generate the cases for the stationary cylinder that may be run. After that run, the script `MethodsValidation/IBAMR/CopyRestarts.sh` will copy everything with the new input files that will move the sphere at some non-zero velocity.

# Static sphere simulations

## Meshes

The generation of the two sphere meshes may be performed by running the python script `Preprocessing/genDilute.py`. The monodisperse meshes were originally generated with SALOME, which is reflected in `Preprocessing/DiluteMeshing/MeshingFunctions.py`, however they are all set up to be generated with `pygmsh`.

## Dilute Cases

## Dense cases

## Midrange cases

# To Do list
- [x] Methods validation: openfoam cases
- [x] Methods validation: ibamr cases
- [ ] Methods validation: ibamr post processing
- [x] Methods validation: analysis matlab
- [ ] Methods validation: analysis octave
- [x] Preprocess: Two sphere meshes
- [ ] Preprocess: Mid/dense meshes
- [ ] Preprocess: Cross validation walk
- [ ] Preprocess: Cross validation meshes
- [ ] Two sphere: Base case
- [ ] Two sphere: Scripts
- [ ] Mid/Dense: Base case
- [ ] Mid/Dense: scripts
- [x] Analysis: Get data
- [ ] Analysis: PySR run script
- [ ] Analysis: PySR eval script