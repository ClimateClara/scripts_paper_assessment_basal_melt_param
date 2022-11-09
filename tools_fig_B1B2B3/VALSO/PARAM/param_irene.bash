#!/bin/bash

ulimit -s unlimited

module purge
module load intel/20.0.0 hdf5/1.8.20 netcdf-fortran/4.4.4 nco

# where cdftools are stored
CDFPATH=${CCCWORKDIR}/TOOLS/CDFTOOLS_4.0_ISF/bin/

# toolbox location (where the toolbox is installed)
EXEPATH=${CCCWORKDIR}/TOOLS/VALSO/

# SCRIPT location (where script are, no need to be changed)
SCRPATH=${EXEPATH}/SCRIPT/

# WORK path (where all the processing will be done)
WRKPATH=${CCCWORKDIR}/NEMO/PP/

# Storage path: where the data are stored
STOPATH=${CCCSCRATCHDIR}/DRAKKAR/


#++++++++++++++++++++++++++++++++++++
#      FUNCTION to submit task
#++++++++++++++++++++++++++++++++++++

load_python() {
conda activate valso
}

retreive_data() {
   # $1 = $CONFIG ; $2 = $RUNID ; $3 = $FREQ ; $4 = $TAG ; $5 = $GRID
   # prepare run script
   sed -e  "s!<CONFIG>!${1}!g"\
       -e  "s!<RUNID>!${2}!g" \
       -e  "s!<FREQ>!${3}!g"  \
       -e  "s!<TAG>!${4}!g"   \
       -e  "s!<GRID>!${5}!g" ${SCRPATH}/get_data.bash > ${WRKPATH}/${1}-${2}/get_data.bash_${1}_${2}_${3}_${4}_${5}
   # run script
   ccc_msub -r moo_${4}_${5}                                                          \
            -o  ${JOBOUT_PATH}/moo_${3}_${4}_${5}                                     \
            -e  ${JOBOUT_PATH}/moo_${3}_${4}_${5}_err                                 \
            -T 600 -n 1 -A gen6035 -q rome -m store,work,scratch -E " -D ${EXEPATH} " \
            ${WRKPATH}/${1}-${2}/get_data.bash_${1}_${2}_${3}_${4}_${5} | awk '{print $4}'
}

build_mask() {
   # $1 = $CONFIG ; $2 = $RUNID
   # prepare run script
   sed -e  "s!<CONFIG>!${1}!g"\
       -e  "s!<RUNID>!${2}!g" ${SCRPATH}/mk_msk.bash > ${WRKPATH}/${1}-${2}/mk_msk.bash_${1}_${2}
   # run script
   ccc_msub -r mk_msk_${1}_${2}                         \
            -o ${JOBOUT_PATH}/mk_msk_${1}_${2}.out      \
            -e ${JOBOUT_PATH}/mk_msk_${1}_${2}.err      \
            -T 600 -n 1 -A gen6035 -q rome -m store,work,scratch -E " -D ${EXEPATH} " \
            ${WRKPATH}/${1}-${2}/mk_msk.bash_${1}_${2} | awk '{print $4}'
}

run_tool() {
   # $1 = TOOL ; $2 = $CONFIG ; $3 = $TAG ; $4 = $RUNID ; $5 = $FREQ ; $6+ = ID
   # global var njob
   # prepare run script
   sed -e  "s!<CONFIG>!${2}!g"\
       -e  "s!<RUNID>!${4}!g" \
       -e  "s!<FREQ>!${5}!g"  \
       -e  "s!<TAG>!${3}!g"   ${SCRPATH}/${1}.bash > ${WRKPATH}/${2}-${4}/${1}.bash_${2}_${4}_${3}_${5}
   # run script
   ccc_msub -r SO_${1}_${2}_${3}_${4}                \
            -o ${JOBOUT_PATH}/${1}_${5}_${3}.out     \
            -e ${JOBOUT_PATH}/${1}_${5}_${3}.err     \
            -T 1200 -n 1 -A gen6035 -q rome -m store,work,scratch -E " -D ${EXEPATH} --dependency=afterany:${@:6} --wait " \
            ${WRKPATH}/${2}-${4}/${1}.bash_${2}_${4}_${3}_${5} > /dev/null 2>&1 &
   njob=$((njob+1))
}
