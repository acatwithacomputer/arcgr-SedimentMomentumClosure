# Introduction

The following repository contains all of the data for the sediment transport momentum closure work published in Shepherd, Bowers et al. 2026, found [here](https://janeway.uncpress.org/ARC-GR/article/id/4973/). 

## Software

To reproduce results from this data, all that is required is Python 3. To reproduce the data, the following software is required. 

Required CFD software includes:
* OpenFOAM 10 [Link](https://openfoam.org/download/10-source/ "OpenFOAM-10")
* autoibamr [Link](https://github.com/IBAMR/autoibamr "autoibamr") 

Required python packages include:
* Numpy
* pygmsh
* PySR

Optional software for preprocessing includes:
* SALOME 
* MATLAB 2020a or Octave
* LIGGGHTS

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

## Preprocessing: pack generation and meshing

The generation of the two sphere meshes may be performed by running the python script `Preprocessing/genDilute.py`. The monodisperse meshes were originally generated with SALOME, which is reflected in `Preprocessing/DiluteMeshing/MeshingFunctions.py`, however they are all set up to be generated with `pygmsh`.

For ease, we recommend running the `Preprocessing/genMid.py` script that is set up to reproduce the dense and mid-range cases based on the sphere lists that were generated with the following process. The dense packings are generated using the `Preprocessing/genDense.py` case in conjunction with the [SpherePacking](https://github.com/tmweigand/spherePacking) code. A MATLAB script that was lost during file recovery after a work station issue was used to randomly remove spheres by applying the `randi` function result to the indicies of the list of radii. A selection of these were fed back into the SpherePacking code to generate the "e" cases. To generate the "w" cases, install the LIGGGHTS package and run the cases found in `Preprocessing/Walk`.

## Dilute Cases

After having run `genDilute.py` in the `Preprocessing` directory, use the bash script `StaticCases/CopyDiluteBase.sh` to copy the cases. The scripts `SM-mesh.sh` and `SM-run.sh` were used to run the cases. For transient cases, where necessary, the files in the system directory ending with `*-pf` was used to overwrite the corresponding file. 

## Midrange and Dense cases

# Data Analysis

All data resulting from simulations may be found in the `Results/results` directory. 

## Running PySR
Before running PySR, first make sure that it is installed. That information may be found [here](https://github.com/astroautomata/PySR). It'll take a minute to set up the first time it's imported. The PySR running script is `Results/runPysr.py`. Before running, there are a couple things to check.

1. Line 53, `laptop=[bool]` toggles the settings used during local testing versus running on a part of a node on a cluster. 

2. Line 64, `linear=[bool]` selects whether to run PySR for R1 (the linear coefficient) or R2 (the quadratic coefficient). 

Since the L2 norm was used, that may be left as is. 

## Model evaluation

In order to do the evaluation and get the comparison figures, run the script in `Results/evalPysr.py`.

# To Do list
- [x] Methods validation: openfoam cases
- [x] Methods validation: ibamr cases
- [ ] Methods validation: ibamr post processing
- [x] Methods validation: analysis matlab
- [ ] Methods validation: analysis octave
- [x] Preprocess: Two sphere meshes
- [x] Preprocess: Mid/dense meshes
- [x] Preprocess: Cross validation walk
- [x] Preprocess: Cross validation meshes
- [x] Two sphere: Base case
- [x] Two sphere: Scripts
- [ ] Mid/Dense: Base case
- [ ] Mid/Dense: scripts
- [x] Analysis: Get data
- [x] Analysis: PySR run script
- [x] Analysis: PySR eval script