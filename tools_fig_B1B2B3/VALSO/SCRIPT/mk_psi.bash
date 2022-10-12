#!/bin/bash

# inputs
CONFIG=<CONFIG>
RUNID=<RUNID>
TAG=<TAG>
FREQ=<FREQ>

# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/

# check presence of input file

GRID=$GRIDU ; FILEU=`get_nemofilename`
GRID=$GRIDV ; FILEV=`get_nemofilename`
if [ ! -f $FILEV ] ; then echo "$FILEV is missing; exit"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_psi_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILEU ] ; then echo "$FILEU is missing; exit"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_psi_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make psi
FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_psi.nc
$CDFPATH/cdfpsi -u $FILEU -v $FILEV ${VVL} -nc4 -ref 1 1 -o tmp_$FILEOUT

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfpsi; exit"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_psi_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi

# WG max
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -31.250 37.500 -66.500 -60.400 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILEOUT -v sobarstf -p T -w ${ijbox} 0 0 -o WG_$FILEOUT
if [ $? -ne 0 ] ; then echo "error when running cdfmean (WG)"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_psi_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# RG max
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -168.500 -135.750 -72.650 -61.600 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILEOUT -v sobarstf -p T -w ${ijbox} 0 0 -o RG_$FILEOUT
if [ $? -ne 0 ] ; then echo "error when running cdfmean (RG)"; echo "E R R O R in : ./mk_psi.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_psi_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi
