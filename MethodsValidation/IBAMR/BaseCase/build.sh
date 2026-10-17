#!/bin/bash

cluster="false"


if $cluster
then
    module load openmpi_4.0.1/gcc_11.2.0
    module load python/3.9.6
    source $HOME/autoibamr/configuration/enable.sh
else
    IBAMR_ROOT=~/sfw/ibamr
fi

rm -r build
mkdir build
cd build
cmake -DIBAMR_ROOT="${IBAMR_ROOT}" -DCMAKE_CXX_COMPILER=mpicxx ../
make -j 4

cp ../input2d .
cp ../sphere3d.vertex .
cp ../run.sh .