import spherepacking
import numpy as np
import pygmsh

def computeNonDimMeasures(es,radii):
    rsq = np.multiply(radii,radii)
    Asi = 4.0*np.pi*rsq
    Vsi = 4.0/3.0*np.pi*np.multiply(rsq,radii)

    smd = 6.0*sum(Vsi)/sum(Asi)
    # Non dim ews: 
    # ews*smd = (As/Vbox)*(6*Vs/As)
    #         = 6*Vs/Vbox = 6*es
    ewss = 6.0*es
    # Non dim J
    ones = np.ones(np.shape(radii))
    Jmi  = 2.0*np.divide(ones,radii)
    Jma  = sum(np.multiply(Jmi,Asi))/sum(Asi)
    Jmas = Jma*smd
    # Non dim K
    Kmi  = np.divide(ones,rsq)
    Kma  = sum(np.multiply(Kmi,Asi))/sum(Asi)
    Kmas = Kma*smd*smd

    Jmeas = ewss*Jmas
    Kmeas = ewss*Kmas

    return ewss,Jmeas,Kmeas,smd

def makeSpherePack(radii,run_folder,out_folder):
    spheres = spherepacking.Spheres(radii.radii)
    target_es = .6

    domain = spherepacking.Domain(
        spheres=spheres,
        porosity=1.0-target_es
    )

    domain.gen_min_cube()

    packIO = spherepacking.SpherePackIO(domain,
                                        media_type = 'Spheres',
                                        run_folder = run_folder,
                                        out_folder=out_folder)

    sp = packIO.generate_sphere_pack(seed = 12, periodic=True)
    return packIO,sp

def printMeasures(es,ewss,Jmeas,Kmeas):
    border="----------------------------------"
    print(border)
    print("es : ",es)
    print("ews* : ",ewss)
    print("ews* x J* : ",Jmeas)
    print("ews* x K* : ", Kmeas)
    print(border)

def collectPrelimStats(mumin,mumax,mun,varmin,varmax,varn):
    np.random.seed(15)
    mu_  = np.linspace(mumin,mumax,mun)
    var_ = np.linspace(varmin,varmax,varn)
    Jmeas_ = np.zeros((mun,varn))
    Kmeas_ = np.zeros((mun,varn))
    smd_ = np.zeros((mun,varn))

    for i in range(0, mun):
        mu = mu_[i]
        for j in range(0, varn):
            var = var_[j]
            sig=np.sqrt(var)

            radii = spherepacking.SphereRadii(
                n = 1000,
                distribution='lognormalLHS',
                mean=mu,
                stdev=sig,
                run_folder = run_folder,
                media_type="spheres"
            )
            ewss,Jmeas,Kmeas,smd = computeNonDimMeasures(.6,radii.radii)
            Jmeas_[i,j] = Jmeas
            Kmeas_[i,j] = Kmeas
            smd_[i,j] = smd
            print(i,", ",j)

    np.savetxt("./Jmeas.txt",Jmeas_)
    np.savetxt("./Kmeas.txt",Kmeas_)
    np.savetxt("./smd.txt",smd_)
    np.savetxt("./mu.txt",mu_)
    np.savetxt("./var.txt",var_)

def generateEverything(target_r,var,nsph,run_folder,out_folder):
    target_es= .6
    # Delete sphere pack files so runs
    spherepacking.remove_dir(run_folder)

    # Determine radii distribution 
    np.random.seed(14)
    mux = target_r
    sigx=np.sqrt(var)

    radii = spherepacking.SphereRadii(
        n = nsph,
        distribution='lognormalLHS',
        mean=mux,
        stdev=sigx,
        run_folder = run_folder,
        media_type="spheres"
    )

    packIO,sp = makeSpherePack(radii,run_folder,out_folder)

    #shrinkVolumeFractionMono(packIO,sp,.45)
    # Save the packs
    packIO.save_pack_txt(sp,"uniform")
    packIO.save_pack_stl(sp,"uniform")
    packIO.save_openfoam(sp,'uniform_openfoam')

    # Shrink
    # Dimensioned quantities


    print("Measures after throwing into pack generator")
    ewss,Jmeas,Kmeas,smd = computeNonDimMeasures(1.0-sp.porosity,sp.media.radii[0:sp.n_spheres])
    printMeasures(1-sp.porosity,ewss,Jmeas,Kmeas)
    printarray = np.array([ewss,Jmeas,Kmeas,smd])
    np.savetxt(out_folder+"/measures.txt",printarray)

    # Target error:
    comp_es=1.0-sp.porosity
    err_es = abs(comp_es-target_es)/target_es*100

    # Mean Error
    comp_mu=sum(sp.media.radii)/len(sp.media.radii)
    err_mu = abs(comp_mu-target_r)/target_r*100
    print("Mean radius error (%): ",err_mu)

    # Variance Error
    varc = sp.media.radii-comp_mu
    comp_var=sum(np.multiply(varc,varc))/len(sp.media.radii)
    comp_std=np.sqrt(comp_var)
    print("Recovered Standard Deviation: ",comp_std)



    ewss,Jmeas,Kmeas,smd = computeNonDimMeasures(target_es,radii.radii)
    print("Measures before throwing into pack generator")
    printMeasures(target_es,ewss,Jmeas,Kmeas)


# Mono disperse case
nsph_ = [50,100,250,500,1000,2000]
var_ = [0.0, .0408,.0736,.1054]

target_r = .5

for i in range(4,5):        # Loop over number of spheres
    for j in range(0,4):    # Loop over variances
        print("mu: ",target_r,"; and var: ",var_[j])
        run_folder = "poly" + str(j+1) + "-" + str(nsph_[i]) + "_temp"
        out_folder = "poly" + str(j+1) + "-" + str(nsph_[i]) + "_data"
        generateEverything(target_r,var_[j],nsph_[i],run_folder,out_folder)

#mumin=.01; mumax=.25; mun=5
#varmin=0.0; varmax=.1;varn=5
#collectPrelimStats(mumin,mumax,mun,varmin,varmax,varn)
