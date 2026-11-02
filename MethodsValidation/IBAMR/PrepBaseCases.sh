#!/bin/bash

echo "Copying IBAMR initial cases"

for pi in $(seq 1 3)
do
    cp -r BaseCase ib-${pi}0
    cp input/input2d-${pi}0 ib-${pi}0
done

echo "Done"