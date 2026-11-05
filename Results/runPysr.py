import numpy as np
np.bool = np.bool_
from post.fitR import *
from post.pysrFunctions import *


def runPysr(R,measures,labels,case2run,linear,nProc,nIter,selectedNorm):
    print("Confirm the cases being used:")
    print(labels[case2run])
    print("Measures of these cases:")
    print(measures[case2run,:])
    if linear:
        print("Run PySR for linear coefficient")
        runPySRLinear(measures[case2run,:],R[case2run,0],nProc,nIter,selectedNorm)
    else:
        print("Run PySR for quadratic coefficient")
        runPySRQuadratic(measures[case2run,:],R[case2run,1],nProc,nIter,selectedNorm)
    return

def getMaxRe(dataLocation):
    letter=getAllCodes()
    nCases = len(letter)
    for i in range(0,nCases):
        isDilute,configRange, rho, nu, mu, L, Vw, Vbox, smd, measures_ = loadParameters(letter[i],dataLocation)
        for j in range(0, configRange): #   Loop through the configurations
            # New data scooping
            # Divy up and weigh the OpenFOAM data
            if isDilute:
                code = letter[i]+str(j)
                caseLocation = dataLocation + code
            else:
                code = letter[i]
                caseLocation = dataLocation + code
            
            ng = getng(caseLocation)
            volData, surfData = collectDataAcrossGValues(ng,caseLocation)
            vRe,sRe,lhs,tstar,gpt = prepForFit(volData, surfData,smd,rho,mu,Vw,Vbox,L,ng,isDilute,principalOnly=True,caseLocation=caseLocation)
            
            # Save the info
            maxRe_ = np.max(sRe)
            if i<1 and j<1:
                #print("size",np.size(R_))
                maxRe = np.array([maxRe_])
            else:
                maxRe = np.append(maxRe,maxRe_)
    #print("max re in function:", maxRe)
                
    return maxRe

################################################
### Settings to toggle

laptop = True

if laptop:
    dataLocation = "./results/"
    nProc=4
    nIter=100
else:
    dataLocation = "/work/users/b/r/breizh/pysr/results/"
    nProc=16
    nIter=10000

linear = True             # Select which R_i  
selectedNorm = "L2"       # Select loss function norm

################################################
### Load up the data

# R_,res_,measures,labels, candidates, gpt = loadAllData(dataLocation)
R_,res_,measures,labels, gpt = loadAllData(dataLocation)
maxRe = getMaxRe(dataLocation)
#print("Max re", maxRe)
Rlin  = R_[:,0]
Rquad = R_[:,1:3]

###########################################
### RUN PYSR!

print("Rquad",np.shape(Rquad))
#print(Rquad)
ndshape = np.shape(Rquad)
nd = ndshape[0]

# Add in ew = 1-es to make up for lack of way to construct ew
ew = np.reshape(1.0-measures[:,0],(nd,1))
includeew = True
if includeew:
    print("Including ew calculation")
    measures = np.hstack((measures,ew))

# Pick out the data from the dense and mid range cases
middenseonly = range(-20,-6)

# Run PySR for all cases
case2run = middenseonly
print("Running cases:",labels[case2run])
runPysr(Rquad,measures,labels,case2run,linear,nProc,50*nIter,selectedNorm)



