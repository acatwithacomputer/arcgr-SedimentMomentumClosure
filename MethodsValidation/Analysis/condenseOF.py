import numpy as np

def writeClean(filename,filename2):
    unwanted_chars ="()"
    with open(filename) as f:
        lines=list(f)
    for k, line in enumerate(lines):
        for c in unwanted_chars:
            line=line.replace(c,'')
        lines[k]=line
    # Original working version!
    #    with open(filename2,'w') as f:
    #        f.write(''.join(lines))
    #        #f.write('\n'.join(lines))
    with open(filename2,'w') as f:
        for number, line in enumerate(lines):
            # delete line 5 and 8. or pass any Nth line you want to remove
            # note list index starts from 0
            if number not in range(0,4):
                f.write(''.join(line))
def collectData(filename,data,i):
    print(filename)
    print(data)
    data_ = np.loadtxt(filename)
    data[i,:] = data_[-1,1:]
    return data
    

n = 9

volData = np.zeros((n+1,4))
surfData = np.zeros((n+1,9))

OFdir = "../OpenFOAM"
vdir   = "/volumeIntegrals/0"
sdir   = "/surfaceIntegrals/0"

for i in range(0, n+1):
    # remove parenthesis from data files
    filename  = OFdir + "/post" + str(i) + vdir + "/volFieldValue.dat"
    filename2 = OFdir + "/post" + str(i) + vdir + "/clean.dat"
    writeClean(filename,filename2)
    collectData(filename2,volData,i)

    filename  = OFdir + "/post" + str(i) + sdir + "/surfaceFieldValue.dat"
    filename2 = OFdir + "/post" + str(i) + sdir + "/clean.dat"
    writeClean(filename,filename2)
    collectData(filename2,surfData,i)

np.savetxt("./volOF.dat",volData,fmt='%.6e',delimiter=' ')
np.savetxt("./surfOF.dat",surfData,fmt='%.6e',delimiter=' ')