#!/bin/bash

copyCase () {
    newdir=${1}-${2}
    echo "New directory: " ${newdir}
  
    #Copy case basics
    cp -r baseDilute/ ${newdir}/
    cp ../Preprocessing/${newdir}.stl ${newdir}/constant/geometry/spheres.stl
}

copyCases () {
    for j in $(seq 0 3)
    do
	copyCase ${1} ${j}
    done
    
}

case=mx
echo "Copying case sequence: " ${case}
copyCases ${case}

case=mz
echo "Copying case sequence: " ${case}
copyCases ${case}

case=msk
echo "Copying case sequence: " ${case}
copyCases ${case}

case=px1
echo "Copying case sequence: " ${case}
copyCases ${case}

case=px2
echo "Copying case sequence: " ${case}
copyCases ${case}

case=pz
echo "Copying case sequence: " ${case}
copyCases ${case}
	     
echo " "
echo "Done!"
