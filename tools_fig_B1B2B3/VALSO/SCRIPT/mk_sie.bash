#!/bin/bash

write_err() {
echo "error when running cdficediags ($1)"; echo "E R R O R in : ./mk_sie.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_sie_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt
}

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
GRID=$GRIDI
FILE=`get_nemofilename`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_sie.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_sie_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# make sie
set -x

if [[ $FREQF == 1y && $FREQ == 1m ]]; then
   echo 'split file'
   for m in {0..11}; do
      mm=`printf "%02d" $m`     
      ncks -d time_counter,$mm,$mm $FILE ${FILE}_m$mm

      FILEOUT=GLO_sie_${CONFIG}-${RUNID}_${FREQ}_${TAG}m$mm.nc
      $CDFPATH/cdficediags -i ${FILE}_m$mm -o $FILEOUT
      if [[ $? -ne 0 ]]; then write_err GLO ; fi

      FILEOUT=AMUXL_sie_${CONFIG}-${RUNID}_${FREQ}_${TAG}m$mm.nc
      $CDFPATH/cdficediags -i ${FILE}_m$mm -maskfile msk_AMUXL.nc -o $FILEOUT
      if [[ $? -ne 0 ]]; then write_err AMUXL ; fi
   done 
else
   FILEOUT=GLO_sie_${CONFIG}-${RUNID}_${FREQ}_${TAG}.nc
   $CDFPATH/cdficediags -i $FILE -o $FILEOUT
   if [[ $? -ne 0 ]]; then write_err GLO ; fi

   FILEOUT=AMUXL_sie_${CONFIG}-${RUNID}_${FREQ}_${TAG}.nc
   $CDFPATH/cdficediags -i $FILE -maskfile msk_AMUXL.nc -o $FILEOUT
   if [[ $? -ne 0 ]]; then write_err AMUXL ; fi
fi
