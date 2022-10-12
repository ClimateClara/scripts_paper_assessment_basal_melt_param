#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ~/.bashrc
. PARAM/param_arch.bash
load_python

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}

# ISF
# FRIS
echo 'plot total FRIS time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_FRIS)' -title "FRIS total melt (Gt/y)" -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig01 -obs OBS/FRIS_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ROSS
echo 'plot total ROSS melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_ROSS)' -title "ROSS total melt (Gt/y)"  -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig02  -obs OBS/ROSS_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# PINE
echo 'plot total PINE G melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_PINE)' -title "PIG total melt (Gt/y)"   -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig03  -obs OBS/PINE_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean T FRIS
echo 'plot mean bot T (FRIS) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f FRIS*thetao*${FREQ}*T.nc   -var '(mean_sosbt_tmask)' -title "Mean bot. temp. FRIS (C)"   -dir ${WRKPATH} -o ${KEY}_fig04  -obs OBS/FRIS_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean T ROSS
echo 'plot mean bot T (ROSS) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ROSS*thetao*${FREQ}*T.nc   -var '(mean_sosbt_tmask)' -title "Mean bot. temp. ROSS(C)"   -dir ${WRKPATH} -o ${KEY}_fig05   -obs OBS/ROSS_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean T AMU
echo 'plot mean bot T (AMUS) time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f AMUS*thetao*${FREQ}*T.nc   -var '(mean_sosbt_tmask)' -title "Mean bot. temp. AMU (C)"   -dir ${WRKPATH} -o ${KEY}_fig06   -obs OBS/AMUS_botT_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# TOTAL
echo 'plot total TOTAL melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_TOTA)' -title "ANT (isf) total melt (Gt/y)"  -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig07  -obs OBS/ANT_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ICB
echo 'plot total icb melt time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f SH*${FREQ}*icb*.nc -var '(sum_berg_melt_tmask)' -title "ANT (icb) total melt (Gt/y)" -sf 0.000031536 -dir ${WRKPATH} -o ${KEY}_fig08  -obs OBS/ANTicb_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# crop figure (rm legend)
convert ${KEY}_fig01.png -crop 1240x1040+0+0 tmp01.png
convert ${KEY}_fig02.png -crop 1240x1040+0+0 tmp02.png
convert ${KEY}_fig03.png -crop 1240x1040+0+0 tmp03.png
convert ${KEY}_fig04.png -crop 1240x1040+0+0 tmp04.png
convert ${KEY}_fig05.png -crop 1240x1040+0+0 tmp05.png
convert ${KEY}_fig06.png -crop 1240x1040+0+0 tmp06.png
convert ${KEY}_fig07.png -crop 1240x1040+0+0 tmp07.png
convert ${KEY}_fig08.png -crop 1240x1040+0+0 tmp08.png

# trim figure (remove white area)
convert FIGURES/box_VALSI.png -trim -bordercolor White -border 40 tmp09.png
convert legend.png            -trim -bordercolor White -border 20 tmp10.png
convert runidname.png         -trim -bordercolor White -border 20 tmp11.png

# compose the image
convert \( tmp01.png tmp02.png tmp03.png +append \) \
        \( tmp04.png tmp05.png tmp06.png +append \) \
        \( tmp07.png tmp08.png tmp09.png +append \) \
           tmp10.png tmp11.png -append -trim -bordercolor White -border 40 $KEY.png

# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp10.png FIGURES/${KEY}_legend.png
mv tmp11.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png

#display
#display -resize 30% $KEY.png
