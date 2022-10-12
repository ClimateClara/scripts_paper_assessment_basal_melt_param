#!/bin/bash

# input
CONFIG=<CONFIG>
RUNID=<RUNID>
TAG=<TAG>
FREQ=<FREQ>

VAR='|berg_melt|'

# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/

# check presence of input file
GRID=$GRIDflx
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_icb.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_icb_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_icb-${GRID}.nc
set -x
# SH
$CDFPATH/cdfmean -f $FILE -v $VAR -p T -surf -o SH_$FILEOUT -B mask_bassin_SH.nc tmask
if [ $? -ne 0 ] ; then echo "error when running cdficb (SH)"; echo "E R R O R in : ./mk_icb.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_icb_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# NH
$CDFPATH/cdfmean -f $FILE -v $VAR -p T -surf -o NH_$FILEOUT -B mask_bassin_NH.nc tmask
if [ $? -ne 0 ] ; then echo "error when running cdficb (NH)"; echo "E R R O R in : ./mk_icb.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_icb_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; fi
