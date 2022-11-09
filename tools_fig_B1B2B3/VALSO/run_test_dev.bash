#!/bin/bash
RUNTEST=1
RUNID1=u-bn900 ; RUNID2=u-bs852
. ./run_all.bash eORCA025 1976 1992 1y $RUNID1 $RUNID2
./run_plot_VALGLO.bash ICB $RUNID1 $RUNID2
./run_plot_VALSO.bash  ICB 1y $RUNID1 $RUNID2
