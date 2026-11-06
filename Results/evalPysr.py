import numpy as np
np.bool = np.bool_
import matplotlib.pyplot as plt
from pysr import PySRRegressor
from post.dataio import collectDataAcrossGValues
from post.fitR import *

########################################################################
########################################################################
###         PySR functions
########################################################################
########################################################################
  
def classicalChoices(measures, linset):
    es = measures[:,0]
    ew = 1.0-es

    x0 = measures[:,0]
    x1 = measures[:,1]
    x2 = measures[:,2]
    x3 = 1.0-x0

    nd = len(es)
    unit = np.ones(np.shape(es))

    # Linear coefficient
    c1 = np.array([1, 2, 3, 4, 5, 6])
    nc = len(c1)
    q1 = np.zeros((nd,nc))
    x1sq = np.multiply(x1,x1)
    # Wen and Yu linear coefficient
    q1[:,0] = 150*np.divide(np.multiply(es,es),ew)
    # Chosen PySR coefficients
    # Chosen case 1: y = (x₁ * x₁) * x₀
    q1[:,1] = np.multiply(x0,np.power(x1,2))
    # Chosen case 2: y = (44.478 ^ x₀) * x₁
    q1[:,2] = np.multiply(x1,np.power(44.5,x0))
    # Chosen case 3: y = ((x₀ * 166.75) / x₃) * x₀
    q1[:,3] = 167*np.divide(np.power(x0,2),x3)

    # Second coefficient
    c2 = np.array([1, 2, 3, 4, 5, 6])
    nc = len(c2)
    q2 = np.zeros((nd,nc))
    x0sq = np.multiply(x0,x0)
    # Wen and Yu quadratic coefficient
    q2[:,0] = 1.75*es
    
    #Old version
    # Chosen case 1: y = es^ew
    #q2[:,1] = np.power(x0,x3)
    # y = x₀ + (0.20335 / (x₀ + ((7.6702 ^ x₂) / (x₁ ^ x₁))))
    f1 = np.power(x1,x1)
    f2 = np.power(7.6702, x2)
    f3 = x0 + np.divide(f2,f1)
    q2[:,1] = x0 + np.divide(0.20335,f3)
    # Chosen case 2: y = 1.5312*es
    #q2[:,2] = 1.5312*x0
    q2[:,2] = 1.5224*x0
    # Chosen case 3: y = es^2 + es
    q2[:,3] = np.multiply(x0,x0+1)

    return q1, q2, c1, c2


########################################################################
########################################################################
###         PySR functions
########################################################################
########################################################################

def justRe(dataLocation,Vw,smd,nu):
    gRange = getng(dataLocation)
    volData, surfData = collectDataAcrossGValues(gRange,dataLocation)
    vaw  = volData[:,0]/Vw
    vRe, sRe = computeRe(vaw,smd,nu)
    Re = vRe
    Resq = np.multiply(-vRe,sRe)
    return Re, Resq

def justReDense(base):
    # Load parameters
    L,Vbox,Vwa,Vwn,Awsn = loadMicroscaleDomainInfo(base)
    Vs = Vbox-Vwn   # Volume of the solid phase
    smd = 6*Vs/Awsn  # Sauter Mean Diameter
    riw= .001
    nu = 100
    # Get the Re only
    Re, Resq = justRe(base,Vwn,smd,nu)
    return Re, Resq

def pysrErr(xc,xp):
    err = abs(xc-xp)/xc*100
    return sf(err)

def prepForPlot(casei,complexityi,base,q1,q2,Rquad):
    print("Check case:",labels[casei,0])
    Re, Resq = justReDense(base)
    Rfit = Rquad[casei,0]*Re + Rquad[casei,1]*Resq
    pysr = q1[casei,complexityi]*Re + q2[casei,complexityi]*Resq
    return Re, Rfit, pysr

def viewPairs(dataLocation, labels, q1, q2, Rquad):
    # p125
    complexityi = 2
    casei = 27
    base = dataLocation+labels[casei,0]
    Re_125, R_125, pysr_125 = prepForPlot(casei,complexityi,base,q1,q2,Rquad)

    # p125-cv
    casei = 38
    base = dataLocation+labels[casei,0]
    Re_125cv, R_125cv, pysr_125cv = prepForPlot(casei,complexityi,base,q1,q2,Rquad)

    fig, ax = plt.subplots()
    f125f, = ax.plot(-Re_125,-R_125,'o',label='Fitted p125')
    f125p, = ax.plot(-Re_125,-pysr_125,'x',label="pysr p125")
    f125cvf, = ax.plot(-Re_125cv,-R_125cv,'o',label='Fitted p125-cv')
    f125cvp, = ax.plot(-Re_125cv,-pysr_125cv,'x',label="pysr p125-cv")
    #fli, = ax.plot(sRe,Kl*sRe,'x',label='linear')
    ax.set_xlabel('Re')
    ax.set_ylabel('LHS')
    ax.legend(handles=[f125f,f125p,f125cvf,f125cvp],loc='upper left')
    plt.show()

def evalAllPts(dataLocation):
    ################################################
    ### PREPARE MONODISPERSE DILUTE CASES
    # Prepare R values for monodisperse dilute cases
    R_, err, measures, labels, candidates = loadAllData(dataLocation)
    Rlin  = R_[:,0]
    Rquad = R_[:,1:3]

    q1, q2, c1 ,c2 = classicalChoices(measures,candidates)

    # Print linear coefficient
    #print(Rquad[:,0],q1)
    nP = len(Rquad[:,0])
    nq1 = len(q1[0,:])
    # Compute overall errors
    oaerrprint = "Overall errors: "
    oaerr = np.zeros((2,nq1))
    for i in range(0,nq1):
        e,e1r = computeL2Error(q1[:,i],Rquad[:,0])
        oaerr[0,i] = e1r
        oaerrprint = oaerrprint + sf(e1r) + "% "

    print("***************************************************************************")
    print("Evaluation of linear coefficient")
    print("First element is PySR evaluation, second is relative error for that case.")
    print(oaerrprint)
    title = " Case  |Comp. R1|"
    for j in range(0,nq1):
        title = title + "| PySR "+str(j)+" compl. "+str(c1[j]) + " |"
    print(title)
    for i in range(0,nP):
        printme = labels[i,1]+"|"+sf(Rquad[i,0]) + "|"
        for j in range(0,nq1):
            qij = q1[i,j]
            printme = printme + "|"+sf(qij) + "|" + pysrErr(Rquad[i,0],qij)+"|"
        print(printme)

    print("***************************************************************************")
    # Print quadratic coefficient
    #print(Rquad[:,1],q2)
    nP = len(Rquad[:,1])
    nq2 = len(q2[0,:])
    # Compute overall errors
    oaerrprint = "Overall errors: "
    for i in range(0,nq2):
        e,e1r = computeL2Error(q2[:,i],Rquad[:,1])
        oaerr[1,i] = e1r
        oaerrprint = oaerrprint + sf(e1r) + "% "
    print("Evaluation of quadratic coefficient")
    print("First element is PySR evaluation, second is relative error for that case.")
    print(oaerrprint)

    title = " Case  |Comp. R1|"
    for j in range(0,nq2):
        title = title + "| PySR "+str(j)+" compl. "+str(c1[j]) + " |"
    print(title)
    for i in range(0,nP):
        printme = labels[i,1]+"|"+sf(Rquad[i,1]) + "|"
        for j in range(0,nq2):
            qij = q2[i,j]
            printme = printme + "|"+sf(qij) + "|" + pysrErr(Rquad[i,1],qij)+"|"
        print(printme)

    viewPairs_ = False
    #plot2 = False 
    plot2 = True
    if viewPairs_:
        viewPairs(dataLocation, labels, q1, q2, Rquad)
    if plot2:
        complexityi = 0
        nComplex = len(q1[0,:])
        mono_ = range(0,14)
        podi_ = range(14,26)
        pdmd_ = range(26,38)
        pmcv_ = [38, 39]

        fig, axs = plt.subplots(nrows=2,ncols=nComplex)
        for complexityi in range(0,nComplex):
            nref = 11
            refp_ = range(-3,(-3+nref))
            ref_ = np.power(2.0*np.ones((nref)),np.array(refp_))
            mono_ = range(0,14)
            podi_ = range(14,26)
            pdmd_ = range(26,38)
            pmcv_ = [38, 39]
            ref, = axs[0,complexityi].loglog(ref_,ref_,'--',label='Reference')
            monol, = axs[0,complexityi].loglog(Rquad[mono_,0],q1[mono_,complexityi],'o',label='MonoDilute')
            podil, = axs[0,complexityi].loglog(Rquad[podi_,0],q1[podi_,complexityi],'o',label='PolyDilute')
            pdmdl, = axs[0,complexityi].loglog(Rquad[pdmd_,0],q1[pdmd_,complexityi],'o',label='Dense and mid es')
            pmcvl, = axs[0,complexityi].loglog(Rquad[pmcv_,0],q1[pmcv_,complexityi],'o',label='Cross validation')
            if complexityi < 1:
                axs[0,complexityi].set_title('Comparison, '+ sf(oaerr[0,complexityi]) +'%')
            else:
                axs[0,complexityi].set_title('PySR linear coeff., '+ sf(oaerr[0,complexityi]) +'%')
            #if complexityi < 1:
            #    axs[0,complexityi].set_xlabel('Observed')
            if complexityi < 1:
                axs[0,complexityi].set_ylabel('Predicted')
            axs[0,complexityi].legend(handles=[monol,podil,pdmdl,pmcvl],loc='lower right')
            #plt.show()
            axs[0,complexityi].grid(visible=True,axis="both",color='0.9',linestyle="--")

            #fig, ax = plt.subplots()
            nref = 13
            base = -12
            refp_ = range(base,(base+nref))
            ref_ = np.power(2.0*np.ones((nref)),np.array(refp_))
            ref, = axs[1,complexityi].loglog(ref_,ref_,'--',label='Reference')
            monol, = axs[1,complexityi].loglog(Rquad[mono_,1],q2[mono_,complexityi],'o',label='MonoDilute')
            podil, = axs[1,complexityi].loglog(Rquad[podi_,1],q2[podi_,complexityi],'o',label='PolyDilute')
            pdmdl, = axs[1,complexityi].loglog(Rquad[pdmd_,1],q2[pdmd_,complexityi],'o',label='Dense and mid es')
            pmcvl, = axs[1,complexityi].loglog(Rquad[pmcv_,1],q2[pmcv_,complexityi],'o',label='Cross validation')
            #axs[1,complexityi].set_title('Quadratic coefficient, '+ sf(oaerr[1,complexityi]) +'%')
            if complexityi < 1:
                axs[1,complexityi].set_title('Comparison, '+ sf(oaerr[1,complexityi]) +'%')
            else:
                axs[1,complexityi].set_title('PySR quad. coeff., '+ sf(oaerr[1,complexityi]) +'%')
            
            axs[1,complexityi].set_xlabel('Observed')
            if complexityi < 1:
                axs[1,complexityi].set_ylabel('Predicted')
            axs[1,complexityi].legend(handles=[monol,podil,pdmdl,pmcvl],loc='lower right')
            axs[1,complexityi].grid(visible=True,axis="both",color='0.9',linestyle="--")
        
        plt.show()

def evalMidDns(dataLocation):
    ################################################
    ### PREPARE MONODISPERSE DILUTE CASES
    # Prepare R values for monodisperse dilute cases
    R_, err_, measures_, labels_, candidates_ ,gunit= loadAllData(dataLocation)
    middenseonly = range(-20,0)
    #middenseonly = range(-5,0) 
    walkonly = range(-6,0)
    Rlin  = R_[middenseonly,0]
    Rquad = R_[middenseonly,1:3]
    measures = measures_[middenseonly,:]
    err = err_[middenseonly,:]
    labels = labels_[middenseonly,:]
    candidates = candidates_[middenseonly,:]
    linset = 2

    q1, q2, c1 ,c2 = classicalChoices(measures,candidates,linset)

    print("***************************************************************************")
    print("Walk only L2 errors")
    print(Rquad[walkonly])
    print(q1[walkonly])
    print(" Linear Coefficient on walk data")
    print("Traditional model:",computeL2Error(Rquad[walkonly,0],q1[walkonly,0])[1])
    nLin = np.size(q1[0,:])
    for linOpt in range(0,nLin):
        print("PySR",linOpt,"model:",computeL2Error(Rquad[walkonly,0],q1[walkonly,linOpt])[1])
    print(" Quadratic Coefficient on walk data")
    nQud = np.size(q2[0,:])
    print("Traditional model:",computeL2Error(Rquad[walkonly,1],q2[walkonly,0])[1])
    for qudOpt in range(0,nQud):
        print("PySR",qudOpt,"model:",computeL2Error(Rquad[walkonly,1],q2[walkonly,qudOpt])[1])
    #print("PySR 2 model:",computeL2Error(Rquad[walkonly,1],q2[walkonly,2])[1])
    #print("PySR 3 model:",computeL2Error(Rquad[walkonly,1],q2[walkonly,3])[1])

    # Print linear coefficient
    #print(Rquad[:,0],q1)
    nP = len(Rquad[:,0])
    nq1 = len(q1[0,:])
    # Compute overall errors
    oaerrprint = "Overall errors: "
    oaerr = np.zeros((2,nq1))
    for i in range(0,nq1):
        e,e1r = computeL2Error(q1[:,i],Rquad[:,0])
        oaerr[0,i] = e1r
        oaerrprint = oaerrprint + sf(e1r) + "% "

    print("***************************************************************************")
    print("Evaluation of linear coefficient")
    print("First element is PySR evaluation, second is relative error for that case.")
    print(oaerrprint)
    #title = " Case  |Comp. R1|"
    #for j in range(0,nq1):
    #    title = title + "| PySR "+str(j)+" compl. "+str(c1[j]) + " |"
    #title = " Case  |Comp. R1|| PySR 0 compl. 1 || PySR 1 compl. 2 || PySR 2 compl. 3 || PySR 3 compl. 4 |"
    title = " Case  |Comp. R1||   Trad. Model   ||   Simple Model  ||  Closed Two Pt  ||  Plain Two Pt   |"
    print(title)
    for i in range(0,nP):
        printme = labels[i,1]+"|"+sf(Rquad[i,0]) + "|"
        for j in range(0,nq1):
            qij = q1[i,j]
            printme = printme + "|"+sf(qij) + "|" + pysrErr(Rquad[i,0],qij)+"|"
        print(printme)

    print("***************************************************************************")
    # Print quadratic coefficient
    #print(Rquad[:,1],q2)
    nP = len(Rquad[:,1])
    nq2 = len(q2[0,:])
    # Compute overall errors
    oaerrprint = "Overall errors: "
    for i in range(0,nq2):
        e,e1r = computeL2Error(q2[:,i],Rquad[:,1])
        oaerr[1,i] = e1r
        oaerrprint = oaerrprint + sf(e1r) + "% "
    print("Evaluation of quadratic coefficient")
    print("First element is PySR evaluation, second is relative error for that case.")
    print(oaerrprint)

    title = " Case  |Comp. R1|"
    for j in range(0,nq2):
        title = title + "| PySR "+str(j)+" compl. "+str(c1[j]) + " |"
    print(title)
    for i in range(0,nP):
        printme = labels[i,1]+"|"+sf(Rquad[i,1]) + "|"
        for j in range(0,nq2):
            qij = q2[i,j]
            printme = printme + "|"+sf(qij) + "|" + pysrErr(Rquad[i,1],qij)+"|"
        print(printme)

    viewPairs_ = False
    #plot2 = False 
    plot2 = True
    if viewPairs_:
        viewPairs(dataLocation, labels, q1, q2, Rquad)
    if plot2:
        complexityi = 0
        nComplex = len(q1[0,:])
        pdmd_ = range(0,12)
        pmcv_ = [12, 13]

        fig, axs = plt.subplots(nrows=2,ncols=nComplex)
        for complexityi in range(0,nComplex):
            nref = 6
            nbase = 3
            refp_ = range(nbase,(nbase+nref))
            ref_ = np.power(2.0*np.ones((nref)),np.array(refp_))
            ref, = axs[0,complexityi].loglog(ref_,ref_,'--',label='Reference')
            pdmdl, = axs[0,complexityi].loglog(Rquad[pdmd_,0],q1[pdmd_,complexityi],'o',label='Dense and mid es')
            pmcvl, = axs[0,complexityi].loglog(Rquad[pmcv_,0],q1[pmcv_,complexityi],'o',label='Cross validation')
            if complexityi < 1:
                axs[0,complexityi].set_title('Comparison, '+ sf(oaerr[0,complexityi]) +'%')
            else:
                axs[0,complexityi].set_title('PySR linear coeff., '+ sf(oaerr[0,complexityi]) +'%')
            #if complexityi < 1:
            #    axs[0,complexityi].set_xlabel('Observed')
            if complexityi < 1:
                axs[0,complexityi].set_ylabel('Predicted')
            axs[0,complexityi].legend(handles=[pdmdl,pmcvl],loc='lower right')
            #plt.show()
            axs[0,complexityi].grid(visible=True,axis="both",color='0.9',linestyle="--")

            #fig, ax = plt.subplots()
            nref = 3
            base = -2
            refp_ = range(base,(base+nref))
            ref_ = np.power(2.0*np.ones((nref)),np.array(refp_))
            ref, = axs[1,complexityi].loglog(ref_,ref_,'--',label='Reference')
            pdmdl, = axs[1,complexityi].loglog(Rquad[pdmd_,1],q2[pdmd_,complexityi],'o',label='Dense and mid es')
            pmcvl, = axs[1,complexityi].loglog(Rquad[pmcv_,1],q2[pmcv_,complexityi],'o',label='Cross validation')
            #axs[1,complexityi].set_title('Quadratic coefficient, '+ sf(oaerr[1,complexityi]) +'%')
            if complexityi < 1:
                axs[1,complexityi].set_title('Comparison, '+ sf(oaerr[1,complexityi]) +'%')
            else:
                axs[1,complexityi].set_title('PySR quad. coeff., '+ sf(oaerr[1,complexityi]) +'%')
            
            axs[1,complexityi].set_xlabel('Observed')
            if complexityi < 1:
                axs[1,complexityi].set_ylabel('Predicted')
            axs[1,complexityi].legend(handles=[pdmdl,pmcvl],loc='upper left')
            axs[1,complexityi].grid(visible=True,axis="both",color='0.9',linestyle="--")
        
        plt.show()

def comparisonLinear(code):
    R,err,measures = loadWalkData(dataLocation,code)
    print("R",R[0,:])
    print("Fit relative error: "+sf(err[0,1])+"%")
    print("Measures",measures)

    x0 = measures[0]
    x1 = measures[1]
    x2 = measures[2]
    x3 = 1.0-x0

    q1 = 150*np.divide(np.multiply(x0,x0),x3)
    print("Traditional model:",sff(abs(q1-R[0,1])/R[0,1]*100), "%")

    q1_=np.multiply(x0,np.power(x1,2))
    den = np.multiply(np.power(x0,2),x1)
    x7_ = np.power(np.divide(.01*x2,den),x3)
    q1 = 0.29068*np.divide(q1_,x7_)
    print("New model: ",sff(abs(q1-R[0,1])/R[0,1]*100),"%")

def loadAllpts(dataLocation):
    letter=getAllCodes()
    nWalk = 0
    nDilute = 0
    
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
            vRe,sRe,lhs,tstar_,gunit = prepForFit(volData, surfData,smd,rho,mu,Vw,Vbox,L,ng,isDilute,principalOnly=True,caseLocation=caseLocation)
            Rlin, errL, Rquad, errQ = completeQuadraticFit(vRe,sRe,lhs)

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

            # Compute Predicted
            #candidates_ = prepCandidates(dataLocation,code)
            #lc = len(candidates_)
            #if lc < 6:
            #    candidates__ = np.append(candidates_,[0],axis=0)
            #    candidates_ = candidates__
            #    lc = lc+1
            #candidates_ = np.reshape(candidates_,(1,lc))
            measures_ = np.reshape(measures_,(1,3))
            #linset = 2
            linset = 6
            q1,q2,c1,c2 = classicalChoices(measures_, linset)
            nLin  = np.size(q1)
            nQuad = np.size(q2)
            nRe   = np.size(sRe)
            #print(q1)
            R1_ = np.zeros((nRe,nLin+1))
            R2_ = np.zeros((nRe,nQuad+1))

            for m in range(0,nLin):
                R1_[:,m]  = q1[0,m]*vRe
            for m in range(0,nQuad):
                R2_[:,m] = q2[0,m]*np.multiply(vRe,sRe)

            R1_[:,-1] = Rquad[0,0]*vRe
            R2_[:,-1] = Rquad[1,0]*np.multiply(vRe,sRe)
            
            # Save the info
          
            if i<1 and j<1:
                #print("size",np.shape(R1_))
                tstar = tstar_
                R1 = R1_
                R2 = R2_
                gpterm = lhs - tstar_
                print( "Case | Min Re | Max Re |")
            else:
                #print("size",np.shape(R1_))
                if nWalk < 1 and code[-1] == 'w':
                    nWalk = np.size(tstar)
                if nDilute < 1 and not isDilute:
                    nDilute = np.size(tstar)
                tstar = np.append(tstar,tstar_,axis=0)
                R1 = np.append(R1,R1_,axis=0)
                R2 = np.append(R2,R2_,axis=0)
                gpterm = np.append(gpterm,lhs-tstar_,axis=0)


            #print(code," Linear K: ",Kl, " with residual ", Rl, " and Quadratic K: ",Kq, " with residual ", Rq)
            #print(code, "Min Re: ", sff(np.min(sRe)), ", and max Re:", np.max(sRe))            
            print(labels_,"|",sff(np.min(sRe)),"|",sff(np.max(sRe)),"|")

    return tstar, R1, R2, gpterm, nWalk, nDilute

laptop = True

if laptop:
    dataLocation = "./results/"
    nProc=4
    nIter=100
else:
    dataLocation = "/work/users/b/r/breizh/pysr/results/"
    nProc=16
    nIter=10000

#evalAllPts(dataLocation)
#evalMidDns(dataLocation)

print("***************************************")
print("***************************************")
print("***************************************")
tstar, R1, R2, gpterm, nWalk, nDilute = loadAllpts(dataLocation)
#R_,res_,measures,labels, gpt = loadAllData(dataLocation)
#gpterm = gpterm
traditional = R1[:,0] + R2[:,0] #- gpterm
#print(np.shape(R1))
#print(np.shape(R2))
print("Number of walk points",np.shape(tstar[nWalk:]))
nLin = np.size(R1[0,:])-2
nQud = np.size(R2[0,:])-2

print("***************************************")
print("Overall error on all points")
print("Trad model:",sf(computeL2Error(tstar[nWalk:],traditional[nWalk:])[1]),"%")
print("---------------------------------")
print("| L | Q |   Walk    |    All    |")
print("---------------------------------")
for linOpt in range(1,nLin-1):
    for qudOpt in range(1,nQud-1):
        predicted   = R1[:,linOpt] + R2[:,qudOpt] - gpterm
        print("|",linOpt,"|", qudOpt,"|", sf(computeL2Error(tstar[nWalk:],predicted[nWalk:])[1]),"%|",sf(computeL2Error(tstar[:],predicted[:])[1]),"%|")
    print("---------------------------------")
print("L - Linear option")
print("Q - Quadratic option")
print("Walk - Relative error over walk data")
print("All  - Relative error over all data")
print("****************************************************")
print("Error over increasing Re")

predicted1 = R1[:,2] + R2[:,3] - gpterm
predicted2 = R1[:,3] + R2[:,3] - gpterm
ref = np.linspace(1e-2,5e5,100)

bothcases = True
linedup = False
if bothcases:
    fs=30
    tickfs= 25
    legfs=25
    markersize=15
    markerscale=3
    if linedup:
        fig, axs = plt.subplots(nrows=1,ncols=3)
        tradRef,  = axs[0].loglog(ref,ref,'k--')
        tradDil,  = axs[0].loglog(np.abs(tstar[0:nDilute]),np.abs(traditional[0:nDilute]),'o',label="Two Sphere Data")
        tradMdd,  = axs[0].loglog(np.abs(tstar[nDilute:nWalk]),np.abs(traditional[nDilute:nWalk]),'o',label="Midrange/Dense Data")
        tradWalk, = axs[0].loglog(np.abs(tstar[nWalk:]),np.abs(traditional[nWalk:]),'*',label="Validation")
        # Combination 1 subplot
        pred1Ref,  = axs[1].loglog(ref,ref,'k--')
        pred1Dil,  = axs[1].loglog(np.abs(tstar[0:nDilute]),np.abs(predicted1[0:nDilute]),'o',label="Two Sphere Data")
        pred1Mdd,  = axs[1].loglog(np.abs(tstar[nDilute:nWalk]),np.abs(predicted1[nDilute:nWalk]),'o',label="Midrange/Dense Data")
        pred1Walk, = axs[1].loglog(np.abs(tstar[nWalk:]),np.abs(predicted1[nWalk:]),'*',label="Validation")
        # Combination 2 subplot
        pred2Ref,  = axs[2].loglog(ref,ref,'k--')
        pred2Dil,  = axs[2].loglog(np.abs(tstar[0:nDilute]),np.abs(predicted2[0:nDilute]),'o',label="Two Sphere Data")
        pred2Mdd,  = axs[2].loglog(np.abs(tstar[nDilute:nWalk]),np.abs(predicted2[nDilute:nWalk]),'o',label="Midrange/Dense Data")
        pred2Walk, = axs[2].loglog(np.abs(tstar[nWalk:]),np.abs(predicted2[nWalk:]),'*',label="Validation")

        axs[0].set_title('Traditional',fontsize=fs+5)
        axs[1].set_title('Combination 1',fontsize=fs+5)
        axs[2].set_title('Combination 2',fontsize=fs+5)
        
        # Set axis label info (identical for all subplots)
        axs[0].set_ylabel('Predicted',fontsize=fs)
        for sp in range(0,3):
            #axs[sp].set_ylabel('Predicted',fontsize=fs)
            axs[sp].set_xlabel('Observed',fontsize=fs)
            axs[sp].tick_params(axis='both', which='major', labelsize=tickfs)

        # Set legends
        axs[0].legend(handles=[tradDil,tradMdd,tradWalk],loc='lower right',fontsize=legfs,markerscale=markerscale)
        axs[1].legend(handles=[pred1Dil,pred1Mdd,pred1Walk],loc='lower right',fontsize=legfs,markerscale=markerscale)
        axs[2].legend(handles=[pred2Dil,pred2Mdd,pred2Walk],loc='lower right',fontsize=legfs,markerscale=markerscale)
    else:
        # Traditional plot
        fig, ax = plt.subplots()
        tradRef,  = ax.loglog(ref,ref,'k--')
        tradDil,  = ax.loglog(np.abs(tstar[0:nDilute]),np.abs(traditional[0:nDilute]),'o',label="Two Sphere Data")
        tradMdd,  = ax.loglog(np.abs(tstar[nDilute:nWalk]),np.abs(traditional[nDilute:nWalk]),'o',label="Midrange/Dense Data")
        tradWalk, = ax.loglog(np.abs(tstar[nWalk:]),np.abs(traditional[nWalk:]),'*',label="Validation")
        #ax.set_title('Traditional',fontsize=fs+5)
        ax.set_ylabel('Predicted',fontsize=fs)
        ax.set_xlabel('Observed',fontsize=fs)
        ax.tick_params(axis='both', which='major', labelsize=tickfs)
        ax.legend(handles=[tradDil,tradMdd,tradWalk],loc='lower right',fontsize=legfs,markerscale=markerscale)
        plt.show()

        # Combination 1 subplot
        fig, ax = plt.subplots()
        pred1Ref,  = ax.loglog(ref,ref,'k--')
        pred1Dil,  = ax.loglog(np.abs(tstar[0:nDilute]),np.abs(predicted1[0:nDilute]),'o',label="Two Sphere Data")
        pred1Mdd,  = ax.loglog(np.abs(tstar[nDilute:nWalk]),np.abs(predicted1[nDilute:nWalk]),'o',label="Midrange/Dense Data")
        pred1Walk, = ax.loglog(np.abs(tstar[nWalk:]),np.abs(predicted1[nWalk:]),'*',label="Validation")
        #ax.set_title('Combination 1',fontsize=fs+5)
        ax.set_ylabel('Predicted',fontsize=fs)
        ax.set_xlabel('Observed',fontsize=fs)
        ax.tick_params(axis='both', which='major', labelsize=tickfs)
        ax.legend(handles=[pred1Dil,pred1Mdd,pred1Walk],loc='lower right',fontsize=legfs,markerscale=markerscale)
        plt.show()

        # Combination 2 subplot
        fig, ax = plt.subplots()
        pred2Ref,  = ax.loglog(ref,ref,'k--')
        pred2Dil,  = ax.loglog(np.abs(tstar[0:nDilute]),np.abs(predicted2[0:nDilute]),'o',label="Two Sphere Data")
        pred2Mdd,  = ax.loglog(np.abs(tstar[nDilute:nWalk]),np.abs(predicted2[nDilute:nWalk]),'o',label="Midrange/Dense Data")
        pred2Walk, = ax.loglog(np.abs(tstar[nWalk:]),np.abs(predicted2[nWalk:]),'*',label="Validation")
        #ax.set_title('Combination2',fontsize=fs+5)
        ax.set_ylabel('Predicted',fontsize=fs)
        ax.set_xlabel('Observed',fontsize=fs)
        ax.tick_params(axis='both', which='major', labelsize=tickfs)
        ax.legend(handles=[pred2Dil,pred2Mdd,pred2Walk],loc='lower right',fontsize=legfs,markerscale=markerscale)
        plt.show()
else:
    fig, axs = plt.subplots()
    fs=30
    tickfs= 25
    legfs=25
    markersize=15


    #tstar = np.multiply(np.sign(tstar),tstar)
    #predicted = np.multiply(np.sign(predicted),predicted)

    predRef,  = axs.loglog(ref,ref,'k--')
    predAll,  = axs.loglog(tstar[0:nWalk],predicted[0:nWalk],'o',label="Parent data",markersize=markersize)
    predWalk, = axs.loglog(tstar[nWalk:],predicted[nWalk:],'*',label="Validation",markersize=markersize)


    #plt.rcParams['text.usetex'] = True
    axs.set_ylabel('Predicted', fontsize=fs)
    axs.set_xlabel('Observed', fontsize=fs)
    axs.legend(handles=[predAll,predWalk],loc='lower right',fontsize=legfs)
    axs.tick_params(axis='both', which='major', labelsize=tickfs)
    axs.tick_params(axis='both', which='minor', labelsize=tickfs)

plt.show()

print("All data error")
print("Trad model:",computeL2Error(tstar,traditional)[1])
print("PySR model:",computeL2Error(tstar,predicted)[1])
print("Walk only error")
print("Trad model:",computeL2Error(tstar[nWalk:],traditional[nWalk:])[1])
print("PySR model:",computeL2Error(tstar[nWalk:],predicted[nWalk:])[1])

perc  = np.divide(R2[:,-1],R1[:,-1]+R2[:,-1]-gpterm)*100
tstar_ = tstar[nWalk:]
trad_ = traditional[nWalk:]
pred_ = predicted[nWalk:]
perc_ = perc[nWalk:]

perci = np.argsort(perc_)

prederr = np.array([computeL2Error(tstar_[perci[0:1]],pred_[perci[0:1]])[1]])
traderr = np.array([computeL2Error(tstar_[perci[0:1]],trad_[perci[0:1]])[1]])

for i in range(1,np.size(perci)):
    traderr = np.append(traderr,[computeL2Error(tstar_[perci[0:i]],trad_[perci[0:i]])[1]],axis=0)
    prederr = np.append(prederr,[computeL2Error(tstar_[perci[0:i]],pred_[perci[0:i]])[1]],axis=0)


"""
fig, axs = plt.subplots()
#tradWalk, = axs.plot(perc,np.abs(tstar-traditional),'o')
#predWalk, = axs.plot(perc,np.abs(tstar-predicted),'o')
#tradWalk, = axs.plot(perc_,np.abs(np.divide(tstar[nWalk:]-traditional[nWalk:],tstar[nWalk:])),'o')
tradWalk, = axs.plot(perc_[perci],traderr,'o-')
predWalk, = axs.plot(perc_[perci],prederr,'o-')
plt.show()
"""
"""
print("*********************************************")
print("p125 plucked")
comparisonLinear("p125-g")

print("*********************************************")
print("p125 even")
comparisonLinear("p125-e")

print("*********************************************")
print("p125-cv walk")
comparisonLinear("p125-e-w")

print("*********************************************")
code = "p125-g-w"
print(code)
comparisonLinear(code)

print("*********************************************")
print("p045 plucked")
comparisonLinear("p045-g")

print("*********************************************")
print("p045 walk")
comparisonLinear("p045-g-w")

print("*********************************************")
print("p145 plucked")
comparisonLinear("p145-g")

print("*********************************************")
print("p145 walk")
comparisonLinear("p145-g-w")

print("*********************************************")
print("p245 plucked")
comparisonLinear("p245-g")

print("*********************************************")
print("p245 even")
comparisonLinear("p245-e")

print("*********************************************")
print("p245 walk")
comparisonLinear("p245-e-w")
"""
print("*********************************************")
