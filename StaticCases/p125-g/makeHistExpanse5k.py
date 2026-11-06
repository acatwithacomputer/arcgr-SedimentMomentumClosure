import os
import numpy as np
#import matplotlib.pyplot as plt

def loadU_SingleProc(caseLocation,proc,time):
    fn = caseLocation + "/processor" + str(proc) + "/" + str(time) + "/" + "U"
    f = open(fn,"r")
    # Get number of cells
    for i in range(0,20):   #Loop to get to line 20
        line = f.readline()
    nCells = int(line)
    #print("Number of cells:", nCells)
    # Skip the parenthesis line
    line = f.readline()

    # Initialize U
    U = np.zeros((nCells,3))
    # Loop through cells
    for i in range(0,nCells):
        line = f.readline()     # Read line
        #print("Line:",line[1:-2]) 
        U[i,:] = np.fromstring(line[1:-2],sep=" ") # Str 2 array
        #print("Numpy:",Ui)

    return U
    #print(nsph)

def findMinMaxU(caseLocation,nProc,time):
    #min = np.zeros((1,3))
    #max = np.zeros((1,3))
    # Loop through processors
    for proc in range(0,nProc):
        # Load U for this processor
        print("Max/min proc",proc)
        U = loadU_SingleProc(caseLocation,proc,time)
        if proc < 1:
            min = np.min(U,axis=0)
            max = np.max(U,axis=0)
        else:
            # Pick out the min
            min_ = np.min(U,axis=0)
            min = np.min(np.vstack((min,min_)),axis=0)
            #print("Minimum U:",np.min(np.vstack((min,min_)),axis=0))
            # Pick out the max
            max_ = np.max(U,axis=0)
            max = np.max(np.vstack((max,max_)),axis=0)
    return min, max

def getnProc(caseLocation):
    procList=[]
    for x in os.listdir(caseLocation):
        if x.startswith("processor"):
            # Prints only text file present in My Folder
            procList.append(x)
    nProc=len(procList)
    #print(ng)
    return nProc

def makeHistU(nBins,comp,caseLocation,time,show,save):
    # Get nProc
    nProc = getnProc(caseLocation)
    # Binning info
    #nBins = 100
    min, max = findMinMaxU(caseLocation,nProc,time)
    #print("Min:", min) 
    #print("Max:", max)
    comp = 0
    minc = min[comp]
    maxc = max[comp]
    dx = (maxc-minc)/nBins
    # Initialize counting
    nCells = 0 
    hist = np.zeros((nBins,))

    for proc in range(0,nProc):
        print("Time:",time,"Processor:",proc)
        U = loadU_SingleProc(caseLocation,proc,time)
        #print(U)
        hist_ = np.histogram(U[:,comp],nBins,(minc,maxc))
        hist = hist + hist_[0]
        nCells_ = np.size(U[:,comp])
        nCells = nCells + nCells_

    bins = 0.5*(hist_[1][0:-1]+ hist_[1][1:])
    #print(hist)

    #plt.bar(bins,hist,width=dx,edgecolor="black")
    #plt.xlabel("U")
    #plt.title("Time:"+str(time))

    if save:
        fn = caseLocation + "/" + str(time) + '.txt' #.png'
        #plt.savefig(fn,bbox_inches='tight')
        binsrs = np.reshape(bins,(nBins,1))
        histrs = np.reshape(hist,(nBins,1))
        np.savetxt(fn,np.hstack((binsrs,histrs)))
    #if show:
        #plt.show()
    #plt.close()

def getTimeList(caseLocation):
    timeLocation = caseLocation + "/processor0"
    ldir = len(timeLocation)
    timeList=[]
    #for x in os.listdir(timeLocation):
    for root, dirs, files in os.walk(timeLocation):
        #print(files)
        if 'U' in files:
            t = root[ldir+1:]
            if int(t) > 2 and int(t[-2:])>0:
                timeList.append(t)
    #print(timeList)
    return timeList

#caseLocation = "/home/brittany/sedTransp/viewPolyDilute/px1-0"
caseLocation = "/expanse/lustre/scratch/bshepherd/temp_project/p125"

# Proc/time info
timeList = ["2616"] #getTimeList(caseLocation)
timeList = ["2698","2804","2960"]
timeList = ["3136","3477"]
timeList = ["4122","4606","4916"]
timeList = ["5211","5296","5319","5682"]
nBins=100
comp = 0
show = False
save = True
getTimeList(caseLocation)

for time in timeList:
    print("Current time:",time)
    makeHistU(nBins,comp,caseLocation,time,show,save)
