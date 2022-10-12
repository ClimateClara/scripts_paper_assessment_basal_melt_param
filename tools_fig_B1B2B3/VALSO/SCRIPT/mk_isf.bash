#!/bin/bash

export OMP_NUM_THREADS=8

write_err() {
   echo "error when running cdfisf_diags; exit"; echo "E R R O R in : ./mk_isf.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_isf_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
}

# input
CONFIG=<CONFIG>
RUNID=<RUNID>
TAG=<TAG>
FREQ=<FREQ>

VAR='|fwfisf|sowflisf_cav|'

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
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_isf.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_isf_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# compute melt
FILEOUT=ISF_ALL_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfisf_diags -f $FILE -v $VAR -mskf mskisf.nc -mskv mask_isf -l isflst.txt -o $FILEOUT
if [[ $? -ne 0 ]]; then write_err ; fi
#
GRID=$GRIDT
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_isf.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_isf_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# compute profile T
FILEOUT=ISF_Tprof_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v votemper -p T -I mskisf.nc mask_isf_front isflst.txt -o $FILEOUT ${VVL}
if [[ $? -ne 0 ]]; then write_err ; fi

FILEOUT=ISF_Sprof_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc
$CDFPATH/cdfmean -f $FILE -v vosaline -p T -I mskisf.nc mask_isf_front isflst.txt -o $FILEOUT ${VVL}
if [[ $? -ne 0 ]]; then write_err ; fi

