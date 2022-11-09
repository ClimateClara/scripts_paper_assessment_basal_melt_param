#!/bin/bash

# where mask are stored (name of mesh mask in SCRIPT/common.bash)
MSKPATH=${STOPATH}/${CONFIG}/${CONFIG}-${RUNID}-MSH/
MSHMSK=${CONFIG}-${RUNID}_mesh_mask.nc
SUBMSK=${CONFIG}-${RUNID}_subbassins.nc
ISFMSK=${CONFIG}-${RUNID}_mskisf.nc
ISFLST=${CONFIG}-${RUNID}_isflst.txt

# STORE DIR (where data are)
STOPATH=${STOPATH}/${CONFIG}/${CONFIG}-${RUNID}-S/
SIMPATH=${STOPATH}/${FREQ}/*/

# CFG path, ie where processing is done (CONFIG and RUNID are fill by script)
DATPATH=${WRKPATH}/${CONFIG}-${RUNID}/
if [ ! -d $DATPATH ]; then mkdir -p $DATPATH ; fi

# NEMO output format (update it for your need)
#       for TAG see get_tag below
NEMOFILE=${CONFIG}-${RUNID}_${TAG}.${FREQ}_${GRID}.nc

# grid (update it for your need)
GRIDT=gridT ; GRIDU=gridU ; GRIDV=gridV ; GRIDI=icemod ; GRIDflx=flxT

# frequency of the monthly file (1m means 1 file per month, 1y means 1 file per 12 month)
FREQF='1m'

# get NEMO FILE
get_nemofilename() {
  echo ${CONFIG}-${RUNID}_${TAG}.${FREQ}_${GRID}.nc
}

# get TAG
get_tag() {
  FREQ=$1 ; YYYY=$2 ; MM=$3 ; DD=$4
  if [ $FREQ == '10y' ]; then
     echo y${YYYY}
  elif [ $FREQ == '5y' ]; then
     echo y${YYYY}
  elif [ $FREQ == '1y' ]; then
     echo y${YYYY}
  elif [ $FREQ == '1m' ]; then
     echo y${YYYY}m${MM}
  else
     echo y${YYYY}m${MM}d${DD}
  fi
}

# CDFTOOLS
# is the run vvl ?
VVL=-vvl
# do we need to run cdfbottom ?
BOT=0
