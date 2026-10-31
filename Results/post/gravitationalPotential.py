import numpy as np

"""
Functions to compute the gravitational potential on the surface of spheres

The component functions are calculated using n_s,  as that is easier to do
by hand, but the sign is flipped at the very end since we are typically 
want the calculation using n_w.

Note: the list of spheres should only be spheres that are contained in the 
domain of interest. Peridicity is handled with a boolean switch. 

INPUTS:
R : radii of the spheres
g : the body force that you want to use
z0: the list of sphere centers
L : the cutoff in z, typically the (L)ength of the box
periodic: boolean switch for periodicity
"""

def computeGptermSphere(R,g):
    # Compute the term for a sphere inside the domain
    Rsq = np.multiply(R,R)
    gp = np.sum(4.0/3.0*np.pi*g*np.multiply(Rsq,R))
    return gp

def computeGptermCaps(R,g,z0,L):
    # Compute the term
    Lmz = L-z0
    Lmz2 = np.multiply(Lmz,Lmz)
    Lmz3 = np.multiply(Lmz2,Lmz)
    Rsq = np.multiply(R,R)
    Rcb = np.multiply(Rsq,R)

    # z^2 integral
    I1 = 2.0/3.0*(Rcb-Lmz3)
    # z0*z integral
    I2 = np.multiply(z0,Rsq-Lmz2)

    I = np.pi*g*np.sum(I1 + I2)

    return I

def computeGptermBottoms(R,g,z0,L):
    # Compute for entire sphere
    I = computeGptermSphere(R,g)
    # Remove contribution from the cap
    I = I - computeGptermCaps(R,g,z0,L)
    return I

def computeGptermPartial(R_,g,z0_,L,periodic):
    I = 0.0
    z0 = np.array(z0_)
    R = np.array(R_)
    bot = z0 < R
    if np.sum(bot) > 0:
        I = I + computeGptermCaps(R[bot],g,z0[bot],0.0)
        if periodic:
            I = I + computeGptermBottoms(R[bot],g,z0[bot]+L,L)
    # Contribution from top spheres
    top = abs(L-z0) < R
    if np.sum(top) > 0:
        I = I + computeGptermBottoms(R[top],g,z0[top],L)
        if periodic:
            I = I + computeGptermCaps(R[top],g,z0[top]-L,0.0)

    return I

def computeGpterm(R,g,z0,L,periodic):
    # Sort spheres
    perBot = np.less_equal(z0, R)           # Bottom spheres that will repeat at the top
    perTop = np.less_equal(L - z0, R)       # Top spheres that will repeat at the bot
    perPts = np.logical_or(perTop,perBot)   # Combine periodic points
    intPts = np.logical_not(perPts)         # Spheres fully in interior
    
    # Compute parts of the term
    I1 = computeGptermSphere(R[intPts],g)
    I2 = computeGptermPartial(R[perPts],g,z0[perPts],L,periodic)
    # Return sum of contributions; negated to account for direction of normals
    return -(I1+I2)

"""
Functions to compute the gravitational potential in the volume
"""

def computeGpmaFull(g,z0,R):
    rsq = np.multiply(R,R)
    Vs = 4.0/3.0*np.pi*np.multiply(R,rsq)
    return g*np.sum(np.multiply(z0,Vs))

def computeGpmaPartial(g,z0,R,L):
    # Computing partial sphere contribution to gpmas
    Lmz = L-z0
    Lmz2 = np.multiply(Lmz,Lmz)
    rsq = np.multiply(R,R)
    
    I1 = 1.0/4.0*np.multiply(rsq,rsq-Lmz2)
    I2 = 2.0/3.0*np.multiply(np.multiply(z0,rsq),R-Lmz)
    I3 = 1.0/4.0*np.multiply(Lmz2,Lmz2-rsq)
    I4 = 1.0/3.0*np.multiply(np.multiply(z0,Lmz),Lmz2-rsq)
    return g*np.pi*np.sum(I1+I2+I3+I4)


def computeGpma(g,z0,R,L,periodic):
    # Compute gpma, full domain
    I_full = g/2*(L**4)
    # Sort the spheres
    bot = np.less(z0,R)
    top = np.greater(z0+R,L)
    int = np.logical_not(np.logical_or(bot,top))
    # Compute interior sphere contribution
    I_int = computeGpmaFull(g,z0[int],R[int])
    # Compute bottom sphere contribution
    I_bot = computeGpmaPartial(g,z0[bot],R[bot],0.0)
    # Compute top sphere contribution
    I_top = computeGpmaFull(g,z0[top],R[top]) - computeGpmaPartial(g,z0[top],R[top],L)
    
    I = I_full - I_int - I_bot - I_top

    if periodic:
        I_topp = computeGpmaPartial(g,z0[top]-L,R[top],0.0)
        I_botp = computeGpmaFull(g,z0[bot]+L,R[bot]) - computeGpmaPartial(g,z0[bot]+L,R[bot],L)
        I = I - I_topp - I_botp

    return I