#!/usr/bin/env python

###
### This file is generated automatically by SALOME v9.12.0 with dump python functionality
###

import sys
#import salome
import math

#salome.salome_init()
#import salome_notebook
#notebook = salome_notebook.NoteBook()
import numpy as np
import pygmsh

def makeMesh(pts,Lx,Ly,Lz,r,outputfn):
  ###
  ### GEOM component
  ###

  import GEOM
  from salome.geom import geomBuilder
  import SALOMEDS

  geompy = geomBuilder.New()

  O = geompy.MakeVertex(0, 0, 0)
  OX = geompy.MakeVectorDXDYDZ(1, 0, 0)
  OY = geompy.MakeVectorDXDYDZ(0, 1, 0)
  OZ = geompy.MakeVectorDXDYDZ(0, 0, 1)

  Box_1 = geompy.MakeBoxDXDYDZ(Lx, Ly, Lz)

  Spheres = []

  npts = len(pts)

  for i in range(npts):
    print("Sphere index : " + str(i))
    x = pts[i,0]
    y = pts[i,1]
    z = pts[i,2]
    Vertex_1 = geompy.MakeVertex(x, y, z)
    Sphere_1 = geompy.MakeSpherePntR(Vertex_1, r)
    Spheres.append(Sphere_1)

  print("Fusing and cutting...")
  Fuse_1 = geompy.MakeFuseList(Spheres, True, True)
  #Cut_1 = geompy.MakeCutList(Box_1, [Fuse_1], True)
  #Common_1 = geompy.MakeCommonList([Box_1, Fuse_1], True)

  print("Extracting faces and grouping them...")
  faces = geompy.ExtractShapes(Fuse_1, geompy.ShapeType["FACE"], True)
  Group_1 = geompy.CreateGroup(Fuse_1, geompy.ShapeType["FACE"])
  Ids = geompy.SubShapeAllIDs(Fuse_1,geompy.ShapeType["FACE"]) 
  geompy.UnionIDs(Group_1, Ids)

  print("Adding everything to the study...")
  geompy.addToStudy( O, 'O' )
  geompy.addToStudy( OX, 'OX' )
  geompy.addToStudy( OY, 'OY' )
  geompy.addToStudy( OZ, 'OZ' )

  geompy.addToStudy( Box_1, 'Box_1' )
  geompy.addToStudy( Fuse_1, 'Fuse_1')
  #geompy.addToStudy( Cut_1, 'Common_1')
  nf = len(faces)
  for i in range(nf):
    facename = "Face_" + str(i)
    geompy.addToStudyInFather( Fuse_1, faces[i], facename )
  geompy.addToStudyInFather( Fuse_1, Group_1, 'Group_1' )

  #geompy.addToStudy( Partition_1, 'Partition_1' )

  ###
  ### SMESH component
  ###

  import  SMESH, SALOMEDS
  from salome.smesh import smeshBuilder

  print("Making a new mesh and setting parameters...")
  smesh = smeshBuilder.New()
  #smesh.SetEnablePublish( False ) # Set to False to avoid publish in study if not needed or in some particular situations:
                                  # multiples meshes built in parallel, complex and numerous mesh edition (performance)

  Mesh_1 = smesh.Mesh(Group_1,'Mesh_1')
  NETGEN_1D_2D = Mesh_1.Triangle(algo=smeshBuilder.NETGEN_1D2D)
  NETGEN_2D_Parameters_1 = NETGEN_1D_2D.Parameters()
  NETGEN_2D_Parameters_1.SetMaxSize( 0.02 )
  NETGEN_2D_Parameters_1.SetMinSize( 0.01 )
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

  print("Computing mesh...")
  isDone = Mesh_1.Compute()
  print("Exporting mesh...")
  try:
    Mesh_1.ExportSTL( outputfn, 1 )
    pass
  except:
    print('ExportSTL() failed. Invalid file name?')

  print("Exporting done!")

  ## Set names of Mesh objects
  smesh.SetName(NETGEN_1D_2D.GetAlgorithm(), 'NETGEN 1D-2D')
  smesh.SetName(NETGEN_2D_Parameters_1, 'NETGEN 2D Parameters_1')
  smesh.SetName(Mesh_1.GetMesh(), 'Mesh_1')


  if salome.sg.hasDesktop():
    salome.sg.updateObjBrowser()
  
  return

def meshSpheres(pos_,r_,stlname):
    nsph = len(r_)
    with pygmsh.geo.Geometry() as geom:
        for i in range(0,nsph):
            pos = pos_[i,:]
            r = r_[i]
            geom.add_ball(pos,r,mesh_size=r * 0.025)
        print("Generating mesh: " + stlname)
        mesh = geom.generate_mesh()
    print("Writing mesh: " + stlname)
    mesh.write(stlname)
    print("Done writing mesh: "+stlname)