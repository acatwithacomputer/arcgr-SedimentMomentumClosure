#!/bin/bash

for i in $(seq 0 9)
do
    mkdir post$i
    # Make and place volume integral directory
    mkdir ./post$i/volumeIntegrals
    mkdir ./post$i/volumeIntegrals/0
    cp ./vola0$i.dat ./post$i/volumeIntegrals/0/volFieldValue.dat
    # Make and place surface integral directory
    mkdir ./post$i/surfaceIntegrals
    mkdir ./post$i/surfaceIntegrals/0
    cp ./surfa0${i}.dat ./post$i/surfaceIntegrals/0/surfaceFieldValue.dat
done