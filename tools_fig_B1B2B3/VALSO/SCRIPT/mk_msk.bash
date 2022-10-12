#!/bin/bash

# inputs
CONFIG=<CONFIG>
RUNID=<RUNID>

# load path and mask
. param.bash

# load config param
. PARAM/param_${CONFIG}.bash

# make links
. ${SCRPATH}/common.bash

cd $DATPATH/
set -x
# FRIS shelf
$CDFPATH/cdfmkmask -zoom -63 -25 -80 -71 -f mask.nc -v tmask -zoomvar '|hdept|bathy_metry|' 1000 6000 2d -o msk_FRIS_shelf.nc  -filllonlat -32.224 -73.091 -r -2d
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (FRIS)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# ROSS shelf
$CDFPATH/cdfmkmask -zoom 160 202 -79 -71.5 -f mask.nc -v tmask -zoomvar '|hdept|bathy_metry|' 1000 6000 2d -o msk_ROSS_shelf.nc -filllonlat -190.0 -70.0 -r -2d
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (ROSS)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# AMU  shelf
$CDFPATH/cdfmkmask -zoom -114 -101 -76 -70 -f mask.nc -v tmask -zoomvar '|hdept|bathy_metry|' 1000 6000 2d -o msk_AMUS_shelf.nc -filllonlat -113      -70.746 -r -2d
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (AMUS)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# AMUXL 
$CDFPATH/cdfmkmask -zoom -140 -86 -80 -60 -f mask.nc -v tmask -o msk_AMUXL.nc -2d
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (AMUXL)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# GETZ shelf
$CDFPATH/cdfmkmask  -zoom -137 -114 -76 -70 -f mask.nc -v tmask -zoomvar '|hdept|bathy_metry|' 1000 6000 2d -o msk_GETZ_shelf.nc -filllonlat -118.993 -70.746 -r -2d
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (GETZ)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# SH
$CDFPATH/cdfmkmask -zoom -180 180 -90 0 -f mask.nc -v tmask -o mask_bassin_SH.nc -2d
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (SH)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# NH
$CDFPATH/cdfmkmask -zoom -180 180 0  90 -f mask.nc -v tmask -o mask_bassin_NH.nc -2d
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (NH)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# BELING shelf
$CDFPATH/cdfmkmask -f mask.nc -v tmask -zoomvar '|hdept|bathy_metry|' 1000 6000 2d -zoom -100 -70.5 -76 -69 -filllonlat -86.544076 -69.8 -r -2d -o msk_BELING_shelf.nc
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (BELING)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi

# W PENIN shelf
$CDFPATH/cdfmkmask -f mask.nc -v tmask -zoomvar '|hdept|bathy_metry|' 1000 6000 2d -zoom -72 -62.3 -72 -62 -filllonlat -66 -63 -r -2d -o msk_WPEN_shelf.nc 
if [ $? -ne 0 ] ; then echo "error when running cdfmkmask (W PENIN)"; echo "E R R O R in : ./mk_msk.bash $@ (see SLURM/${CONFIG}/${RUNID}/mk_msk_${CONFIG}_${RUNID}.out)" >> ${EXEPATH}/ERROR.txt ; fi
