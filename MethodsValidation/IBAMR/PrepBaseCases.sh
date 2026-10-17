#!/bin/bash

echo "Copying IBAMR initial cases"

for i in $(seq 1 3)
do
    cp -r BaseCase ib-${i}0
    cp input/input2d-${i}0
done

echo "Done"