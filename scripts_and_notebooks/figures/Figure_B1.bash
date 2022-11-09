#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name), [FREQ] (1y or 1m) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ./param.bash

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}
echo $RUNIDS

WRKPATH=/work/pmathiot/DATA_BURGARD_2021
# ROSS GYRE
echo 'plot Ross Gyre time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *RG*${FREQ}*psi.nc -var max_sobarstf -title "b) Ross Gyre (Sv)" -dir ${WRKPATH} -o ${KEY}_RG -sf 0.000001 -obs OBS/RG_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# WED GYRE
echo 'plot Weddell Gyre time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WG*${FREQ}*psi.nc -var max_sobarstf -title "a) Weddell Gyre (Sv)" -dir ${WRKPATH} -o ${KEY}_WG -sf 0.000001 -obs OBS/WG_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ACC
echo 'plot ACC time series'
set -x
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *ACC*${FREQ}*.nc -var vtrp -sf -1 -title "c) ACC transport (Sv)" -dir ${WRKPATH} -o "${KEY}_ACC" -obs OBS/ACC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# FRIS
echo 'plot total FRIS time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_FRIS)' -title "d) FRIS total melt (Gt/y)" -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig01 -obs OBS/FRIS_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ROSS
echo 'plot total ROSS melt time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_ROSS)' -title "e) ROSS total melt (Gt/y)"  -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig02  -obs OBS/ROSS_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# PINE
echo 'plot total PINE G melt time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_PINE)' -title "f) PIG total melt (Gt/y)"   -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig03  -obs OBS/PINE_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# TOTAL
echo 'plot total TOTAL melt time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var '(isfmelt_TOTA)' -title "g) ANT (isf) total melt (Gt/y)"  -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig07  -obs OBS/ANT_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# SIE 02
echo 'plot 09 SIE time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f 'GLO*sie*m02*.nc' -var SExnsidc -sf 0.001 -title "h) SIE Antarctic m02 (1e6 km2)" -dir ${WRKPATH} -o ${KEY}_fig08 -obs OBS/ANT_sie02_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# SIE 09
echo 'plot 09 SIE time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f 'GLO*sie*m09*.nc' -var SExnsidc -sf 0.001 -title "i) SIE Antarctic m09 (1e6 km2)" -dir ${WRKPATH} -o ${KEY}_fig09 -obs OBS/ANT_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# HSSW ROSS
# mean S WROSS
echo 'plot mean bot S (WROSS) time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WROSS*so*${FREQ}*T.nc -var '(mean_sosbs|mean_vosaline)' -title "j) Mean bot. sal. WROSS (g/kg)" -dir ${WRKPATH} -o ${KEY}_WROSS_mean_bot_so -obs OBS/WROSS_botS_mean_obs.txt

# mean S WWED
if [[ $? -ne 0 ]]; then exit 42; fi
echo 'plot mean bot S (WWED) time series'
python ./tools_fig_B1B2B3/VALSO/SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *WED*so*${FREQ}*T.nc   -var '(mean_sosbs|mean_vosaline)' -title "k) Mean bot. sal. WWED  (g/kg)" -dir ${WRKPATH} -o ${KEY}_WWED_mean_bot_so  -obs OBS/WWED_botS_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# crop figure (rm legend)
convert ${KEY}_WG.png                    -crop 1240x1040+0+0 tmp01.png
convert ${KEY}_RG.png                    -crop 1240x1040+0+0 tmp02.png
convert ${KEY}_ACC.png                   -crop 1240x1040+0+0 tmp03.png
convert ${KEY}_fig01.png                 -crop 1240x1040+0+0 tmp04.png
convert ${KEY}_fig02.png                 -crop 1240x1040+0+0 tmp05.png
convert ${KEY}_fig03.png                 -crop 1240x1040+0+0 tmp06.png
convert ${KEY}_fig07.png                 -crop 1240x1040+0+0 tmp07.png
convert ${KEY}_fig08.png                 -crop 1240x1040+0+0 tmp08.png
convert ${KEY}_fig09.png                 -crop 1240x1040+0+0 tmp09.png
convert ${KEY}_WROSS_mean_bot_so.png     -crop 1240x1040+0+0 tmp10.png
convert ${KEY}_WWED_mean_bot_so.png      -crop 1240x1040+0+0 tmp11.png

# trim figure (remove white area)
convert FIGURES/box_BURGARD.png -trim -bordercolor White -border 40 tmp12.png
convert legend.png      -trim -bordercolor White -border 20 tmp13.png
convert runidname.png   -trim -bordercolor White -border 20 tmp14.png

# compose the image
convert \( tmp01.png tmp02.png tmp03.png +append \) \
        \( tmp04.png tmp05.png tmp06.png +append \) \
        \( tmp07.png tmp08.png tmp09.png +append \) \
        \( tmp10.png tmp11.png tmp12.png +append \) \
           tmp13.png tmp14.png -append -trim -bordercolor White -border 40 $KEY.png

# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp13.png FIGURES/${KEY}_legend.png
mv tmp14.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png

#display
#display -resize 30% $KEY.png
