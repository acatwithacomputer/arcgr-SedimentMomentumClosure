#!/usr/bin/env python

###
### This file is generated automatically by SALOME v9.12.0 with dump python functionality
###

import sys
import salome

salome.salome_init()
import salome_notebook
notebook = salome_notebook.NoteBook()
sys.path.insert(0, r'/home/brittany/sedTransp/genIC/fixTest')
import numpy as np

###
### GEOM component
###

import GEOM
from salome.geom import geomBuilder
import math
import SALOMEDS

Lx = 2.0
Ly = 2.0
Lz = 2.0
D = 1.0
r = D/2.0


geompy = geomBuilder.New()

O = geompy.MakeVertex(0, 0, 0)
OX = geompy.MakeVectorDXDYDZ(1, 0, 0)
OY = geompy.MakeVectorDXDYDZ(0, 1, 0)
OZ = geompy.MakeVectorDXDYDZ(0, 0, 1)

Box_1 = geompy.MakeBoxDXDYDZ(Lx, Ly, Lz)

print("Put sphere down...")
x = Lx/2.0
y = Ly/2.0
z = Lz/2.0
Vertex_1 = geompy.MakeVertex(x, y, z)
Sphere_1 = geompy.MakeSpherePntR(Vertex_1, r)


print("Exploding... (!!!)")
shells = geompy.ExtractShapes(Sphere_1, geompy.ShapeType["SHELL"], True)

print("Making a group...")
Ids = geompy.SubShapeAllIDs(Sphere_1,geompy.ShapeType["FACE"]) 
Group_1 = geompy.CreateGroup(Sphere_1, geompy.ShapeType["FACE"])
geompy.UnionIDs(Group_1, Ids)

print("Adding everything to the study...")
geompy.addToStudy( O, 'O' )
geompy.addToStudy( OX, 'OX' )
geompy.addToStudy( OY, 'OY' )
geompy.addToStudy( OZ, 'OZ' )

geompy.addToStudy( Box_1, 'Box_1')
geompy.addToStudy( Sphere_1, 'Fuse_1')

nshells=len(shells)
for i in range(nshells):
  facename = "Shell_" + str(i)
  geompy.addToStudyInFather( Sphere_1, shells[i], facename )

###
### SMESH component
###

import  SMESH, SALOMEDS
from salome.smesh import smeshBuilder

print("New Mesh...")
smesh = smeshBuilder.New()
#smesh.SetEnablePublish( False ) # Set to False to avoid publish in study if not needed or in some particular situations:
                                 # multiples meshes built in parallel, complex and numerous mesh edition (performance)

print("Applying settings...")
Mesh_1 = smesh.Mesh(Group_1,'Mesh_1')
NETGEN_1D_2D = Mesh_1.Triangle(algo=smeshBuilder.NETGEN_1D2D)
NETGEN_2D_Parameters_1 = NETGEN_1D_2D.Parameters()
NETGEN_2D_Parameters_1.SetMaxSize( 0.0025 )
NETGEN_2D_Parameters_1.SetMinSize( 0.00125 )
NETGEN_2D_Parameters_1.SetSecondOrder( 0 )
NETGEN_2D_Parameters_1.SetOptimize( 1 )
NETGEN_2D_Parameters_1.SetFineness( 2 )
NETGEN_2D_Parameters_1.SetChordalError( -1 )
NETGEN_2D_Parameters_1.SetChordalErrorEnabled( 0 )
NETGEN_2D_Parameters_1.SetUseSurfaceCurvature( 1 )
NETGEN_2D_Parameters_1.SetFuseEdges( 1 )
NETGEN_2D_Parameters_1.SetWorstElemMeasure( 0 )
NETGEN_2D_Parameters_1.SetQuadAllowed( 0 )
NETGEN_2D_Parameters_1.SetUseDelauney( 160 )
NETGEN_2D_Parameters_1.SetCheckChartBoundary( 3 )

print("Computing new mesh...")
isDone = Mesh_1.Compute()
try:
  Mesh_1.ExportSTL( r'./constant/geometry/Group_3.stl', 1 )
  pass
except:
  print('ExportSTL() failed. Invalid file name?')

if salome.sg.hasDesktop():
  salome.sg.updateObjBrowser()
