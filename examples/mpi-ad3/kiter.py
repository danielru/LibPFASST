import sys
import subprocess
import os
import numpy as np
import matplotlib.pyplot as plt

#  Run examples to check the iterations in PFASST
#Nstep_rack.append([300,400,600,800,1600,3200,4800,6400,9600])
#Nstep_rack.append([200,300,400,600,800,1600,3200,4800,6400,9600])
#Nstep_rack.append([100,200,250,300,400,500,600,800,1200,1600,2000,2400,3200,4800,6400])

Nnode_rack =[4];
Numruns=12
Niters=10
for N in range(5,8):
    Nx = 2**N
    Nsteps = Nx
    Nvars= [Nx/4, Nx/2, Nx]
    print Nvars
    dt = 1.0/(Nsteps)
    print Nsteps,dt
    table = {'Niters' : Niters, "Nsteps" : Nsteps, "Dt" : dt, "Nvar1": Nvars[0], "Nvar2": Nvars[1], "Nvar3": Nvars[2]}
    mycmd= 'mpiexec -n %(Nsteps)s ./main.exe probin.nml  niters=%(Niters)s  nsteps=%(Nsteps)s dt=%(Dt)s nvars="%(Nvar1)s %(Nvar2)s %(Nvar3)s"' % table
    print mycmd
    subprocess.call(mycmd, shell=True)

            #  Plot on the fly
            #fname = 'Dat/conv_Niter%(Niters)02d_Nsteps%(Nsteps)04d_Nnodes%(Nnodes)d_E.m' % table

            #print fname
            #with open(fname,'r') as f:
            #    a=np.loadtxt(f)
            #print a.shape, a.ndim, Niters
            #if a.ndim < 2:
            #    errors[eind]=a[3]
            #else:
            #    errors[eind]=a[Niters-1][3]

        
#        plt.loglog(Nstep_rack[Niters-1],errors,'-*')
#        plt.title('Convergence with %s Lobatto Nodes' % Nnodes)
#        plt.xlabel('Number of time step')
#        plt.ylabel('Rel. Error in Position')
#        if (Nnodes == 4):
#            plt.legend(["1 iter","2 iters","3 iters","4 iters"],loc=4)
#plt.show()
            

