#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ~/.bashrc
. PARAM/param_arch.bash
load_python

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}

# ISF
i=0
for ISF in GETZ TWAI PINE; do
   echo "plot total $ISF melt time series"
   i=$((i+1))
   python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ISF_ALL*${FREQ}*.nc -var "(isfmelt_${ISF})" -title "${ISF} total melt (Gt/y)"   -sf -1.0 -dir ${WRKPATH} -o ${KEY}_fig0${i} -obs OBS/${ISF}_obs.txt
   if [[ $? -ne 0 ]]; then exit 42; fi
done

for AREA in GETZ AMUS BELING WPEN; do
   i=$((i+1))
   ifig=`printf %02d $i`
   echo "plot mean bot T (${AREA}) time series"
   python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ${AREA}*thetao*${FREQ}*T.nc   -var '(mean_sosbt_tmask|mean_sbt_tmask)' -title "Mean bot. temp. ${AREA} (C)" -dir ${WRKPATH} -o ${KEY}_fig${ifig} -obs OBS/${AREA}_botT_mean_obs.txt
   if [[ $? -ne 0 ]]; then exit 42; fi
done

i=8
for AREA in GETZ AMUS BELING WPEN; do
   i=$((i+1))
   ifig=`printf %02d $i`
   echo "plot mean bot S (${AREA}) time series"
   python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f ${AREA}*so*${FREQ}*T.nc   -var '(mean_sosbs_tmask|mean_sbs_tmask)' -title "Mean bot. sal. ${AREA} (g/kg)" -dir ${WRKPATH} -o ${KEY}_fig${ifig} -obs OBS/${AREA}_botS_mean_obs.txt
   if [[ $? -ne 0 ]]; then exit 42; fi
done

i=$((i+1))
echo 'plot SIE time series'
set -x
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -varf 'AMUXL*sie*m02*.nc' 'AMUXL*sie*m09*.nc' -var SExnsidc SExnsidc -sf 0.001 0.001 -title "SIE AMUXL m02 [1e6 km2]" "SIE AMUXL m09 [1e6 km2]" -dir ${WRKPATH} -o ${KEY}_fig13
if [[ $? -ne 0 ]]; then exit 42; fi

# crop figure (rm legend)
convert ${KEY}_fig01.png -crop 1240x1040+0+0 tmp01.png
convert ${KEY}_fig02.png -crop 1240x1040+0+0 tmp02.png
convert ${KEY}_fig03.png -crop 1240x1040+0+0 tmp03.png

convert ${KEY}_fig04.png -crop 1240x1040+0+0 tmp04.png
convert ${KEY}_fig05.png -crop 1240x1040+0+0 tmp05.png
convert ${KEY}_fig06.png -crop 1240x1040+0+0 tmp06.png
convert ${KEY}_fig07.png -crop 1240x1040+0+0 tmp07.png

convert ${KEY}_fig09.png -crop 1240x1040+0+0 tmp09.png
convert ${KEY}_fig10.png -crop 1240x1040+0+0 tmp10.png
convert ${KEY}_fig11.png -crop 1240x1040+0+0 tmp11.png
convert ${KEY}_fig12.png -crop 1240x1040+0+0 tmp12.png

convert ${KEY}_fig13.png -crop 1240x1040+0+0 tmp13.png

# trim figure (remove white area)
convert FIGURES/box_VALAMU.png -trim -bordercolor White -border 40 tmp08.png
convert legend.png             -trim -bordercolor White -border 20 tmp14.png
convert runidname.png          -trim -bordercolor White -border 20 tmp15.png

# compose the image
        #\( tmp04.png tmp05.png tmp06.png +append \) \
convert \( tmp01.png tmp02.png tmp03.png +append \) \
        \( tmp04.png tmp05.png tmp08.png +append \) \
        \( tmp09.png tmp10.png tmp13.png +append \) \
        \( tmp06.png tmp07.png           +append \) \
        \( tmp11.png tmp12.png           +append \) \
           tmp14.png tmp15.png -append -trim -bordercolor White -border 40 $KEY.png

# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp10.png FIGURES/${KEY}_legend.png
mv tmp11.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png

