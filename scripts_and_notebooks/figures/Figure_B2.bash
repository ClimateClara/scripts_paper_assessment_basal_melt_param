#!/bin/bash
#set -x
python ./tools_fig_B1B2B3/PyChart/pychart.py \
 --mapf eORCA025.L121-OPM021/eORCA025.L121-OPM021_y1999.10y_gridT.nc \
        eORCA025.L121-OPM018/eORCA025.L121-OPM018_y1999.10y_gridT.nc \
        eORCA025.L121-OPM016/eORCA025.L121-OPM016_y1999.10y_gridT.nc \
        eORCA025.L121-OPM006/eORCA025.L121-OPM006_y1999.10y_gridT.nc \
 --mapreff eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2/eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2_1y_y0001_bottom-gridT.nc \
        eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2/eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2_1y_y0001_bottom-gridT.nc \
        eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2/eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2_1y_y0001_bottom-gridT.nc \
        eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2/eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2_1y_y0001_bottom-gridT.nc \
 --mapv    sosbt    \
 --maprefv    sosbt    \
 --mapjk  0         \
 --cbn    RdBu_r   \
 --cblvl  -1.1 1.1   0.2 \
 --cbu    C          \
 --cbext  both       \
 --mask   eORCA025.L121-OPM021/mask.nc eORCA025.L121-OPM018/mask.nc eORCA025.L121-OPM016/mask.nc eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2/mask.nc \
 --ft     'Bottom CT (1999-2008)' \
 --spfid  'REALISTIC' 'COLDAMU' 'WARMROSS' 'HIGHGETZ' \
 --sprid  'WOA2018' 'WOA2018' 'WOA2018' 'WOA2018'     \
 --sp     2x2 \
 -o       BOTT_BURGARD_diff \
 -p       ant \
 --joffset -2

python ./tools_fig_B1B2B3/PyChart/pychart.py \
 --mapf eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2/eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2_1y_y0001_bottom-gridT.nc \
 --mapv    sosbt    \
 --mapjk  0         \
 --cbn    viridis  \
 --cblvl  -1.7 1.6   0.4 \
 --cbu    C          \
 --cbext  both       \
 --mask   eORCA025.L121-WOA2018_c3.0_d1.0_v19812010.5.2/mask.nc \
 --ft     '' \
 --spfid  'e) WOA2018 (1980-2010)' \
 --sp     2x2 \
 -o       BOTT_BURGARD \
 -p       ant \
 --joffset -2
