#!/bin/bash

# create repository
if [ ! -d $DATPATH ]; then mkdir -p $DATPATH ; fi

# check mesh mask
cd ${DATPATH}
if [ ! -L mesh.nc     ] ; then ln -s ${MSKPATH}/${MSHMSK} mesh.nc     ; fi
if [ ! -L mask.nc     ] ; then ln -s ${MSKPATH}/${MSHMSK} mask.nc     ; fi
if [ ! -L subbasin.nc ] ; then ln -s ${MSKPATH}/${SUBMSK} subbasin.nc ; fi
if [ ! -L mskisf.nc   ] ; then ln -s ${MSKPATH}/${ISFMSK} mskisf.nc   ; fi
if [ ! -L isftxt.txt  ] ; then ln -s ${MSKPATH}/${ISFLST} isflst.txt  ; fi
if [ ! -L mesh.nc     ] ; then echo "mesh.nc     is missing; exit"; exit 1 ; fi
if [ ! -L mask.nc     ] ; then echo "mask.nc     is missing; exit"; exit 1 ; fi
if [ ! -L subbasin.nc ] ; then echo "subbasin.nc is missing; exit"; exit 1 ; fi
if [ ! -L mskisf.nc   ] ; then echo "mskisf.nc   is missing; exit"; exit 1 ; fi
if [ ! -L isflst.txt  ] ; then echo "isflst.txt  is missing; exit"; exit 1 ; fi
