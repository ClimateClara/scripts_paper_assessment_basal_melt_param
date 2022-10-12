# VALSO

## Purpose
* This toolbox only assess the order 0 of the southern ocean circulation :
   * ACC
   * Weddell gyre
   * Ross gyre strength
   * Salinity of HSSW 
   * Intrusion of CDW in Amundsen sea
   * Intrusion of CDW on East Ross shelf
   * AMOC
   * MHT
   * NWC sst
   * ISF melt
   * NH/SH sea ice extent (summer and winter)

* Compare simulated metrics with what is called a good-enough simulation (this range is estimated from expert judgements not observation dataset)

![Alt text](FIGURES/example.png?raw=true "Example of the VALSO output")

## Limitation
* only work on Occigen computer
* plot should not be used for publication as it is (std and mean value of observation should be corrected if you want to do so)
* need to find a better method for plotting management (maybe an xml file with all available output)

## Installation
Simplest instalation (maybe not the most optimal)
* install the CDFTOOLS at v3.0.2-355-g66ce3da :
```
   git clone https://github.com/pmathiot/CDFTOOLS_4.0_ISF.git
```
* ckeckout the VALSO directory
```
   git clone https://github.com/pmathiot/VALSO.git
```
* install python valso environment
```
  conda env create -f valso.yml 
```
* edit param.bash to fit your setup/need
   * path of the toolbox (`$EXEPATH`)
   * path of the processing directory (`$WRKPATH`) 
   * path of the CDFTOOLS version 4.0 bin drectory (`$CDFPATH`)
* edit `PARAM/param_CONFIG.bash` (`$CONFIG`, `$RUNID`, `$FREQ`, `$GRID` are automatically filled during the run, so they can be used in param_CONFIG.bash). Rename the file with the correct CONFIG name (eORCA025.L121 in my case).
   * path of the mask file (`$MSKPATH`) and the corresponding mask name (`$MSHMSK`, `$SUBMSK`, `$ISFMSK` and `$ISFLST`)
   * path of storage location (`$STOPATH`)
   * path where the simulation processing location is done (`$DATPATH`)
   * template for the file name (`$NEMOFILE`)
   * edit `get_nemofile` function to match your output name.
   * edit `get_tag` function to match your output name.

* the module required are the one used to compiled the CDFTOOLS and nco 

## Usage
* define your style for each simulation (file style.db)
* `./run_all.bash [CONFIG] [YEARB] [YEARE] [FREQ (1y or 1m)] [RUNID list]` as example : 
```
./run_all.bash eORCA025.L121 1976 1977 1y OPM006 OPM007
```
will proceed the year 1976 to 1977 for runid OPM006 and OPM007 of configuration eORCA025.L121

Once this is done and if no error or minor errors 
(ie for example we ask from 2000 to 2020 
but some simulation only span between 2010 and 2020. In this case no data will be built for the period 2000 2009 but error will show up)

you can now build the plot for the Southern Ocean:
* activate your valso python environment:
```
   conda activate valso
```
* `./run_plot_VALSO.bash [KEY] [FREQ] [RUNID list]` as example : 
```
./run_plot_VALSO.bash output_name 1y eORCA025.L121-OPM006 eORCA025.L121-OPM007
```
The script will look for file with a generic pattern and plot all the available data.
* You can also run with a similar command VALGLO, VALSI and VALAMU.

## Output
* figure [KEY].png

Other output : 
* all individual time series are saved in FIGURES along with the txt file describing the exact command line done to build it

## To add a new diag
* build a new script in SCRIPT or modify one (for exemple if you want another area for the bottomT time series, update `mk_bot.bash` to add it)
If a new script is added you need also to:
  * add a logical flag in param
  * update `run_all.sh`
Then:
* build a new run_plot script based on the existing one
