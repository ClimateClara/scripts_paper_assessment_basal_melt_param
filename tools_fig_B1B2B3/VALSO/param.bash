#!/bin/bash

. PARAM/param_arch.bash

# diagnostics bundle
RUNVALSO=0
RUNVALGLO=0
RUNVALSI=0
RUNVALAMU=0
RUNALL=1

# custom
runACC=0
runMLD=0
runBSF=0
runBOT=0
runMOC=0
runMHT=0
runSIE=0
runSST=0
runQHF=0
runISF=0
runICB=0
runMEAN=0
runEKE=0
#
runOBS=0
#
if [[ $RUNALL == 1 || $RUNTEST == 1 ]]; then
   runACC=1 #acc  ts
   runMLD=1 #mld  ts
   runBSF=1 #gyre ts
   runBOT=1 #bottom TS ts
   runMOC=1
   runMHT=1
   runSIE=1
   runSST=1
   runQHF=1
   runISF=1
   runICB=1
   runMEAN=1
   runEKE=1
elif [[ $RUNVALSO == 1 ]]; then
   runACC=1 #acc  ts
   runMLD=1 #mld  ts
   runBSF=1 #gyre ts
   runBOT=1 #bottom TS ts
elif [[ $RUNVALGLO == 1 ]]; then
   runMOC=1
   runMHT=1
   runSIE=1
   runSST=1
   runQHF=1
elif [[ $RUNVALSI == 1 ]]; then
   runISF=1
   runICB=1
   runBOT=1
elif [[ $RUNVALAMU == 1 ]]; then
   runISF=1
   runBOT=1
   runSIE=1
fi
