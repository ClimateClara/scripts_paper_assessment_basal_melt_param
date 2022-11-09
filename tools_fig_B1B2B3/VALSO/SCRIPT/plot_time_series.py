import numpy as np
import glob
import netCDF4 as nc
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import sys
import re
import datetime as dt
import argparse
import pandas as pd
import matplotlib.dates as mdates
import matplotlib.ticker as ticker
import xarray as xr

# def class runid
class run(object):
    def __init__(self, runid):
        # var ?, file list ?, time_variable ?
        # parse dbfile
        self.runid, self.name, self.line, self.color = parse_dbfile(runid)

    def load_time_series(self, cfile, cvarregex, sf):
        # need to deal with mask, var and tag
        # need to do with the cdftools unit -> no unit !!!!
        # define time variable
        ctime = 'time_centered'

        ds=xr.open_mfdataset(cfile, parallel=True, concat_dim='time_counter',combine='nested').sortby(ctime)

        cvar = get_name(cvarregex,ds.keys())

        da=xr.DataArray(ds[cvar].values.squeeze()*sf, [(ctime, ds[ctime].values)], name=self.name)
        da[ctime] = da.indexes[ctime].to_datetimeindex()

        self.ts=da.to_dataframe()
        self.mean = self.ts[self.name].mean()
        self.std  = self.ts[self.name].std()
        self.min  = self.ts[self.name].min()
        self.max  = self.ts[self.name].max()

    def __str__(self):
        return 'runid = {}, name = {}, line = {}, color = {}'.format(self.runid, self.name, self.line, self.color)

def get_name(regex,varlst):
    """
    Purpose: return the variable inside a list that match a specific regex.
    
    Args:
        regex: regular expression for a variable name [string]
	varlst: list of possible variable name [string list]
        
    Return: 
	cvar: variable name matching the regex inside the variable name list 
              (if multiple matches, the first is return) [string]
    
    Raise:
        RuntimeError : in case no match is found between regex and variable name list
    """

    revar = re.compile(r'\b%s\b'%regex,re.I)
    cvar  = list(filter(revar.match, varlst))
    if (len(cvar) > 1):
        print(regex+' name list is longer than 1 or 0; error')
        print( cvar[0]+' is selected' )
    if (len(cvar) == 0):
        print( 'no match between '+regex+' and :' )
        print( varlst )
        raise RuntimeError('empty match')
    return cvar[0]

#=============================== obs management =================================
#class with mean,std,min,max
def load_obs(cfile):
    """
    Purpose: find mean and std inside a text file.
    
    Args:
        cfile : text file name [string]
        
    Return: 
        cmean: mean value [scalar]
        cstd : std  value [scalar]
    
    Raise:
        RuntimeError
    """

    print( 'open file '+cfile )
    try:
        with open(cfile) as fid:
            cmean = find_key('mean', fid)
            cstd  = find_key('std' , fid)
        return float(cmean), float(cstd)

    except:
        raise RuntimeError('mean and std keys not found in {}'.format(cfile))

def find_key(ckey, fid):
    """
    Purpose: find value of a specific key in an open text file (separator is a space character)
    
    Args:
        ckey: key variable you want to extract the value [string]
        fid : text file id where you want to find the key value [txt file id]
        
    Return: 
        cvar: the key value [scalar]
    
    Raise:
        RuntimeError : in case no match is found between regex and variable name list
    """

    for cline in fid:
        lmatch = re.findall(ckey, cline) 
        if (lmatch) :
            return cline.rstrip().strip('\n').split(' ')[-1]

    raise RuntimeError('empty match: key {} is not in the fid file'.format(ckey))
#================================================================================

# check argument
def load_argument():
    # deals with argument
    parser = argparse.ArgumentParser()
    parser.add_argument("-runid", metavar='runid list' , help="used to look information in runid.db"                  , type=str, nargs='+' , required=True )
    parser.add_argument("-f"    , metavar='file list'  , help="file list to plot (default is runid_var.nc)"           , type=str, nargs='+' , required=False)
    parser.add_argument("-var"  , metavar='var list'   , help="variable to look for in the netcdf file ./runid_var.nc", type=str, nargs='+' , required=True)
    parser.add_argument("-varf" , metavar='var list'   , help="variable to look for in the netcdf file ./runid_var.nc", type=str, nargs='+' , required=False)
    parser.add_argument("-title", metavar='title'      , help="subplot title (associated with var)"                   , type=str, nargs='+' , required=False)
    parser.add_argument("-dir"  , metavar='directory of input file' , help="directory of input file"                  , type=str, nargs=1   , required=False, default=['./'])
    parser.add_argument("-sf"  , metavar='scale factor', help="scale factor"                             , type=float, nargs='+'   , required=False)
    parser.add_argument("-o"    , metavar='figure_name', help="output figure name without extension"                  , type=str, nargs=1   , required=False, default=['output'])
    # flag argument
    parser.add_argument("-obs"  , metavar='obs mean and std file', help="obs mean and std file"          , type=str, nargs='+', required=False)
    parser.add_argument("-mean" , help="will plot model mean base on input netcdf file"                               , required=False, action="store_true")
    parser.add_argument("-noshow" , help="do not display the figure (only save it)"                                   , required=False, action="store_true")
    return parser.parse_args()

def output_argument_lst(cfile, arglst):
    """
    Purpose: write the command line in a text file
    
    Args:
        cfile : output text file name [string]
        arglst: list of arguments used in the command line [list of strings]
        
    Return: None
    
    Raise:
        RuntimeError : in case no match is found between regex and variable name list
    """
    try:
        fid = open(cfile, "w")
        fid.write('python '+' '.join(arglst))
        fid.close()
    except:
        raise RuntimeError('Error when trying to print the command line text file')

# ============================ plotting tools ==================================
def get_corner(ax):
    x0 = ax.get_position().x1
    x1 = x0+0.1
    y0 = ax.get_position().y0
    y1 = ax.get_position().y1
    return x0, x1, y0, y1

def get_ybnd(run_lst, omin, omax):
    rmin = omin; rmax = omax
    for irun in range(len(run_lst)):
        run  = run_lst[irun]
        rmin = min(rmin, run.ts[run.name].min())
        rmax = max(rmax, run.ts[run.name].max())
        rrange=np.abs(rmax-rmin)
    return rmin-0.05*rrange, rmax+0.05*rrange

def add_legend(lg, ax, ncol=3, lvis=True):
    lax = plt.axes([0.0, 0.0, 1, 0.15])
    lline, llabel = lg.get_legend_handles_labels()
    leg=plt.legend(lline, llabel, loc='upper left', ncol = ncol, fontsize=16, frameon=False)
    for item in leg.legendHandles:
        item.set_visible(lvis)
    lax.set_axis_off() 

def add_text(lg, ax, clabel, ncol=3, lvis=True):
    lax = plt.axes([0.0, 0.0, 1, 0.15])
    lline, llabel = lg.get_legend_handles_labels()
    leg=plt.legend(lline, clabel, loc='upper left', ncol = ncol, fontsize=16, frameon=False)
    for item in leg.legendHandles:
        item.set_visible(lvis)
    lax.set_axis_off() 

def add_legend_plot(lg):
    # build specific legend figure
    plt.figure(figsize=np.array([210*3, 210*3]) / 25.4)
    ax = plt.subplot(1, 1, 1)
    ax.axis('off')
    add_legend(lg,ax,ncol=10)
    plt.savefig('legend.png', format='png', dpi=150)

def add_text_plot(lg,rlst,rid):
    # build specific text figure
    plt.figure(figsize=np.array([210*3, 210*3]) / 25.4)
    ax = plt.subplot(1, 1, 1)
    ax.axis('off')
    clabel=['']*len(rid)
    for irun, runid in enumerate(rid):
        clabel[irun]=rlst[irun].name+' = '+runid
    add_text(lg,ax,clabel,ncol=10,lvis=False)
    plt.savefig('runidname.png', format='png', dpi=150)

# ========================== stat plot ============================
def tidyup_ax(ax, xmin, xmax, ymin, ymax):
    ax.set_ylim([ymin, ymax])
    ax.set_xlim([xmin, xmax])
    ax.set_yticklabels([])
    ax.set_xticks([])
    ax.grid()

def add_modstat(ax, run_lst):
    for irun in range(len(run_lst)):
        cpl = plt.errorbar(irun+1, run_lst[irun].mean, yerr=run_lst[irun].std, fmt='o', markeredgecolor=run_lst[irun].color, markersize=8, color=run_lst[irun].color, linewidth=2)

def add_obsstat(ax, mean, std):
    cpl = plt.errorbar(0, mean, yerr=std, fmt='*', markeredgecolor='k', markersize=8, color='k', linewidth=2)

# ============================ file parser =====================================
def parse_dbfile(runid):
    try:
        lstyle=False
        with open('style.db') as fid:
            for cline in fid:
                att=cline.split('|')
                if att[0].strip() == runid:
                    cpltrunid = att[0].strip()
                    cpltname  = att[1].strip()
                    cpltline  = att[2].strip()
                    cpltcolor = att[3].strip()
                    lstyle=True
        if not lstyle:
            print( runid+' not found in style.db' )
            raise Exception

    except Exception as e:
        print( 'Issue with file : style.db' )
        print( e )
        sys.exit(42)

    # return value
    return cpltrunid, cpltname, cpltline, cpltcolor
# ============================ file parser end =====================================

def main():

# load argument
    print('read args')
    args = load_argument()

# output argument list
    print('argument list')
    output_argument_lst(args.o[0]+'.txt', sys.argv)

# parse db file
    print('init var')
    nrun = len(args.runid)
    nvar = len(args.var)
    lg_lst   = [None]*nrun
    run_lst  = [None]*nrun
    ts_lst   = [None]*nrun ; style_lst = [None]*nrun ;
    ax       = [None]*nvar
    obs_mean = [None]*nvar; obs_std = [None]*nvar; obs_min = [999999.9]*nvar; obs_max = [-999999.9]*nvar
    rmin = [None]*nvar; rmax = [None]*nvar;

    print('parse db')
    for irun, runid in enumerate(args.runid):
        # initialise run
        run_lst[irun] = run(runid)

    print('init figure')
    plt.figure(figsize=np.array([210, 210]) / 25.4)
 
# need to deal with multivar
    print('get min/max possible range')
    mintime=dt.date.max
    maxtime=dt.date.min
    ymin=-sys.float_info.max
    ymax=sys.float_info.max

    if args.sf:
        sf=args.sf
    else:
        sf=np.ones(shape=(len(args.var),))
       

    for ivar, cvar in enumerate(args.var):
        # load obs
        if args.obs:
            print('load obs')
            obs_mean[ivar], obs_std[ivar] = load_obs(args.obs[ivar])
            obs_min[ivar] = obs_mean[ivar]-obs_std[ivar]
            obs_max[ivar] = obs_mean[ivar]+obs_std[ivar]
 
        print('load data and plot')
        ax[ivar] = plt.subplot(nvar, 1, ivar+1)
        for irun, runid in enumerate(args.runid):

            # load data
            if args.f:
                # in case only one file pattern given
                if len(args.f) == 1 :
                    fglob = args.f[0]
                else :
                    fglob = args.f[irun]
                cfile = glob.glob(args.dir[0]+'/'+runid+'/'+fglob)
                if len(cfile)==0:
                    print( 'no file found with this pattern '+args.dir[0]+'/'+runid+'/'+fglob )
                    sys.exit(42)
            elif args.varf:
               # in case only one file pattern given
                if len(args.varf) == 1 :
                    fglob = args.varf[0]
                else :
                    fglob = args.varf[ivar]
                cfile = glob.glob(args.dir[0]+'/'+runid+'/'+fglob)
                if len(cfile)==0:
                    print( 'no file found with this pattern '+args.dir[0]+'/'+runid+'/'+fglob )
                    sys.exit(42)
            else:
                cfile = glob.glob(args.dir[0]+'/'+runid+'_'+cvar+'.nc')
                if len(cfile)==0:
                    print( 'no file found with this pattern '+args.dir[0]+'/'+runid+'_'+cvar+'.nc' )
                    sys.exit(42)

            run_lst[irun].load_time_series(cfile, cvar, sf[ivar])
            ts_lst[irun] = run_lst[irun].ts
            lg = ts_lst[irun].plot(ax=ax[ivar], legend=False, style=run_lst[irun].line, color=run_lst[irun].color, label=run_lst[irun].name, x_compat=True, linewidth=2, rot=0)
            #
            # limit of time axis
            mintime=min([mintime,ts_lst[irun].index[0]])
            maxtime=max([maxtime,ts_lst[irun].index[-1]])

        # set title
        if (args.title):
            ax[ivar].set_title(args.title[ivar],fontsize=20)

        # set x axis
        ax[ivar].tick_params(axis='both', labelsize=16)
        if (ivar != nvar-1):
            ax[ivar].set_xticklabels([])
        else:
            ax[ivar].xaxis.set_major_formatter(mdates.DateFormatter('%Y'))

        for lt in ax[ivar].get_xticklabels():
            lt.set_ha('center')
 
        rmin[ivar],rmax[ivar]=get_ybnd(run_lst,obs_min[ivar],obs_max[ivar])
        ax[ivar].set_ylim([rmin[ivar],rmax[ivar]])
        ax[ivar].set_xlabel('')
        ax[ivar].grid()
 
    # tidy up space
    plt.subplots_adjust(left=0.1, right=0.8, bottom=0.2, top=0.92, wspace=0.3, hspace=0.3)

    # add legend
    add_legend(lg,ax[nvar-1])

    print('add obs')
    if args.mean or args.obs:
        xmin = 0 ; xmax = 0
        for ivar, cvar in enumerate(args.var):
            x0, x1, y0, y1=get_corner(ax[ivar])    
            cax = plt.axes([x0+0.01, y0, x1-x0, y1-y0])
            # plot obs mean
            if args.obs:
                xmin = min(xmin, -1)
                xmax = max(xmax,  1)
                add_obsstat(cax, obs_mean[ivar], obs_std[ivar])
            # plot mean model
            if args.mean:
                xmax = max(xmax, len(run_lst)+1)
                # rebuild run_lst for the mean (not optimale but fast enough for the application)
                ### should not be useful as already loaded
		###for irun, runid in enumerate(args.runid):
                    # load data
                ###    cfile = args.dir[0]+'/'+runid+'_'+cvar+'.nc'
                ###    run_lst[irun].load_time_series(cfile, cvar)
                # add mean and std
                add_modstat(cax, run_lst)
            # set min/max/grid ...
            tidyup_ax(cax, xmin, xmax, rmin[ivar], rmax[ivar])

    plt.savefig(args.o[0]+'.png', format='png', dpi=150)

    if args.noshow: 
       pass
    else:
       plt.show()

    # build specific legend figure
    add_legend_plot(lg)

    # build specific text figure
    add_text_plot(lg,run_lst,args.runid)

if __name__=="__main__":
    main()
