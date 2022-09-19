#!/bin/bash

### THIS SCRIPT IS TO SEND JOBS ON THE LUKE COMPUTER TO DO THE TUNING FOR THE PLUME, BOX AND PICOP PARAMETERISATIONS
### It uses the python script "run_generalized_tuning_from_bash_crossval.ipynb"

tide_opt=False # Not everything has been adapted for tides yet so leave it at False!

tuning_approach='BT' # can be 'BT' (bootstrap), 'CV' (cross validation), 'ALL' (best estimate)
param_opt=box # can be linear, quadratic, plume, box
dom=50 # can be 50 or 1000

# if quadratic or local
simple_form=linear_local # can be 'quadratic_local', 'quadratic_local_cavslope', 'quadratic_local_locslope', quadratic_mixed_mean', 'quadratic_mixed_cavslope', 'quadratic_mixed_locslope' 

# if plume
plume_form=lazero19_2 # can be lazero19_2 or lazero19_modif2

# if box
nDconfig=4 # can be 1 (2 boxes), 2 (5 boxes), 3 (10 boxes), 4 (PICO boxes)
pism=yes # can be yes or no (yes = heterogeneous boxes, no = homogeneous boxes)
picop=no # can be yes or no (yes = PICOP, no = only boxes)

if  [ $param_opt == plume ]
    then
    mparam=${plume_form}
elif [ $param_opt == linear ]
    then
    mparam=${simple_form}
elif [ $param_opt == quadratic ]
    then
    mparam=${simple_form}
elif [ $param_opt == box ]
    then
    mparam=${nDconfig}_${pism}_${picop}
fi

## FOR CROSS-VALIDATION - make either a loop over ice shelves and keep tblock_out=0 or make a loop over tblocks and keep isf_out = 0

#for ii in 10 11 12 13 18 22 23 24 25 30 31 33 38 39 40 42 43 44 45 47 48 51 52 53 54 55 58 61 65 66 69 70 71 73 75
#do
#isf_out=$ii
isf_out=00

#for tt in {01..13}
#do
#tblock_out=$tt
tblock_out=00

## FOR BOOTSTRAP - iterate over ii, it will create a random tblock and isf sample at each bootstrap step. So the name isf_out is just used because it is already an option to put in
for ii in {491..500} 
do
isf_out=$ii

if [ $tide_opt == True ]
    then
    path_jobscripts=/bettik/burgardc/SCRIPTS/basal_melt_param/scripts/BASH/JOB_SCRIPTS/${param_opt}_scripts_tides
    path_outfiles=/bettik/burgardc/SCRIPTS/basal_melt_param/scripts/BASH/JOB_SCRIPTS/${param_opt}_tuning_tides
elif [ $tide_opt == False ]
    then
    path_jobscripts=/bettik/burgardc/SCRIPTS/basal_melt_param/scripts/BASH/JOB_SCRIPTS/${param_opt}_scripts_${tuning_approach}
    path_outfiles=/bettik/burgardc/SCRIPTS/basal_melt_param/scripts/BASH/JOB_SCRIPTS/${param_opt}_tuning_${tuning_approach}
fi

path_python=/bettik/burgardc/SCRIPTS/basal_melt_param/scripts/PYTHON
path_jobid=/bettik/burgardc/SCRIPTS/basal_melt_param/scripts/JOB_STD_OUTPUT

#i=all_utide0
#i=Amundsen_wo006

cat <<EOF > $path_jobscripts/${param_opt}_${mparam}_${dom}km_${tuning_approach}_tides${tide_opt}_noisf${isf_out}_notblock${tblock_out}.sh

#!/bin/bash

conda activate py38
python -u $path_python/run_generalized_tuning_from_bash_crossval.py ${tide_opt} ${tuning_approach} ${param_opt} ${dom} ${mparam} ${isf_out} ${tblock_out} 2>&1 | tee $path_outfiles/${param_opt}_${mparam}_${dom}km_${tuning_approach}_tides${tide_opt}_noisf${isf_out}_notblock${tblock_out}.log 
EOF

chmod +x $path_jobscripts/${param_opt}_${mparam}_${dom}km_${tuning_approach}_tides${tide_opt}_noisf${isf_out}_notblock${tblock_out}.sh


oarsub -S -n ${param_opt}_${mparam}_${dom}km_${tuning_approach}_tides${tide_opt}_noisf${isf_out}_notblock${tblock_out} --stdout $path_jobid/${param_opt}_${mparam}_${dom}km_${tuning_approach}_tides${tide_opt}_noisf${isf_out}_notblock${tblock_out}.o%jobid%  --stderr $path_jobid/${param_opt}_${mparam}_${dom}km_${tuning_approach}_tides${tide_opt}_noisf${isf_out}_notblock${tblock_out}.e%jobid% -l nodes=1/core=2,walltime=10:00:00 --project ice_speed -p "network_address='luke62'" $path_jobscripts/${param_opt}_${mparam}_${dom}km_${tuning_approach}_tides${tide_opt}_noisf${isf_out}_notblock${tblock_out}.sh

# to remove if no CV!!!
done



