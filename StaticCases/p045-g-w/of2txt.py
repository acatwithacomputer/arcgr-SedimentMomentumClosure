import numpy as np
#from mpi4py.futures import MPIPoolExecutor
import multiprocessing as mp
import os

# Read file (proc, time, filename)
def loadField_SingleProc(caseLocation,proc,time,fieldfn,isVector):
    fn = caseLocation + "/processor" + str(proc) + "/" + str(time) + "/" + fieldfn
    f = open(fn,"r")
    # Get number of cells
    for i in range(0,20):   #Loop to get to line 20
        line = f.readline()
    nCells = int(line)
    #print("Number of cells:", nCells)
    # Skip the parenthesis line
    line = f.readline()

    if isVector:
        # Initialize U
        field = np.zeros((nCells,3))
        # Loop through cells
        for i in range(0,nCells):
            line = f.readline()     # Read line
            field[i,:] = np.fromstring(line[1:-2],sep=" ") # Str 2 array
    else:
        # Initialize V
        field = np.zeros((nCells,1))
        # Loop through cells
        for i in range(0,nCells):
            line = f.readline()     # Read line
            field[i] = line # Str 2 array

    return field

# Get time list
def getTimeList(caseLocation):
    timeLocation = caseLocation + "/processor1"
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

# Get number of procs
def getnProc(caseLocation):
    procList=[]
    for x in os.listdir(caseLocation):
        if x.startswith("processor"):
            # Prints only text file present in My Folder
            procList.append(x)
    nProc=len(procList)
    #print(ng)
    return nProc

# Collect data
def collectData(index):
    # Reconstruct info from index
    caseLocation, timeList, nProc = getCaseInfo()
    proc = np.mod(index,nProc)
    ti = int((index-proc)/nProc)
    time = timeList[ti]
    #print(index,"Proc: ",proc,"Time index:",ti, "Time:", time)
    # Create data list
    C = loadField_SingleProc(caseLocation,proc,time,"C",isVector=True)  # Load centers
    Npts = len(C[:,0])                                                  # Gen Np 
    data = np.zeros((Npts,7))                                           # Initialize proc list  
    data[:,0:3] = C                                                     # Centers -> proc list 
    V = loadField_SingleProc(caseLocation,proc,time,"V",isVector=False) # Read cell volumes (recycle) 
    data[:,3] = np.reshape(V,(Npts,))                                                       # Volumes -> proc list 
    U = loadField_SingleProc(caseLocation,proc,time,"U",isVector=True)  # Read velocities (recycle) 
    data[:,4:] = U                                                      # Velocities -> proc list 
    #Write proclist in proc folder 
    fn = "/" + time + "-" + str(proc) + ".txt"
    procLocation = caseLocation + "/processor" + str(proc)
    np.savetxt(procLocation + fn,data,delimiter=",")
    return 0

def getCaseInfo():
    #caseLocation = "/home/brittany/sedTransp/viewPolyDilute/px1-0"
    caseLocation = "/expanse/lustre/scratch/bshepherd/temp_project/p045-w"
    timeList = getTimeList(caseLocation)
    nProc = getnProc(caseLocation)
    return caseLocation, timeList, nProc

# Main function
if __name__ == "__main__":
    caseLocation, timeList, nProc = getCaseInfo()
    n = nProc*len(timeList)
    procList = range(0,nProc)
    n = nProc*len(timeList)
    #print(timeList)
    #for i in range(0,n):
    #    collectData(i)
    #    proc = np.mod(i,nProc)
    #    ti = int((i-proc)/nProc)
    #    time = timeList[ti]
    #    print(i,"Proc: ",proc,"Time index:",ti, "Time:", time)
        #time = timeList[i]
        #print(time,proc)
    runProcs = 128
    pool = mp.Pool(runProcs)
    allInt = pool.map(collectData,[tsi for tsi in range(0,n)])
            #collectData(proc,time)
    
    # Mpi4py
    #with MPIPoolExecutor() as executor:
    ##    results = executor.map(collectData, procList,timeList)
    #    results = executor.map(collectData, [tsi for tsi in range(0,n)])
