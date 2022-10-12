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
GRID=$GRIDflx
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_hfds.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_hfds_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make mxl
FILEOUT=GLO_hfds_${CONFIG}-${RUNID}_${FREQ}_${TAG}_grid-${GRID}.nc
set -x
pwd
$CDFPATH/cdfmean -f $FILE -v '|sohefldo|hfds|' -surf -p T -o $FILEOUT 

# mv output file
if [[ $? -ne 0 ]]; then 
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_hfds.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_hfds_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
#
