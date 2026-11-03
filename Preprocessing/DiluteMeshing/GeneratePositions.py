#!/usr/bin/env python

import sys
import math

import numpy as np

## Monodisperse in-line cases

def xgen2(Lx,Ly,Lz,R,eps):
  center = np.array([Lx/2.0, Ly/2.0, Lz/2.0])
  pts = np.zeros((2,3))
  pts[0,:] = center - np.array([eps+R, 0.0, 0.0])
  pts[1,:] = center + np.array([eps+R, 0.0, 0.0])
  return pts

def zgen2(Lx,Ly,Lz,R,eps):
  center = np.array([Lx/2.0, Ly/2.0, Lz/2.0])
  pts = np.zeros((2,3))
  pts[0,:] = center - np.array([0.0, 0.0, eps+R])
  pts[1,:] = center + np.array([0.0, 0.0, eps+R])
  return pts

## Monodisperse skew case

def xgen3(Lx,Ly,Lz,R,eps):
  th = np.linspace(0,2.0*np.pi,3)
  x = (2.0*R+eps)*np.cos(th)
  y = (2.0*R+eps)*np.sin(th)
  pts = np.zeros((3,3))
  pts[0][:] = Lx/2.0 + x
  pts[1][:] = Ly/2.0
  pts[2][:] = Lz/2.0 + y
  return pts

def ygen3(Lx,Ly,Lz,R,eps):
  th = np.linspace(0,2.0*np.pi,3)
  x = (2.0*R+eps)*np.cos(th)
  y = (2.0*R+eps)*np.sin(th)
  pts = np.zeros((3,3))
  pts[0][:] = Lx/2.0 
  pts[1][:] = Ly/2.0 + x
  pts[2][:] = Lz/2.0 + y
  return pts

# Polydisperse

def zgenPoly(Lx,Ly,Lz,R1,R2,eps):
  center = np.array([Lx/2.0, Ly/2.0, Lz/2.0])
  pts = np.zeros((2,3))
  pts[0,:] = center - np.array([0.0, 0.0, eps+R1])
  pts[1,:] = center + np.array([0.0, 0.0, eps+R2])
  return pts

def xgenPoly(Lx,Ly,Lz,R1,R2,eps):
  center = np.array([Lx/2.0, Ly/2.0, Lz/2.0])
  pts = np.zeros((2,3))
  pts[0,:] = center - np.array([eps+R1, 0.0, 0.0])
  pts[1,:] = center + np.array([eps+R2, 0.0, 0.0])
  return pts
