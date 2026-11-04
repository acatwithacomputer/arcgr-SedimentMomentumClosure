import numpy as np 
import pygmsh
from numpy.random import default_rng


"""
def computeNonDimMeasures(Lx,radii):
    rsq = np.multiply(radii,radii)
    Asi = 4.0*np.pi*rsq
    As = sum(Asi)
    Vsi = 4.0/3.0*np.pi*np.multiply(rsq,radii)
    Vs = sum(Vsi)
    Vbox = Lx**3

    smd = 6.0*sum(Vsi)/sum(Asi)
    # Non dim ews: 
    # ews*smd = (As/Vbox)*(6*Vs/As)
    #         = 6*Vs/Vbox = 6*es
    es = Vs/Vbox
    ewss = 6.0*es
    # Non dim J
    ones = np.ones(np.shape(radii))
    Jmi  = 2.0*np.divide(ones,radii)
    Jma  = sum(np.multiply(Jmi,Asi))/As
    Jmas = Jma*smd
    # Non dim K
    Kmi  = np.divide(ones,rsq)
    Kma  = sum(np.multiply(Kmi,Asi))/As
    Kmas = Kma*smd*smd

    Jmeas = ewss*Jmas
    Kmeas = ewss*Kmas

    return es,ewss,Jmeas,Kmeas,smd
"""
    
def loadFullList(filename):
    data=np.genfromtxt(filename,delimiter=",")
    pos = data[:,0:3]
    r = data[:,-1]
    return pos,r

def meshSpheres(pos_,r_,stlname):
    nsph = len(r_)
    with pygmsh.geo.Geometry() as geom:
        for i in range(0,nsph):
            pos = pos_[i,:]
            r = r_[i]
            geom.add_ball(pos,r,mesh_size=r * 0.1)
        print("Generating mesh: " + stlname)
        mesh = geom.generate_mesh()
    print("Writing mesh: " + stlname)
    mesh.write(stlname)
    print("Done writing mesh: "+stlname)


# Come back for p345 case
cases=["p025-g", "p045-g", "p045-g-w", "p060",  
        "p125-g", "p125-e", "p125-g-w", "p125-e-w",    
        "p145-g", "p145-g-w", "p160", 
        "p245-g", "p245-e", "p245-g-w", "p245-e-w",
        "p225-g", "p260",      
        "p325-g", "p345-e", "p360"]

ncases = len(cases)

for i in range(0,ncases):
    fn=cases[i]

    
    pos,r = loadFullList("SphereLists/"+fn+".csv")
    print("Meshing: "+fn)
    meshSpheres(pos,r,fn+".stl")

print("Done!")
