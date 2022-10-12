#!/bin/bash

# inputs
CONFIG=<CONFIG>
RUNID=<RUNID>
TAG=<TAG>
FREQ=<FREQ>

MXLvar='|somxzint1|sokaraml|somxl010|'

# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/

# check presence of input file
GRID=$GRIDT
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_mxl.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_mxl_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

FILEOUT=WMXL_${CONFIG}-${RUNID}_${FREQ}_${TAG}_${GRID}.nc

# make mxl
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -31.250   37.500  -66.500  -60.400 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILE -v $MXLvar -p T -w ${ijbox} 0 0 -o tmp_$FILEOUT

# mv output file
if [[ $? -ne 0 ]]; then 
   echo "error when running cdfmxl; exit"; echo "E R R O R in : ./mk_mxl.bash $@ (see SLURM/${CONFIG}/${RUNID}/mxl_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
#
