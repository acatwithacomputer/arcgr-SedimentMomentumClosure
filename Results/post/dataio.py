import numpy as np

"""
This is the file containing functions relating to the input and output of data
and loading of parameters. 

writeClean: takes filename, removes the header and parenthesis of the OpenFOAM
post processing output files, and outputs a "clean" file in the same directory
ready for input with numpy or MATLAB.

collectData: collects the last row of a loaded matrix (for simpleFOAM)

collectDataAcrossGValues: collects the converged volume and surface data across
all body forces run. Can be repurposed for collecting across different parameters
if that make sense to the situation.
"""

def writeClean(filename,filename2):
    unwanted_chars ="()"
    with open(filename) as f:
        lines=list(f)
    for k, line in enumerate(lines):
        for c in unwanted_chars:
            line=line.replace(c,'')
        lines[k]=line
    with open(filename2,'w') as f:
        for number, line in enumerate(lines):
            if number not in range(0,4):
                f.write(''.join(line))

def collectData(filename,data,i):
    data_ = np.loadtxt(filename)
    nd = np.shape(data_)
    if len(np.shape(data_)) < 2:
        data[i,:] = data_[1:]
    else:
        data[i,0:(nd[1]-1)] = data_[-1,1:]
    return data

def collectDataAcrossGValues(gRange,caseLocation):
    #volData = np.zeros((gRange,5))
    surfData= np.zeros((gRange,12))
    for k in range(0, gRange):  #   Loop through the g values
        voldir = caseLocation + "/post" + str(k) + "/volumeIntegrals/0"
        # remove parenthesis from data files
        filename  = voldir + "/volFieldValue.dat"
        filename2 = voldir + "/clean.dat"
        writeClean(filename,filename2)
        if k < 1:
            data=np.loadtxt(filename2)
            nd = np.shape(data)
            volData = np.zeros((gRange,nd[1]-1))
        collectData(filename2,volData,k)

        surfdir = caseLocation + "/post" + str(k) + "/surfaceIntegrals/0"
        filename  = surfdir + "/surfaceFieldValue.dat"
        filename2 = surfdir + "/clean.dat"
        writeClean(filename,filename2)
        collectData(filename2,surfData,k)
    return volData, surfData