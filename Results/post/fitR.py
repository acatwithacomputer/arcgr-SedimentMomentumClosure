import numpy as np
np.bool = np.bool_
import post.gravitationalPotential as gp
from post.dataio import collectDataAcrossGValues
import os


########################################################################
###         Parameters and loading data

def loadMicroscaleDomainInfo(caseLocation):
    nfoFile = caseLocation + "/packing.nfo"
    f = open(nfoFile,"r")
    # Get number of spheres
    line = f.readline()
    nsph = int(line[3:-1])
    #print(nsph)
    # Get box length
    line = f.readline()
    L = float(line[13:21])
    Vbox = L*L*L
    #print(L,Vbox)
    # Theoretical porosity
    line = f.readline()
    # Actual porosity
    line = f.readline()
    ew = float(line[16:23])
    Vwa = ew*Vbox

    # Get info from the volume file file
    volbase = caseLocation + "/post0/volumeIntegrals/0/volFieldValue.dat"
    f = open(volbase,"r")
    line = f.readline()
    line = f.readline()
    line = f.readline()
    line = line.replace(':','')
    line = line.replace('# Volume','')
    Vwn = float(line)
    #print((Vwa-Vwn)/Vwa*100)

    # Get info from the surface file file
    volbase = caseLocation + "/post0/surfaceIntegrals/0/surfaceFieldValue.dat"
    f = open(volbase,"r")
    line = f.readline()
    line = f.readline()
    line = f.readline()
    line = line.replace(':','')
    line = line.replace('# Area','')
    Awsn = float(line)

    return L,Vbox,Vwa,Vwn,Awsn

def loadParameters(caseCode,dataLocation=" "):
    if caseCode[0] == "m":      # If the case is monodilute
        R   = np.array([.5, .5])
        rho =1.0
        nu  = .01
        isDilute=True
        if caseCode[1] == "x":
            L = 6
            Vbox = 4.0*4.0*6.0
            configRange=4
        elif caseCode[1] == "z":
            L = 4
            Vbox = 4.0*4.0*6.0
            configRange=4
        elif caseCode[1] == "s":
            L = 6
            Vbox = 6.0*6.0*6.0
            configRange=3
        else:
            print("Pick a valid monodisperse code")
    elif caseCode[1] == "x" or caseCode[1] == "z":    
        L  = 6
        R    = np.array([0.5 ,0.25])
        Vbox  = 4.0*4.0*6.0 
        rho=1.0
        nu = .01
        isDilute = True
        configRange=4
    else:
        caseLocation = dataLocation + caseCode
        # Load parameters
        rho= .001
        nu = 100
        L,Vbox,Vwa,Vwn,Awsn = loadMicroscaleDomainInfo(caseLocation)
        Vw = Vwn
        isDilute = False
        configRange = 1
        # Load radii
        p=caseCode[1]
        es=caseCode[2:4]
        #spheresfn = dataLocation +"poly"+p+"-"+es+"Box.csv"
        spheresfn = dataLocation + caseCode + "/spheres.csv"
        spheres = np.genfromtxt(spheresfn,delimiter=",")
        R = spheres[:,-1]
    
    
    Vs    = 4.0/3.0*np.pi*(np.sum(np.power(R,3.0)))
    As    = 4.0*np.pi*(np.sum(np.power(R,2.0)))
    #print(R)
    #print(Vs)
    #print(As)

    mu = nu*rho
    Vw = Vbox-Vs
    if isDilute:
        Vwn = Vw
    es, ewsnd, Jmeas, Kmeas = computeMeasures(R,Vbox)
    #if classic:
    #    smd = sum(2*R)/len(R)
    #    measures = np.array([es, ewsnd, Jmeas, Kmeas])
    #else:
    smd = 6.0*Vs/As
    measures = np.array([es, Jmeas, Kmeas])

    
    return isDilute,configRange, rho, nu, mu, L, Vwn, Vbox, smd, measures

########################################################################
###         Compute the measures

def computeMeasures(r,Vbox):
    rsq = np.multiply(r,r)
    nsp = len(r)
    v1s = np.ones((nsp,))
    # Compute volumes
    Vsi = 4.0/3.0*np.pi*np.multiply(r,rsq)
    Vs  = np.sum(Vsi)
    # Compute areas
    Asi = 4*np.pi*rsq
    As  = np.sum(Asi)

    # Some geometry
    es = Vs/Vbox    # Volume fraction
    ews = As/Vbox   # Intrinsic area
    #if classic:
    #    smd = sum(2*r)/len(r)
    #else:
    smd = 6*Vs/As   # Sauter mean diameter
    ewsnd = ews*smd # Non dim intrinsic area 
    # note: ewsnd = 6*es

    # Mean curvature
    Jmi = 2.0*np.divide(v1s,r)
    Jma = np.sum(np.multiply(Jmi,Asi))/As
    Jmand = Jma*smd
    Jmeas = ewsnd*Jmand

    # Gaussian curvature
    Kmi = np.divide(v1s,rsq)
    Kma = np.sum(np.multiply(Kmi,Asi))/As
    Kmand = Kma*smd*smd
    Kmeas = ewsnd*Kmand

    return es, ewsnd, Jmeas, Kmeas

########################################################################
###         Prep the fits

def sff(x):
    y = '{:.2e}'.format(x)
    return float(y)

def sf(x):
    y = '{:.2e}'.format(x)
    return y


def computeGpTermExact(caseLocation,L,gpmaw,ng):
    # Load spheres
    data = np.loadtxt(caseLocation+"/spheres.csv",delimiter=',')
    x0 = data[:,0]
    r  = data[:,3]
    periodic = True
    gpma_unit = gp.computeGpma(1.0,x0,r,L,periodic)      # Compute normalized gpmaw
    gpt_unit  = gp.computeGpterm(r,1.0,x0,L,periodic)    # Compute unit gp term
    gpterm = np.zeros((ng,3))                         # Initialize gpterm
    for i in range(0,ng):                             # For each simulation
        g_ = gpmaw[i]/gpma_unit                       #   Backwards compute g approx
        g = sff(g_)                                   #   Finish reconstructing g
        gpterm[i,0] = g*gpt_unit                      #   compute gpmi term
    return gpterm, gpt_unit

def computeRe(vr,D,nu):
    rscale = D/nu
    shapevr = np.shape(vr)
    #print(len(shapevr))
    if len(shapevr)<2:
        nvr = abs(vr)
    else:
        vsq = np.sum(np.multiply(vr,vr),axis=1)
        nvr = np.sqrt(vsq)
    vRe = rscale*vr
    sRe = rscale*nvr
    return vRe,sRe

def getng(caseLocation):
    postlist=[]
    for x in os.listdir(caseLocation):
        if x.startswith("post"):
            # Prints only text file present in My Folder
            postlist.append(x)
    ng=len(postlist)
    #print(ng)
    return ng

def prepForFit(volData, surfData,smd,rho,mu,Vw,Vbox,L,ng,dilute,principalOnly,caseLocation):
    # Note: OpenFOAM normalizes by the density, but TCAT generally doesn't by default
    # Non-dimensionalization was performed using TCAT's convention, so the density is
    # factored back in to the OpenFOAM calculation here to match the TCAT convention,
    # but the resulting coefficients will be insensitive to the density. This fact can
    # and has been used as a sanity check. 
    #
    # Furthermore, the surface gravitational potential term was found to perform 
    # poorly for non-dilute cases due to equating to the difference of two large numbers 
    # (spheres entirely in the domain and the spheres cut by x=Lx) that fell within
    # numerical error, and is so replaced with an analytic calculation. The numerical
    # calculation for dilute casesperformed extremely as all spheres are in the domain,
    # so we just use OpenFOAM's calculation of the term for the dilute case.
    vaw  = volData[:,0:3]/Vw
    paw  = volData[:,3]/Vw
    gpaw = volData[:,4]/Vw
    gradun = surfData[:,0:3]/Vbox
    pns    = surfData[:,3:6]/Vbox
    gradew = surfData[:,6:9]/Vbox
    if dilute:
        gpns   = surfData[:,9:]/Vbox
        gpt_unit = 0.0
    else:
        gpns_,gpt_unit   = computeGpTermExact(caseLocation,L,gpaw*Vw,ng)
        gpns    = 0.0*gpns_/Vbox
        
    gpt_unit = gpt_unit/Vbox
    # Scaling to non-dim left hand side
    tscale = (smd**3)*rho/(mu*mu)
    gpt_unit = gpt_unit #-(1.0-Vw/Vbox)
    # Gravitational potential term
    gpterm = np.zeros(np.shape(gradew))
    gpterm[:,0]= rho*(gpns[:,0] - np.multiply(gpaw,gradew[:,0]))
    gpterm[:,1]= rho*(gpns[:,1] - np.multiply(gpaw,gradew[:,1]))
    gpterm[:,2]= rho*(gpns[:,2] - np.multiply(gpaw,gradew[:,2]))
    # Pressure term
    pterm = np.zeros(np.shape(gradew))
    pterm[:,0] = rho*np.multiply(paw,gradew[:,0])
    pterm[:,1] = rho*np.multiply(paw,gradew[:,1])
    pterm[:,2] = rho*np.multiply(paw,gradew[:,2])
    # Compute and weigh left hand side
    tstar_ = tscale*(rho*pns-mu*gradun)
    lhs_ = tstar_ + tscale*(gpterm+pterm)
    # Get Re and decide if principal direction only
    if principalOnly:
        vRe,sRe = computeRe(vaw[:,0],smd,mu/rho)
        lhs = lhs_[:,0]
        tstar = tstar_[:,0]
    else:
        lhs = lhs_
        vRe,sRe = computeRe(vaw,smd,mu/rho)
        tstar = tstar_

    return vRe, sRe, lhs, tstar, gpt_unit

def computeRstar(vRe_,sRe,lhs_):
    ts = len(sRe)
    lhsshape = np.shape(lhs_)
    if len(lhsshape) > 1:
        dim = 3
    else:
        dim = 1
    shape = (ts*dim,1)
    
    # Scale and reshape quantities
    lhs = np.reshape(lhs_,shape)
    
    # Compute Re powers
    re1 = np.reshape(vRe_,shape)
    re2_ = np.zeros((ts,dim))
    
    if dim > 1:
        for i in range(0,dim):
            re2_[:,i] = np.multiply(sRe,vRe_[:,i])
    else:
        re2_ = np.multiply(sRe,vRe_)
    re2 = np.reshape(re2_,shape)

    # Do the linear fit
    mRe = re1
    linRes = np.linalg.lstsq(mRe,lhs)
    Rlin = linRes[0][0][0]

    # Do the quadratic fit
    mRe = np.zeros((dim*ts,2))
    mRe[:,0] = np.reshape(re1,ts*dim)
    mRe[:,1] = np.reshape(re2,ts*dim)
    quadRes = np.linalg.lstsq(mRe,lhs)
    Rqud = quadRes[0]

    rlin,rqud = computeRErrors(re1,Rlin,Rqud,lhs,dim)

    return Rlin,rlin,Rqud,rqud

def completeQuadraticFit(vRe,sRe,lhs):
    # Fit quadratic and linear coefficients simultaneously
    Rlin,errL,Rquad,errQ = computeRstar(vRe,sRe,lhs)
    return Rlin, errL, Rquad, errQ

def consecutiveFits(vRe,sRe,lhs):
    # Quasi linear fit approach
    RquadSemi = np.zeros((2,1))
    
    # Restrict to linear regime
    stokes = np.less(sRe,1.0)
    sReStokes = sRe[stokes]
    ts = len(sReStokes)
    shape = (ts,1)
    vReStokes = np.reshape(vRe[stokes],shape)
    lhsStokes = np.reshape(lhs[stokes],shape)
    # Linear fit
    RlinStokes = np.linalg.lstsq(vReStokes,lhsStokes)
    Rlin = RlinStokes[0][0][0]
    RquadSemi[0,0] =RlinStokes[0][0][0]
    # Compute Error for linear fit
    observed = RquadSemi[0,0]*vRe
    expected = lhs
    err1, errL = computeL2Error(observed,expected)

    # Remove linear portion
    lhsSemi = lhs - RquadSemi[0,0]*vRe
    # Fit quadratic portion
    Resq = np.reshape(np.multiply(vRe,sRe),(len(sRe),1))
    RquadSemi_ = np.linalg.lstsq(Resq,lhsSemi)
    RquadSemi[1,0] = RquadSemi_[0][0]
    # Compute Error for quadratic fit
    observed = RquadSemi[1,0]*np.multiply(vRe,sRe)+RquadSemi[0,0]*vRe
    expected = lhs
    err1, errQ = computeL2Error(observed,expected)
    #RquadSemi[0,2] = qerr2

    return Rlin, errL, RquadSemi, errQ

########################################################################
###         Error computations functions

def computeL2Error(observed,predicted):
    diffoe = observed-predicted
    if len(np.shape(diffoe)) < 2: # Scalar 
        L2diff = np.sqrt(np.sum(np.multiply(diffoe,diffoe)))
        L2exp = np.sqrt(np.sum(np.multiply(observed,observed)))
        L2 = L2diff/len(diffoe)
        L2rel = L2diff/L2exp*100
    else:   # Vector
        L2diff = np.sqrt(np.sum(np.multiply(diffoe,diffoe)))
        L2exp = np.sqrt(np.sum(np.multiply(observed,observed)))
        length = np.product(np.shape(diffoe))
        L2 = L2diff/length
        L2rel = L2diff/L2exp*100
    return L2,L2rel

def computeRErrors(Re,Rlin,Rquad,lhs,dim):
    # Compute L2 relative error for linear fit
    rhsLin = Rlin*Re
    errLin_,errLin = computeL2Error(rhsLin,lhs)
    # Compute L2 relative error for quadratic fit
    if dim < 2:
        Resq = np.multiply(Re,abs(Re))
    else:
        Resq = np.zeros(np.shape(Re))
        nRe = np.sqrt(np.sum(np.muliply(Re,Re),axis=1))
        for i in range(0,dim):
            Resq[:,i] = np.multiply(Re[:,i],nRe)
    rhsQuad = Rquad[0,0]*Re + Rquad[1,0]*Resq
    errQuad_,errQuad = computeL2Error(rhsQuad,lhs) 
    return errLin, errQuad

########################################################################
###         Load everything

def getAllCodes():
    codes=["mx","mz","msk1-","msk2-","px1","px2","pz",
        "p025-g","p125-g","p225-g","p325-g",
        "p045-g","p145-g","p245-g","p345-e",
        "p060","p160","p260","p360",
        "p125-e","p245-e","p125-e-w","p245-e-w",
        "p125-g-w","p245-g-w",
        "p045-g-w","p145-g-w"]
    return codes

def loadAllData(dataLocation):
    letter=getAllCodes()
    labels=np.array([[]])
    
    for i in range(0, len(letter)):     # Loop through sequence cases
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
            
            #print(code)
            ng = getng(caseLocation)
            volData, surfData = collectDataAcrossGValues(ng,caseLocation)
            vRe,sRe,lhs,tstar,gpt_unit = prepForFit(volData, surfData,smd,rho,mu,Vw,Vbox,L,ng,isDilute,principalOnly=True,caseLocation=caseLocation)
            if isDilute:
                Rlin, errL, Rquad, errQ = completeQuadraticFit(vRe,sRe,lhs)
            else:
                Rlin, errL, Rquad, errQ = completeQuadraticFit(vRe,sRe,lhs)
                #Rlin, errL, Rquad, errQ = consecutiveFits(vRe,sRe,lhs)

            #if isDilute:
            #    Srw = False
            #    discLvl = 5
            #else:
            #    Srw = True
            #    discLvl=3

            # Save the label
            if len(code)<4:
                labels_ = "  "+code+"  "
            elif len(code)<5:
                labels_ = " "+code+"  "
            elif len(code)<6:
                labels_ = " "+code+" "
            elif len(code)<7:
                labels_ = code+" "
            else:
                labels_ = code
            #labels = np.append(labels,[code,labels_],axis=0)

            # Save the info
            R_ = np.array([[Rlin, Rquad[0,0], Rquad[1,0]]])
            err_ = np.array([[errL, errQ]])
            #if classic:
            #    measures_ = np.reshape(measures_,(1,4))
            #else:
            measures_ = np.reshape(measures_,(1,3))
            labels__ = np.array([[code,labels_]])
            #candidates_ = prepCandidates(dataLocation,code)
            lc = len(candidates_)
            #if lc < 6:
            #    candidates__ = np.append(candidates_,[0],axis=0)
            #    candidates_ = candidates__
            #    lc = lc+1
            candidates_ = np.reshape(candidates_,(1,lc))
            if i<1 and j<1:
                #print("size",np.size(R_))
                R = R_
                err = err_
                measures = measures_
                labels = labels__
                #candidates = candidates_
                gpt = np.array([gpt_unit])
                print( "Case | Min Re | Max Re | Err (%) | Rq")
            else:
                R   = np.append(R,R_,axis=0)
                err = np.append(err,err_,axis=0)
                measures = np.append(measures,measures_,axis=0)
                labels = np.append(labels,labels__,axis=0)
                gpt = np.append(gpt,gpt_unit)

            #print(code," Linear K: ",Kl, " with residual ", Rl, " and Quadratic K: ",Kq, " with residual ", Rq)
            #print(code, "Min Re: ", sff(np.min(sRe)), ", and max Re:", np.max(sRe))            
            print(labels_,"|",sff(np.min(sRe)),"|",sff(np.max(sRe)),"|",sff(err_[0,1]),"|",sff(Rquad[0,0]),sff(Rquad[1,0]))
            #fn = "dilute" + code + ".csv"
            #np.savetxt(fn,np.vstack((vaw[:,0],vaw[:,1],vaw[:,2],
            #                         pns[:,0]-mu*gradun[:,0],pns[:,1]-mu*gradun[:,1],pns[:,2]-mu*gradun[:,2],
            #                         pterm[:,0],pterm[:,1],pterm[:,2],
            #                         gpterm[:,0],gpterm[:,1],gpterm[:,0])).T)

    return R, err, measures,labels, gpt #candidates, gpt

def loadWalkData(dataLocation,code):
    #code = "p125-w"
    isDilute,configRange, rho, nu, mu, L, Vw, Vbox, smd, measures_ = loadParameters(code,dataLocation)
    caseLocation = dataLocation + code
    ng = getng(caseLocation)
    volData, surfData = collectDataAcrossGValues(ng,caseLocation)
    vRe,sRe,lhs = prepForFit(volData, surfData,smd,rho,mu,Vw,Vbox,L,ng,isDilute,principalOnly=True,caseLocation=caseLocation)
    Rlin, errL, Rquad, errQ = completeQuadraticFit(vRe,sRe,lhs)

    R = np.array([[Rlin, Rquad[0,0], Rquad[1,0]]])
    err = np.array([[errL, errQ]])

    return R, err, measures_
