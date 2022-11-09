#!/bin/bash -l
#SBATCH --mem=500
#SBATCH --time=60
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

CONFIG=$1
RUNID=$2
FREQ=$3
TAG=$4
GRID=$5

# load default parameter
. param.bash
#
# load config dependant parameter
. PARAM/param_${CONFIG}.bash
#
# make links
. ${SCRPATH}/common.bash

cd ${DATPATH}

# get data
if   [ $FREQ == '5d' ]; then echo '';
elif [ $FREQ == '1m' ]; then echo '';
elif [ $FREQ == '1y' ]; then echo '';
elif [ $FREQ == '10y' ]; then echo '';
else echo '$FREQ frequency is not supported'; exit 1
fi

FILE_LST=`ls ${SIMPATH}/${NEMOFILE}`;

for MFILE in `echo ${FILE_LST}`; do
   FILE=`basename $MFILE`
   if [ -f $FILE ]; then 
      TIME=`ncdump -h $FILE | grep UNLIMITED | sed -e 's/(//' | awk '{print $6}'`
      if [[ $TIME -eq 0 ]]; then echo " $FILE is corrupted "; rm $FILE; fi
   fi
   if [ ! -f $FILE ]; then
      echo "downloading file ${MFILE} in ${DATPATH} ..."
      cp $MFILE .
   fi
done
echo 'done'
