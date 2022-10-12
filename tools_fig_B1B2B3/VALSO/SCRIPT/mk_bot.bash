#!/bin/bash

write_err() {
echo "error when running cdfmean ($1)"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt
}

# inputs
CONFIG=<CONFIG>
RUNID=<RUNID>
TAG=<TAG>
FREQ=<FREQ>

TBOTvar='|sosbt|sbt|votemper_bot|'
SBOTvar='|sosbs|sbs|vosaline_bot|'

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

if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_bot_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

FILEOUT=${CONFIG}-${RUNID}_${FREQ}_${TAG}_bottom-${GRID}.nc
if [[ $BOT == 1 ]]; then
   # make bot
   $CDFPATH/cdfbottom -f $FILE -nc4 -o tmp_$FILEOUT

   # mv output file
   if [[ $? -eq 0 ]]; then 
      mv tmp_$FILEOUT $FILEOUT
   else 
      echo "error when running cdfbottom; exit"; echo "E R R O R in : ./mk_bot.bash $@ (see SLURM/${CONFIG}/${RUNID}/bot_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ;
      exit 1
   fi
else
   ln -sf $FILE $FILEOUT
fi

set -x
# Amundsen avg (CDW)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -109.640 -102.230  -75.800  -71.660 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILEOUT -v $TBOTvar -p T -w ${ijbox} 0 0 -o AMU_thetao_$FILEOUT 
if [ $? -ne 0 ] ; then write_err AMU ; fi

# WRoss avg (bottom water)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w 157.100  173.333  -78.130  -74.040 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILEOUT -v $SBOTvar -p T -w ${ijbox} 0 0 -o WROSS_so_$FILEOUT 
if [ $? -ne 0 ] ; then write_err WROS ; fi

# ERoss avg (CDW)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -176.790 -157.820  -78.870  -77.520 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILEOUT -v $TBOTvar -p T -w ${ijbox} 0 0 -o EROSS_thetao_$FILEOUT 
if [ $? -ne 0 ] ; then write_err EROSS ; fi

# Weddell Avg (bottom water)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -65.130  -53.020  -75.950  -72.340 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILEOUT -v $SBOTvar  -p T -w ${ijbox} 0 0 -o WWED_so_$FILEOUT 
if [ $? -ne 0 ] ; then write_err WWED ; fi

# EWeddell Avg (CDW)
ijbox=$($CDFPATH/cdffindij -c mesh.nc -p T -w -45.647  -32.253  -78.632  -76.899 | tail -2 | head -1)
$CDFPATH/cdfmean -f $FILEOUT -v $TBOTvar  -p T -w ${ijbox} 0 0 -o EWED_thetao_$FILEOUT
if [ $? -ne 0 ] ; then write_err EWED ; fi

for AREA in FRIS ROSS AMUS GETZ BELING WPEN ; do
   echo "$AREA ..."
   $CDFPATH/cdfmean -f $FILEOUT -v $TBOTvar  -p T  -o ${AREA}_thetao_$FILEOUT -B msk_${AREA}_shelf.nc tmask
   if [ $? -ne 0 ] ; then write_err $AREA ; fi

   $CDFPATH/cdfmean -f $FILEOUT -v $SBOTvar  -p T  -o ${AREA}_so_$FILEOUT     -B msk_${AREA}_shelf.nc tmask
   if [ $? -ne 0 ] ; then write_err $AREA ; fi
done
