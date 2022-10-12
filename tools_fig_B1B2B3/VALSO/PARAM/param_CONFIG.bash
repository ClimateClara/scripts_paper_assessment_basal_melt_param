#!/bin/bash

# where mask are stored (name of mesh mask in SCRIPT/common.bash)
MSKPATH=${SCRATCHDIR}/DRAKKAR/${CONFIG}/${CONFIG}-${RUNID}-MSH/
MSHMSK=${CONFIG}-${RUNID}_mesh_mask.nc
SUBMSK=${CONFIG}-${RUNID}_subbassins.nc
ISFMSK=${CONFIG}-${RUNID}_mskisf.nc
ISFLST=${CONFIG}-${RUNID}_isflst.txt

# STORE DIR (where data are)
STOPATH=${SCRATCHDIR}/DRAKKAR/${CONFIG}/${CONFIG}-${RUNID}-S/

# CFG path, ie where processing is done (CONFIG and RUNID are fill by script)
DATPATH=${WRKPATH}/${CONFIG}-${RUNID}/

# NEMO output format (update it for your need)
#       for TAG see get_tag below
NEMOFILE=${CONFIG}-${RUNID}_${TAG}.${FREQ}_${GRID}.nc

# how the store dir is organised (FREQ/YEAR/*.nc in this case)
SIMPATH=${STOPATH}/${FREQ}/*/

# grid (update it for your need)
GRIDT=gridT ; GRIDU=gridU ; GRIDV=gridV ; GRIDI=icemod ; GRIDflx=flxT

# how the monthly file are stored (1file per month in this case, '1y' if all monthly file in a yearly file)
FREQF='1m'

# get NEMO FILE
get_nemofilename() {
  echo ${CONFIG}-${RUNID}_${TAG}.${FREQ}_${GRID}.nc
}

# get TAG
get_tag() {
  FREQ=$1 ; YYYY=$2 ; MM=$3 ; DD=$4
  if [ $FREQ == '1y' ]; then
     echo y${YYYY}
  elif [ $FREQ == '1m' ]; then
     echo y${YYYY}m${MM}
  else
     echo y${YYYY}m${MM}d${DD}
  fi
}
