#!/bin/bash

set -x
# input
CONFIG=<CONFIG>
RUNID=<RUNID>
FREQ=<FREQ>
TAG=<TAG>
GRID=<GRID>

# load default parameter
. param.bash

# load config dependant parameter
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd ${DATPATH}

# get data
if   [ $FREQ == '5d' ]; then echo '';
elif [ $FREQ == '1m' ]; then echo '';
elif [ $FREQ == '1y' ]; then echo '';
elif [ $FREQ == '5y' ]; then echo '';
elif [ $FREQ == '10y' ]; then echo '';
else echo '$FREQ frequency is not supported'; exit 1
fi

FILE_LST=`ls ${SIMPATH}/${NEMOFILE}`;

for MFILE in `echo ${FILE_LST}`; do
   FILE=`basename $MFILE`
   if [ -f $FILE ]; then 
      echo 'File $FILE already there, test integrity :'
      TIME=`ncdump -h $FILE | grep UNLIMITED | sed -e 's/(//' | awk '{print $6}'`
      if [[ $TIME -eq 0 ]]; then echo " $FILE is corrupted "; rm $FILE; else echo 'File seems OK'; fi
   fi
   if [ ! -f $FILE ]; then
      echo "downloading file ${MFILE} in ${DATPATH} ..."
      cp $MFILE .
   fi
done
echo 'done'
