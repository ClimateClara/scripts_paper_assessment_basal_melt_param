#!/bin/bash

#########
#This script is to format the raw NEMO data for further use 
#It extracts the interesting variables and adds the right grid information needed to regrid it in the next step
########

homepath=/bettik/burgardc

#### name of NEMO run
# nemo_run=OPM006
# nemo_run=OPM016
# nemo_run=OPM018
nemo_run=OPM021


################# DECLARE THE PATHS ##############################
path1=/bettik/mathiotp/NEMO/DRAKKAR/eORCA025.L121/eORCA025.L121-"$nemo_run"
path2=$homepath/DATA/BASAL_MELT_PARAM/raw/NEMO_eORCA025.L121-"$nemo_run"
path3=$homepath/DATA/BASAL_MELT_PARAM/interim/NEMO_eORCA025.L121_"$nemo_run"_ANT_STEREO
path4=$homepath/DATA/BASAL_MELT_PARAM/raw/BEDMACHINE_RTOPO
path5=$homepath/DATA/BASAL_MELT_PARAM/raw/
###################################################################

############### WRITE OUT ONLY VARIABLES OF INTEREST #################

#for yy in {1980..2018} #OPM006
#for yy in {1980..2008} #OPM016
#for yy in {1980..2008} #OPM018
for yy in {1989..2018} #OPM021

do
echo $yy
# extract 3D temperature, 3D salinity, sea-surface temperature, sea bottom temperature, sea bottom salinity 
cdo selvar,votemper,vosaline,sosst,sosss,sosbt,sosbs $path1/eORCA025.L121-"$nemo_run"-S/eORCA025.L121-"$nemo_run"_y"$yy".1y_gridT.nc $path2/eORCA025.L121-"$nemo_run"_y"$yy".1y_gridT_varofint.nc 
# extract basal melt rates
cdo selvar,sowflisf_cav $path1/eORCA025.L121-"$nemo_run"-S/eORCA025.L121-"$nemo_run"_y"$yy".1y_flxT.nc $path2/eORCA025.L121-"$nemo_run"_y"$yy".1y_flxT_varofint.nc 
done

# copy mask information
cp $path1/eORCA025.L121-"$nemo_run"-MSH/eORCA025.L121-"$nemo_run"_mesh_mask.nc $path2/eORCA025.L121-"$nemo_run"_mesh_mask.nc
###############################################################

############### DATA MANIPULATION TO HAVE IT ON THE RIGHT GRID FOR CDO REGRIDDING #################
# -O overwriting file
# -C -v control variables
# -a no alphabetical order of the variables

#for yy in {1980..2018} #OPM006
#for yy in {1980..2008} #OPM016
#for yy in {1980..2008} #OPM018
for yy in {1989..2018} #OPM021

do

echo $yy
echo 'cp > create gridded file'
cp $path5/grid_eORCA025_CDO.nc $path3/variables_of_interest_"$yy".nc

for var in {votemper,vosaline,sosst,sosss,sosbt,sosbs}
do
echo $var
echo 'ncks > extract variable from gridT' $var
ncks -O -C -v $var $path2/eORCA025.L121-"$nemo_run"_y"$yy".1y_gridT_varofint.nc $path3/$var.nc
echo 'ncks > put variable in file' $var
ncks -A -C -v $var $path3/$var.nc $path3/variables_of_interest_"$yy".nc
echo 'ncatted > put coords to lon lat' $var
ncatted -a coordinates,$var,m,c,"lon lat" $path3/variables_of_interest_"$yy".nc
\rm $path3/$var.nc
done

var=sowflisf_cav
echo $var
echo 'ncks > extract variable from flxT' $var
ncks -O -C -v $var $path2/eORCA025.L121-"$nemo_run"_y"$yy".1y_flxT_varofint.nc $path3/$var.nc
echo 'ncks > put variable in file' $var
ncks -A -C -v $var $path3/$var.nc $path3/variables_of_interest_"$yy".nc
echo 'ncatted > put coords to lon lat' $var
ncatted -a coordinates,$var,m,c,"lon lat" $path3/variables_of_interest_"$yy".nc
\rm $path3/$var.nc
done

echo 'cp > create gridded file'
cp $path2/grid_eORCA025_CDO.nc $path3/mask_variables_of_interest.nc

# write out the ice-shelf draft, the bathymetry and the ice-shelf mask (the latter is just to double-check the one we produce ourselves)
for var in {isfdraft,bathy_metry,misf} 
do
echo $var
echo 'ncks > extract variable'
ncks -O -C -v $var $path2/eORCA025.L121-"$nemo_run"_mesh_mask.nc $path3/$var.nc
echo 'ncks > put variable in file'
ncks -A -C -v $var $path3/$var.nc $path3/mask_variables_of_interest.nc
echo 'ncatted > put coords to lon lat'
ncatted -a coordinates,$var,m,c,"lon lat" $path3/mask_variables_of_interest.nc
done

# write out the 3D depth coordinate
var=gdept_0
echo $var
echo 'ncks > extract variable'
ncks -O -C -v $var $path2/eORCA025.L121-"$nemo_run"_mesh_mask.nc $path3/$var.nc
echo 'ncks > put variable in file'
ncks -A -C -v $var $path3/$var.nc $path3/mask_variables_of_interest.nc
echo 'ncatted > put coords to lon lat'
ncatted -a coordinates,$var,m,c,"lon lat" $path3/mask_variables_of_interest.nc

# write out the land-sea mask
var=tmask #instead of tmaskutil to avoid the vertical line
echo $var 
echo 'define land sea mask'
cdo ifthenc,1 -vertsum -selvar,tmask $path2/eORCA025.L121-"$nemo_run"_mesh_mask.nc $path3/"$var"_sum_withmiss.nc 
cdo setmisstoc,0 $path3/"$var"_sum_withmiss.nc $path3/"$var"_sum.nc
echo 'ncks > extract variable'
ncks -O -C -v $var $path3/"$var"_sum.nc $path3/$var.nc
echo 'ncks > put variable in file'
ncks -A -C -v $var $path3/$var.nc $path3/mask_variables_of_interest.nc
echo 'ncatted > put coords to lon lat'
ncatted -a coordinates,$var,m,c,"lon lat" $path3/mask_variables_of_interest.nc


############### SELECT ONLY ANTARCTICA #################

### Variables
#for yy in {1980..2018} #OPM006
#for yy in {1980..2008} #OPM016, OPM018
for yy in {1989..2018} #OPM021

do

echo $yy
cdo sellonlatbox,0,360,-90,-50 $path3/variables_of_interest_"$yy".nc $path3/variables_of_interest_"$yy"_Ant.nc
done

### Masks 
cdo setgrid,$path3/variables_of_interest_1999.nc $path3/mask_variables_of_interest.nc $path3/mask_variables_of_interest_setgrid.nc
echo 'cut mask file'
cdo sellonlatbox,0,360,-90,-50 $path3/mask_variables_of_interest_setgrid.nc $path3/mask_variables_of_interest_Ant.nc

############### PREPARE A LANDMASK WITHOUT NANS (ZEROS INSTEAD) TO MAKE THE REGRIDDING MORE MEANINGFUL AFTERWARDS #################


cdo ifthenc,2 -subc,1 -selvar,tmask $path3/mask_variables_of_interest_Ant.nc $path3/lsmask_0-2_Ant_withmiss.nc  
cdo setmisstoc,0 $path3/lsmask_0-2_Ant_withmiss.nc $path3/lsmask_0-2_Ant.nc 

cdo ifthenc,1 -selvar,isfdraft $path3/mask_variables_of_interest_Ant.nc $path3/isfmask_1_Ant_withmiss.nc 
cdo setmisstoc,0 $path3/isfmask_1_Ant_withmiss.nc $path3/isfmask_1_Ant.nc 

cdo add $path3/lsmask_0-2_Ant.nc $path3/isfmask_1_Ant.nc $path3/lsmask_0-1-2_andsome3s_Ant.nc
cdo mul -lec,2 $path3/lsmask_0-1-2_andsome3s_Ant.nc $path3/lsmask_0-1-2_andsome3s_Ant.nc $path3/lsmask_0-1-2_Ant_nonfloat.nc
cdo mulc,1.0 $path3/lsmask_0-1-2_Ant_nonfloat.nc $path3/lsmask_0-1-2_Ant.nc 


#### WHEN YOU'RE FINISHED WITH THIS, MOVE TO THE PYTHON NOTEBOOK "custom_lsmask.ipynb"