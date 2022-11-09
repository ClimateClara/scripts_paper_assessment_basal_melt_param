#!/bin/bash

# input
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
GRID=$GRIDT ; FILET=`get_nemofilename`
GRID=$GRIDT ; FILES=`get_nemofilename`
if [ ! -f $FILEV ] ; then echo "$FILEV is missing; exit"; echo "E R R O R in : ./mk_moc.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_moc_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILEU ] ; then echo "$FILEU is missing; exit"; echo "E R R O R in : ./mk_moc.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_moc_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILET ] ; then echo "$FILET is missing; exit"; echo "E R R O R in : ./mk_moc.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_moc_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi
if [ ! -f $FILES ] ; then echo "$FILES is missing; exit"; echo "E R R O R in : ./mk_moc.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_moc_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make moc
FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_moc.nc
set -x
$CDFPATH/cdfmoc -v $FILEV -u $FILEU -t $FILET -s $FILES -rapid ${VVL} -o tmp_$FILEOUT

# mv output file
if [[ $? -eq 0 ]]; then 
   mv rapid_tmp_$FILEOUT rapid_$FILEOUT
else 
   echo "error when running cdfmoc; exit"; echo "E R R O R in : ./mk_moc.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_moc_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi

