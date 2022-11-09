#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ~/.bashrc
. PARAM/param_arch.bash
load_python

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}

# ACC
# Drake
echo 'plot ACC time series'
set -x
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *ACC*${FREQ}*.nc -var vtrp -sf -1 -title "ACC transport (Sv)" -dir ${WRKPATH} -o ${KEY}_fig01 -obs OBS/ACC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# AMOC
echo 'plot AMOC time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f rapid_*${FREQ}*moc.nc -var Total_max_amoc_rapid -title "Max AMOC 26.5N (Sv)" -dir ${WRKPATH} -o ${KEY}_fig02 -obs OBS/AMOC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# MHT 
echo 'plot MHT  time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *${FREQ}*mht_265.nc -var zomht_atl -title "AMHT 26.5N (PW)" -dir ${WRKPATH} -o ${KEY}_fig03 -obs OBS/AMHT_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# QNET
echo 'plot QNET  time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f GLO_hfds*${FREQ}*.nc -var '(mean_sohefldo|mean_hfds)' -title "Net downward heat flux (W/m2)" -dir ${WRKPATH} -o ${KEY}_fig04 -obs OBS/QNET_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# SO SST
echo 'plot SO SST time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f SO_sst*${FREQ}*.nc -var '(mean_votemper|mean_thetao)' -title "SO sst [K]" -dir ${WRKPATH} -o ${KEY}_fig05 -obs OBS/SO_sst_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# SO SST
echo 'plot SO SST time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f NWC_sst*${FREQ}*.nc -var '(mean_votemper|mean_thetao)' -title "NWC sst [K]" -dir ${WRKPATH} -o ${KEY}_fig06 -obs OBS/NWC_sst_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ARC SIE
echo 'plot 02 SIE time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -varf 'GLO*sie*m03*.nc' 'GLO*sie*m09*.nc' -var NExnsidc NExnsidc -sf 0.001 0.001 -title "SIE Arctic m03 [1e6 km2]" "SIE Arctic m09 [1e6 km2]" -dir ${WRKPATH} -o ${KEY}_fig07 -obs OBS/ARC_sie03_obs.txt OBS/ARC_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

echo 'plot 09 SIE time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -varf 'GLO*sie*m02*.nc' 'GLO*sie*m09*.nc' -var SExnsidc SExnsidc -sf 0.001 0.001 -title "SIE Antarctic m02 [1e6 km2]" "SIE Antarctic m09 [1e6 km2]" -dir ${WRKPATH} -o ${KEY}_fig08 -obs OBS/ANT_sie02_obs.txt OBS/ANT_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# trim figure
convert ${KEY}_fig01.png -crop 1240x1040+0+0 tmp01.png
convert ${KEY}_fig02.png -crop 1240x1040+0+0 tmp02.png
convert ${KEY}_fig03.png -crop 1240x1040+0+0 tmp03.png
convert ${KEY}_fig04.png -crop 1240x1040+0+0 tmp04.png
convert ${KEY}_fig05.png -crop 1240x1040+0+0 tmp05.png
convert ${KEY}_fig06.png -crop 1240x1040+0+0 tmp06.png
convert ${KEY}_fig07.png -crop 1240x1040+0+0 tmp07.png
convert ${KEY}_fig08.png -crop 1240x1040+0+0 tmp08.png
convert FIGURES/box_VALGLO.png -trim -bordercolor White -border 40 tmp09.png
convert FIGURES/box_VALGLO.png -trim -bordercolor White -border 40 tmp09.png
convert legend.png             -trim -bordercolor White -border 20 tmp10.png
convert runidname.png          -trim -bordercolor White -border 20 tmp11.png

# compose the image
convert \( tmp01.png tmp02.png tmp03.png +append \) \
        \( tmp04.png tmp05.png tmp09.png +append \) \
        \( tmp06.png tmp07.png tmp08.png +append \) \
           tmp10.png tmp11.png -append -trim -bordercolor White -border 40 $KEY.png

# save plot
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp10.png FIGURES/${KEY}_legend.png
mv tmp11.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png

# display
#display -resize 30% $KEY.png
