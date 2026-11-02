#!/bin/bash

echo "Copying IBAMR Restarts"

vsn=2

for pi in $(seq 1 3)                    # Loop through initial cases
do
    for vsj in $(seq 1 ${vsn})
    do 
        # Directory info
        ibbase=ib-
        ib0=${ibbase}${pi}0
        ibn=${ibbase}${pi}${vsj}
        echo Copying ${ib0} to ${ibn}

        # Copy the thing
        cp -r ib-${pi}0 
        cp input/input2d-${pi}${vsj} ib-${pi}${vsj}
    done 
    # Prep for the next p_i
    let "vsn_ = vsn + 1"
    vsn=${vsn_}
done

echo "Done"