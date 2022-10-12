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
GRID=$GRIDV ; FILEV=`get_nemofilename`
GRID=$GRIDU ; FILEU=`get_nemofilename`
if [ ! -f $FILEV ] ; then echo "$FILEV is missing; exit"; echo "E R R O R in : ./mk_trp.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_trp_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILEU ] ; then echo "$FILEU is missing; exit"; echo "E R R O R in : ./mk_trp.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_trp_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make trp
$CDFPATH/cdftransport -u $FILEU -v $FILEV -lonlat -noheat ${VVL} -pm  -sfx ${CONFIG}-${RUNID}_${FREQ}_${TAG} < ${EXEPATH}/SECTIONS/section_LONLAT.dat

# mv output file
if [[ $? -eq 0 ]]; then 
else 
   echo "error when running cdftransport; exit" ; echo "E R R O R in : ./mk_trp.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_trp_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
