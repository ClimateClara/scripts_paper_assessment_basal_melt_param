"""
Created on Wed Aug 10 14:10 2022
This script is to run tuning of the params, options read in from bash script: "run_generalized_tuning_script.sh"
@author: Clara Burgard
"""

import sys
import pandas as pd
import xarray as xr
import numpy as np

####### are we dealing with tides?
tide_opt = str(sys.argv[1])
if tide_opt == 'True':
    import assess_param_funcs.tuning_functions_tides as tf
elif tide_opt == 'False':
    import assess_param_funcs.tuning_functions as tf

#######

run_list = ['OPM006','OPM016','OPM018','OPM021'] 

inputpath_chunk_info = '/bettik/burgardc/DATA/BASAL_MELT_PARAM/interim/T_S_PROF/'
info_file = pd.read_csv(inputpath_chunk_info+'info_chunks.txt',header=None, index_col=0)

##### OPTIONS FROM TERMINAL


if sys.argv[2] == 'BT':
    tuning_approach='bootstrap' 
    
    geometry_info_2D, geometry_info_1D, isf_stack_mask, Nisf_all, file_TS_all, target_melt_all, box_1D_all, box_2D_all, idx_ds = tf.load_data_nemo_tuning_BT(run_list)
    
    tblock_dim = range(1,14)
    isf_dim = [10,11,12,13,18,22,23,24,25,30,31,33,38,39,40,42,43,44,45,47,48,51,52,53,54,55,58,61,65,66,69,70,71,73,75]
    
    np.random.seed(int(sys.argv[6]))
    
    # define the random bootstrap samples
    random_tblock_sample = np.sort(np.random.choice(tblock_dim, size=len(tblock_dim), replace=True))
    info_t = info_file.loc[random_tblock_sample].to_numpy()
    
    random_time_list = []
    rrun_list = []
    for tt in random_tblock_sample:
        run, tstart, tend = info_file.loc[tt]
        random_time_list.append(idx_ds['time'].where((idx_ds['run']==run) & (idx_ds['years']>=tstart) & (idx_ds['years']<=tend)).dropna(dim='time').values.astype(int))
        rrun_list.append(run)
    time_idx = np.concatenate(random_time_list,axis=0)

    final_run_list = []
    for rr in run_list:
        if rr in rrun_list:
            final_run_list.append(rr)

    random_isf_sample = np.random.choice(Nisf_all, size=len(isf_dim), replace=True)
    
elif sys.argv[2] == 'CV':
    tuning_approach='crossval'

    geometry_info_2D, geometry_info_1D, isf_stack_mask, Nisf_all, file_TS_all, target_melt_all, box_1D_all, box_2D_all, idx_ds = tf.load_data_nemo_tuning_BT(run_list)

    tblock_dim = np.arange(1,14).tolist()
    isf_dim = Nisf_all
    
    ####### are we dealing with leave-one-out cross-validation over time blocks?
    tblock_out = int(sys.argv[7])
    
    tblock_list = tblock_dim
    if tblock_out > 0:
        tblock_list.remove(tblock_out)

    random_time_list = []
    rrun_list = []
    for tt in tblock_list:
        run, tstart, tend = info_file.loc[tt]
        random_time_list.append(idx_ds['time'].where((idx_ds['run']==run) & (idx_ds['years']>=tstart) & (idx_ds['years']<=tend)).dropna(dim='time').values.astype(int))
        rrun_list.append(run)
    time_idx = np.concatenate(random_time_list,axis=0)

    final_run_list = []
    for rr in run_list:
        if rr in rrun_list:
            final_run_list.append(rr)

    ####### are we dealing with leave-one-out cross-validation over ice shelves?
    isf_out = int(sys.argv[6])
    if isf_out == 0:
        isf_out = False
        random_isf_sample = Nisf_all
        
    else:

        random_isf_sample = Nisf_all.drop_sel(Nisf=isf_out)
    
    ####
    
    
elif sys.argv[2] == 'ALL':
    
    tuning_approach='all_data'
    
    geometry_info_2D, geometry_info_1D, isf_stack_mask, Nisf_all, file_TS_all, target_melt_all, box_1D_all, box_2D_all, idx_ds = tf.load_data_nemo_tuning_BT(run_list)

    tblock_dim = np.arange(1,14).tolist()  
    tblock_list = tblock_dim

    random_time_list = []
    rrun_list = []
    for tt in tblock_list:
        run, tstart, tend = info_file.loc[tt]
        random_time_list.append(idx_ds['time'].where((idx_ds['run']==run) & (idx_ds['years']>=tstart) & (idx_ds['years']<=tend)).dropna(dim='time').values.astype(int))
        rrun_list.append(run)
    time_idx = np.concatenate(random_time_list,axis=0)

    final_run_list = []
    for rr in run_list:
        if rr in rrun_list:
            final_run_list.append(rr)


    random_isf_sample = Nisf_all


    
else:
    print(str(sys.argv[2]) + ' is an unusual command for the tuning approach, are you sure?')
    tuning_approach=str(sys.argv[2])
    

# always needs to be filled
option_param = str(sys.argv[3]) #linear, quadratic, plume, box
dom = int(sys.argv[4])

# if linear or qaudratic
if option_param in ['linear','quadratic']:
    simple_form = str(sys.argv[5]) #'quadratic_local', 'quadratic_local_cavslope', 'quadratic_local_locslope', quadratic_mixed_mean', 'quadratic_mixed_cavslope', 'quadratic_mixed_locslope' 
    plume_form = None
    nD_config = None
    pism_version = None

# if plume
elif option_param == 'plume':
    plume_form = str(sys.argv[5])
    simple_form = None
    nD_config = None
    pism_version = None
    picop_opt = None

# if box 
elif option_param == 'box':
    boxparam = sys.argv[5].split('_')
    nD_config = int(boxparam[0])
    pism_version = str(boxparam[1])
    picop_opt = str(boxparam[2])
    simple_form = None
    plume_form = None

if tide_opt == 'True':
    
    #### DOUBLE CHECK IF EVERYTHING WORKS!!
    tf.tuning_param_tides(option_param, tuning_approach, dom, 
                     file_TS_all, Nisf_all, u_tide_all, target_melt_all,
                     geometry_info_2D, geometry_info_1D, isf_stack_mask,
                     box_2D_all, box_1D_all, 
                     simple_form=simple_form, plume_form=plume_form, nD_config=nD_config, pism_version=pism_version)
else:
    
    #if tuning_approach == 'all_data':
    if tuning_approach == 'blabla':
    
        tf.tuning_param(option_param, tuning_approach, dom, 
                         file_TS_all, Nisf_all, target_melt_all,
                         geometry_info_2D, geometry_info_1D, isf_stack_mask,
                         box_2D_all, box_1D_all, 
                         plume_form=plume_form, nD_config=nD_config, pism_version=pism_version, picop_opt=picop_opt)
        
    else:
        #print('entered bootstrap')
        tf.tuning_param_BT(option_param, tuning_approach, dom, 
                 file_TS_all, random_isf_sample, time_idx, target_melt_all,
                 geometry_info_2D, geometry_info_1D, isf_stack_mask,
                 box_2D_all, box_1D_all, 
                 plume_form=plume_form, nD_config=nD_config, pism_version=pism_version, picop_opt=picop_opt,run_list=final_run_list)