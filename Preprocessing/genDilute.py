#!/usr/bin/env python

import sys
import math

import numpy as np
from DiluteMeshing.MeshingFunctions import meshSpheres
from DiluteMeshing.GeneratePositions import *



def mxz():
  R  = .5
  eps = [.05, .1, R, 1.5*R, 3.0*R]

  Lx = 6.0
  Ly = 4.0
  Lz = 4.0
  print("Generating mx configurations")
  for i in range(len(eps)):
    print("R1 xgen "+str(i))
    outputfn = "./mx-" + str(i) + ".stl"
    pts = xgen2(Lx,Ly,Lz,R,eps[i])
    #makeMesh(pts,Lx,Ly,Lz,R,outputfn)
    meshSpheres(pts,[R, R],outputfn)

  Lx = 4.0
  Ly = 4.0
  Lz = 6.0
  print("Generating mz configurations")
  for i in range(len(eps)):
    print("R1 zgen "+str(i))
    outputfn = "./mz-" + str(i) + ".stl"
    pts = zgen2(Lx,Ly,Lz,R,eps[i])
    #makeMesh(pts,Lx,Ly,Lz,R,outputfn)
    meshSpheres(pts,[R, R],outputfn)

def msk():
  print("Generating msk configuration")
  R  = .5
  eps = [.05, .1, R, 1.5*R, 3.0*R]

  Lx = 6.0
  Ly = 6.0
  Lz = 6.0

  for i in range(len(eps)):
    print("R1 xgen "+str(i))
    outputfn = "./msk-" + str(i) + ".stl"
    pts = xgen3(Lx,Ly,Lz,R,eps[i])
    #makeMesh(pts,Lx,Ly,Lz,R,outputfn)
    meshSpheres(pts,[R, R],outputfn)

  #for i in range(len(eps)):
  #  print("R1 zgen "+str(i))
  #  outputfn = "./positionsF" + str(i) + ".stl"
  #  pts = ygen3(Lx,Ly,Lz,R,eps[i])
  #  makeMesh(pts,Lx,Ly,Lz,R,outputfn)

def pxz():
  R1 = .25
  R2 = .5
  eps = [.05, .1, .2, .4]
  
  Lx = 6.0
  Ly = 4.0
  Lz = 4.0

  print("Generating px1 configurations")
  for i in range(len(eps)):
    print("polyx1, eps "+str(i))
    outputfn = "./px1-" + str(i) + ".stl"
    pts = xgenPoly(Lx,Ly,Lz,R1,R2,eps[i])
    meshSpheres(pts,[R1, R2],outputfn)

  print("Generating px2 configurations")
  for i in range(len(eps)):
    print("polyx2, eps "+str(i))
    outputfn = "./px2-" + str(i) + ".stl"
    pts = xgenPoly(Lx,Ly,Lz,R2,R1,eps[i])
    meshSpheres(pts,[R2, R1],outputfn)
  
  Lx = 4.0
  Ly = 4.0
  Lz = 6.0
  print("Generating pz configurations")
  for i in range(len(eps)):
    print("polyz, eps "+str(i))
    outputfn = "./pz-" + str(i) + ".stl"
    pts = zgenPoly(Lx,Ly,Lz,R1,R2,eps[i])
    meshSpheres(pts,[R1, R2],outputfn)






mxz()
msk()
pxz()
print("Done")
