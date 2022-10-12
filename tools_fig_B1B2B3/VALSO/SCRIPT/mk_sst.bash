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
GRID=$GRIDT
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_sst.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_sst_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

FILEOUT=SO_sst_${CONFIG}-${RUNID}_${FREQ}_${TAG}*_grid-${GRID}.nc

# make sst
set -x
jlimits=$($CDFPATH/cdffindij -w 0.0 1.0 -60.000  -40.000 -c mesh.nc -p T | tail -2 | head -1 | tr -s ' ' | cut -d' ' -f4-5)
echo "jlimits : $jlimits"
$CDFPATH/cdfmean -f $FILE -v '|thetao|votemper|' -w 0 0 ${jlimits} 1 1 -p T -o tmp_$FILEOUT 

# mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_sst.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_sst_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi

FILEOUT=NWC_sst_nemo_${RUN_NAME}o_${FREQ}_${TAG}*_grid-${GRID}.nc
ijbox=$($CDFPATH/cdffindij -w -50.190 -32.873 41.846 54.413 -c mesh.nc -p T | tail -2 | head -1 )
echo "ijbox : $ijbox"
$CDFPATH/cdfmean -f $FILE -v '|thetao|votemper|' -w ${ijbox} 1 1 -p T -o tmp_$FILEOUT 

#mv output file
if [[ $? -eq 0 ]]; then 
   mv tmp_$FILEOUT $FILEOUT
else 
   echo "error when running cdfmean; exit"; echo "E R R O R in : ./mk_sst.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_sst_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi
