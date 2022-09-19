"""
Created Fri Feb 11 2022 16:22

Centralising tuning functions

Author: @claraburgard
"""

import xarray as xr
import numpy as np
import basal_melt_param.melt_functions as meltf
import basal_melt_param.useful_functions as uf
from basal_melt_param.constants import *
import datetime
from scipy.optimize import least_squares, minimize


def melt_Gt_yr(x, option_param, nisf_list, 
                T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                box_charac_all_2D, box_charac_all_1D, nD_config=None, gamma_tuned=None, C_tuned=None, 
                pism_version='no', picop_opt='no',
                xarr=False):
    
    list_1D = []
    
    #print(option_param, picop_opt)
    
    ### OPTIONS PLUME
    if (option_param == 'plume') and (picop_opt == 'no'):
        
        C=None
        ang_opt = 'lazero'
        gamma_plume=None
        picop_opt0 = 'no'
        
        if xarr:
            gamma = x.sel(p=0)
            E0 = x.sel(p=1)
        else:
            gamma = x[0]
            E0 = x[1]
            
    ### OPTION BOXES        
    elif (option_param == 'box') and (picop_opt == 'no'):
                
        E0=None
        ang_opt = 'appenB'
        gamma_plume=None
        picop_opt0 = 'no'
        
        if xarr:
            gamma = x.sel(p=0)*10**-5
            C = x.sel(p=1)*10**6
        else:
            gamma = x[0]*10**-5
            C = x[1]*10**6

    ### OPTION PICOP
    elif picop_opt == 'yes':
                
        ang_opt = 'appenB'
        #ang_opt = 'lazero'
        picop_opt0 = '2019'
        
        #tuned box parameters
        gamma = gamma_tuned
        C = C_tuned
        
        if xarr:
            gamma_plume = x.sel(p=0)
            E0 = x.sel(p=1)
        else:
            gamma_plume = x[0]
            E0 = x[1]

    
    for n, nrun in enumerate(T_S_profile.nemo_run):

        filled_TS = T_S_profile.sel(nemo_run=nrun).ffill('depth').dropna(how='all',dim='time')
        
        
        ds_1D_out = meltf.calculate_melt_rate_Gt_and_box1_all_isf(nisf_list, filled_TS, 
                                                                  geometry_info_2D.sel(nemo_run=nrun), 
                                                                  geometry_info_1D.sel(nemo_run=nrun),
                                                                  isf_stack_mask.sel(nemo_run=nrun), 
                                                                  mparam, 
                                                                  gamma, 
                                                                  U_param=False, 
                                                                  C=C, E0=E0, angle_option=ang_opt,
                                                                  box_charac_2D=box_charac_all_2D.sel(nemo_run=nrun),
                                                                  box_charac_1D=box_charac_all_1D.sel(nemo_run=nrun),
                                                                  box_tot=nD_config, box_tot_option='nD_config',
                                                                  pism_version=pism_version, picop_opt=picop_opt0,
                                                                  gamma_plume=gamma_plume, T_corrections=False,
                                                                  tuning_mode=True, verbose=False)
        
        if T_S_profile.time.max() > 1000:
            ds_1D = ds_1D_out['melt_1D_Gt_per_y'].assign_coords({'time': np.arange(1,len(ds_1D_out.time)+1)+n*50})
        else:
            ds_1D = ds_1D_out['melt_1D_Gt_per_y']
        list_1D.append(ds_1D)
    
    ds_1D_all = xr.concat(list_1D, dim='time')
        
    return ds_1D_all



def jacobian_func(x, option_param, out_opt, nisf_list, 
                  T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, target_melt,
                  box_charac_all_2D, box_charac_all_1D, nD_config, 
                  gamma_tuned=None, C_tuned=None,
                  pism_version='no', picop_opt='no', verbose=False):
        
    if (option_param == 'plume') or (picop_opt == 'yes'):
        delta = xr.DataArray(data=np.array([0.00001, 0.00001]), dims=['p'])
    elif (option_param == 'box') and (picop_opt == 'no'):
        delta = xr.DataArray(data=np.array([0.000001, 0.000001]), dims=['p'])
    delta = delta.assign_coords({'p': np.arange(2)})
    
    theta = xr.DataArray(data=x, dims=['p'])
    theta = theta.assign_coords({'p': np.arange(2)})  
    
    theta_p2 = theta.rename({'p':'p2'})
    theta_br, _ = xr.broadcast(theta,theta_p2)

    delta_id = xr.DataArray(data=delta.values * np.identity(len(theta)), dims=['p','p2'])
    
    theta_disturbed = [theta_br+delta_id, theta_br-delta_id]   
    xr_thetas = xr.concat(theta_disturbed, dim='perturb')
    xr_thetas = xr_thetas.assign_coords({'perturb': ['plus', 'minus']})
    
    da_1D = melt_Gt_yr(xr_thetas, option_param, nisf_list, 
                       T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                       box_charac_all_2D, box_charac_all_1D, nD_config, 
                       gamma_tuned, C_tuned,
                       pism_version=pism_version, picop_opt=picop_opt,
                       xarr=True)
    
    computed_melt_perturbed = da_1D.drop('p').rename({'p2':'p'})
    
    diff_y = (computed_melt_perturbed - target_melt.sel(Nisf=nisf_list))
    
    if (option_param == 'box') and (picop_opt == 'no'):
        rmse = np.sqrt((diff_y**2).mean(dim=['time','Nisf']))
        J_t = ((rmse.sel(perturb='plus') - rmse.sel(perturb='minus')))/((2 * delta))
        return J_t.values
    else:
        J_t = ((diff_y.sel(perturb='plus') - diff_y.sel(perturb='minus')))/((2 * delta))
        return J_t.stack(new_dim=('Nisf','time')).values.T
    
def jacobian_func_BT(x, option_param, out_opt, nisf_list, time_idx,
                  T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, target_melt,
                  box_charac_all_2D, box_charac_all_1D, nD_config, 
                  gamma_tuned=None, C_tuned=None,
                  pism_version='no', picop_opt='no', verbose=False):
        
    if (option_param == 'plume') or (picop_opt == 'yes'):
        delta = xr.DataArray(data=np.array([0.00001, 0.00001]), dims=['p'])
    elif (option_param == 'box') and (picop_opt == 'no'):
        delta = xr.DataArray(data=np.array([0.000001, 0.000001]), dims=['p'])
    delta = delta.assign_coords({'p': np.arange(2)})
    
    theta = xr.DataArray(data=x, dims=['p'])
    theta = theta.assign_coords({'p': np.arange(2)})  
    
    theta_p2 = theta.rename({'p':'p2'})
    theta_br, _ = xr.broadcast(theta,theta_p2)

    delta_id = xr.DataArray(data=delta.values * np.identity(len(theta)), dims=['p','p2'])
    
    theta_disturbed = [theta_br+delta_id, theta_br-delta_id]   
    xr_thetas = xr.concat(theta_disturbed, dim='perturb')
    xr_thetas = xr_thetas.assign_coords({'perturb': ['plus', 'minus']})
    
    da_1D = melt_Gt_yr(xr_thetas, option_param, nisf_list, 
                       T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                       box_charac_all_2D, box_charac_all_1D, nD_config, 
                       gamma_tuned, C_tuned,
                       pism_version=pism_version, picop_opt=picop_opt,
                       xarr=True)
    
    computed_melt_perturbed = da_1D.drop('p').rename({'p2':'p'})
    
    diff_y = (computed_melt_perturbed.sel(time=time_idx) - target_melt.sel(Nisf=nisf_list, time=time_idx))
    
    if (option_param == 'box') and (picop_opt == 'no'):
        rmse = np.sqrt((diff_y**2).mean(dim=['time','Nisf']))
        J_t = ((rmse.sel(perturb='plus') - rmse.sel(perturb='minus')))/((2 * delta))
        return J_t.values
    else:
        J_t = ((diff_y.sel(perturb='plus') - diff_y.sel(perturb='minus')))/((2 * delta))
        return J_t.stack(new_dim=('Nisf','time')).values.T


def resid_rmse_melt_Gt_yr(x, option_param, out_opt, nisf_list, 
                          T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                          target_melt, 
                          box_charac_all_2D, box_charac_all_1D, nD_config=None, 
                          gamma_tuned=None, C_tuned=None,
                          pism_version='no', picop_opt='no', verbose=False):
    
    computed_melt = melt_Gt_yr(x, option_param, nisf_list, 
                               T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                               box_charac_all_2D, box_charac_all_1D, nD_config, gamma_tuned, C_tuned, 
                               pism_version=pism_version, picop_opt=picop_opt)
    
    resid = (computed_melt - target_melt.sel(Nisf=nisf_list)).values.flatten()
    print('Current guess :', x)
    rmse = np.sqrt(np.mean(resid**2))
    print('RMSE :', rmse)
    #print(x, file=open(outputpath_plumes+'output_'+mparam+'.txt', 'a'))
    
    if out_opt == 'resid':
        return resid
    elif out_opt == 'rmse':
        return rmse
    
def resid_rmse_melt_Gt_yr_BT(x, option_param, out_opt, nisf_list, time_idx,
                          T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                          target_melt, 
                          box_charac_all_2D, box_charac_all_1D, nD_config=None, 
                          gamma_tuned=None, C_tuned=None,
                          pism_version='no', picop_opt='no', verbose=False):
    
    computed_melt = melt_Gt_yr(x, option_param, nisf_list, 
                               T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                               box_charac_all_2D, box_charac_all_1D, nD_config, gamma_tuned, C_tuned, 
                               pism_version=pism_version, picop_opt=picop_opt)
    
    resid = (computed_melt.sel(time=time_idx) - target_melt.sel(Nisf=nisf_list, time=time_idx)).values.flatten()
    print('Current guess :', x)
    rmse = np.sqrt(np.mean(resid**2))
    print('RMSE :', rmse)
    #print(x, file=open(outputpath_plumes+'output_'+mparam+'.txt', 'a'))
    
    if out_opt == 'resid':
        return resid
    elif out_opt == 'rmse':
        return rmse
    
def PICO_constraints(x, nisf_list, T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam,
                     angle_option='lazero',
                     box_charac_2D=None, box_charac_1D=None, nD_config=None, box_tot_option='box_nb_tot', 
                     pism_version='no', picop_opt='no',
                     verbose=False):
    
    #print('in', nD_config)
    
    gamma = x[0]*10**-5
    C = x[1]*10**6

    for n, nrun in enumerate(T_S_profile.nemo_run):
        
        filled_TS = T_S_profile.sel(nemo_run=nrun).ffill('depth').dropna(how='all',dim='time')
        
        melt_box1_list = []
        melt_box2_list = []
        
        for kisf in nisf_list:
            #print(kisf)
            #print(filled_TS)

            geometry_isf_2D = uf.choose_isf(geometry_info_2D.sel(nemo_run=nrun), isf_stack_mask.sel(nemo_run=nrun), kisf)
            
            melt_rate_2D_isf = meltf.calculate_melt_rate_2D_1isf(kisf, filled_TS, geometry_info_2D.sel(nemo_run=nrun), 
                                                                 geometry_info_1D.sel(nemo_run=nrun),
                                                                 isf_stack_mask.sel(nemo_run=nrun), 
                                                                 mparam, gamma, U_param=False,
                                                                 C=C, E0=None, angle_option='appenB', 
                                                                 box_charac_2D=box_charac_2D.sel(nemo_run=nrun), 
                                                                 box_charac_1D=box_charac_1D.sel(nemo_run=nrun),
                                                                 box_tot=nD_config, box_tot_option=box_tot_option,
                                                                 pism_version=pism_version,picop_opt=picop_opt,
                                                                 gamma_plume=None, T_corrections=False)
            
            box_nb_tot = box_charac_1D['nD_config'].sel(nemo_run=nrun).sel(Nisf=kisf).sel(config=nD_config).values
            box_location_isf = uf.choose_isf(box_charac_2D['box_location'].sel(nemo_run=nrun).sel(box_nb_tot=box_nb_tot), isf_stack_mask.sel(nemo_run=nrun), kisf)
            melt_isf = melt_rate_2D_isf * yearinsec
            isf_cell_area_weighted = geometry_isf_2D['grid_cell_area_weighted']

            box_nb = 1
            mean_melt_box1 = uf.weighted_mean(melt_isf.where(box_location_isf == box_nb),'mask_coord',isf_cell_area_weighted.where(box_location_isf == box_nb))
            if 'option' in mean_melt_box1.coords:
                mean_melt_box1 = mean_melt_box1.drop('option')
            melt_box1_list.append(mean_melt_box1)
            
            box_nb = 2
            mean_melt_box2 = uf.weighted_mean(melt_isf.where(box_location_isf == box_nb),'mask_coord',isf_cell_area_weighted.where(box_location_isf == box_nb))
            if 'option' in mean_melt_box2.coords:
                mean_melt_box2 = mean_melt_box2.drop('option')
            melt_box2_list.append(mean_melt_box2)

        melt_box1 = xr.concat(melt_box1_list, dim='Nisf')
        melt_box2 = xr.concat(melt_box2_list, dim='Nisf')

        min_melt_1 = melt_box1.min()

        diff_melt = melt_box1 - melt_box2
        min_diff = diff_melt.min()
        
        if min_melt_1 <= 0 or min_diff < 0:
            constraint = -1
            #print('out') 
            return constraint
        else:
            constraint = 1
    #print('out')    
    return constraint

def PICO_constraints_BT(x, nisf_list, T_S_profile, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam,
                     angle_option='lazero',
                     box_charac_2D=None, box_charac_1D=None, nD_config=None, box_tot_option='box_nb_tot', 
                     pism_version='no', picop_opt='no', time_idx=None, run_list=None,
                     verbose=False):
    
    #print('in', nD_config)
    
    gamma = x[0]*10**-5
    C = x[1]*10**6
    
    if not run_list:
        run_list = T_S_profile.nemo_run

    for n, nrun in enumerate(run_list):
        
        if time_idx is not None:
            filled_TS = T_S_profile.sel(nemo_run=nrun, time=time_idx).ffill('depth').dropna(how='all',dim='time')
        else:
            filled_TS = T_S_profile.sel(nemo_run=nrun).ffill('depth').dropna(how='all',dim='time')

        
        melt_box1_list = []
        melt_box2_list = []
        
        for kisf in nisf_list:
            #print(kisf)
            #print(filled_TS)

            geometry_isf_2D = uf.choose_isf(geometry_info_2D.sel(nemo_run=nrun), isf_stack_mask.sel(nemo_run=nrun), kisf)
            
            melt_rate_2D_isf = meltf.calculate_melt_rate_2D_1isf(kisf, filled_TS, geometry_info_2D.sel(nemo_run=nrun), 
                                                                 geometry_info_1D.sel(nemo_run=nrun),
                                                                 isf_stack_mask.sel(nemo_run=nrun), 
                                                                 mparam, gamma, U_param=False,
                                                                 C=C, E0=None, angle_option='appenB', 
                                                                 box_charac_2D=box_charac_2D.sel(nemo_run=nrun), 
                                                                 box_charac_1D=box_charac_1D.sel(nemo_run=nrun),
                                                                 box_tot=nD_config, box_tot_option=box_tot_option,
                                                                 pism_version=pism_version,picop_opt=picop_opt,
                                                                 gamma_plume=None, T_corrections=False)
            
            box_nb_tot = box_charac_1D['nD_config'].sel(nemo_run=nrun).sel(Nisf=kisf).sel(config=nD_config).values
            box_location_isf = uf.choose_isf(box_charac_2D['box_location'].sel(nemo_run=nrun).sel(box_nb_tot=box_nb_tot), isf_stack_mask.sel(nemo_run=nrun), kisf)
            melt_isf = melt_rate_2D_isf * yearinsec
            isf_cell_area_weighted = geometry_isf_2D['grid_cell_area_weighted']

            box_nb = 1
            mean_melt_box1 = uf.weighted_mean(melt_isf.where(box_location_isf == box_nb),'mask_coord',isf_cell_area_weighted.where(box_location_isf == box_nb))
            if 'option' in mean_melt_box1.coords:
                mean_melt_box1 = mean_melt_box1.drop('option')
            melt_box1_list.append(mean_melt_box1)
            
            box_nb = 2
            mean_melt_box2 = uf.weighted_mean(melt_isf.where(box_location_isf == box_nb),'mask_coord',isf_cell_area_weighted.where(box_location_isf == box_nb))
            if 'option' in mean_melt_box2.coords:
                mean_melt_box2 = mean_melt_box2.drop('option')
            melt_box2_list.append(mean_melt_box2)

        melt_box1 = xr.concat(melt_box1_list, dim='Nisf')
        melt_box2 = xr.concat(melt_box2_list, dim='Nisf')

        min_melt_1 = melt_box1.min()

        diff_melt = melt_box1 - melt_box2
        min_diff = diff_melt.min()
        
        if min_melt_1 <= 0 or min_diff < 0:
            constraint = -1
            #print('out') 
            return constraint
        else:
            constraint = 1
    #print('out')    
    return constraint
    

def load_data_nemo_tuning(run_list):
    file_isf_list = []
    file_other_list = []
    file_conc_list = []
    file_TS_list = []
    target_melt_list = []
    box_1D_list = []
    box_2D_list = []
    plume_list = []

    # make the domain a little smaller to make the computation even more efficient - file isf has already been made smaller at its creation
    map_lim = [-3000000,3000000]

    for n,nemo_run in enumerate(run_list):

        # File mask
        inputpath_mask = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/ANTARCTICA_IS_MASKS/nemo_5km_'+nemo_run+'/'
        file_isf_orig = xr.open_dataset(inputpath_mask+'nemo_5km_isf_masks_and_info_and_distance_new_oneFRIS.nc')
        nonnan_Nisf = file_isf_orig['Nisf'].where(np.isfinite(file_isf_orig['front_bot_depth_max']), drop=True).astype(int)
        file_isf_nonnan = file_isf_orig.sel(Nisf=nonnan_Nisf)
        large_isf = file_isf_nonnan['Nisf'].where(file_isf_nonnan['isf_area_here'] >= 2500, drop=True)
        file_isf = file_isf_nonnan.sel(Nisf=large_isf)
        file_isf_list.append(file_isf)

        inputpath_data='/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/NEMO_eORCA025.L121_'+nemo_run+'_ANT_STEREO/'
        file_other = xr.open_dataset(inputpath_data+'corrected_draft_bathy_isf.nc')#, chunks={'x': chunk_size, 'y': chunk_size})
        file_other_cut = uf.cut_domain_stereo(file_other, map_lim, map_lim)
        file_other_list.append(file_other_cut)

        file_conc = xr.open_dataset(inputpath_data+'isfdraft_conc_Ant_stereo.nc')
        file_conc_cut = uf.cut_domain_stereo(file_conc, map_lim, map_lim)
        file_conc_list.append(file_conc_cut)

        # Input profiles
        inputpath_profiles = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/T_S_PROF/nemo_5km_'+nemo_run+'/'
        file_TS_orig = xr.open_dataset(inputpath_profiles+'T_S_mean_prof_corrected_km_contshelf_and_offshore_1980-2018_oneFRIS.nc')
        file_TS = file_TS_orig.sel(Nisf=nonnan_Nisf)
        file_TS_list.append(file_TS)

        # File for target
        outputpath_melt = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/processed/MELT_RATE/nemo_5km_'+nemo_run+'/'
        NEMO_melt_rates_1D = xr.open_dataset(outputpath_melt+'melt_rates_1D_NEMO_oneFRIS.nc')
        target_melt_Gt_yr = NEMO_melt_rates_1D['melt_Gt_per_y_tot'].sel(Nisf=file_isf.Nisf)
        target_melt_Gt_yr = target_melt_Gt_yr.assign_coords({'time': np.arange(1,len(target_melt_Gt_yr.time)+1)+n*50})
        target_melt_list.append(target_melt_Gt_yr)

        # Box and plume characteristics
        inputpath_boxes = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/BOXES/nemo_5km_'+nemo_run+'/'
        box_charac_all_2D = xr.open_dataset(inputpath_boxes + 'nemo_5km_boxes_2D_oneFRIS.nc')
        box_2D_list.append(box_charac_all_2D)
        box_charac_all_1D = xr.open_dataset(inputpath_boxes + 'nemo_5km_boxes_1D_oneFRIS.nc')
        box_1D_list.append(box_charac_all_1D)

        inputpath_plumes = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/PLUMES/nemo_5km_'+nemo_run+'/'
        plume_charac = xr.open_dataset(inputpath_plumes+'nemo_5km_plume_characteristics_oneFRIS.nc')
        plume_list.append(plume_charac)

    file_isf_all = xr.concat(file_isf_list, dim='nemo_run')

    file_other_all = xr.concat(file_other_list, dim='nemo_run')
    file_conc_all = xr.concat(file_conc_list, dim='nemo_run')

    file_TS_all = xr.concat(file_TS_list, dim='nemo_run')

    target_melt_all = xr.concat(target_melt_list, dim='time')

    box_1D_all = xr.concat(box_1D_list, dim='nemo_run')
    box_2D_all = xr.concat(box_2D_list, dim='nemo_run')
    plume_charac_all = xr.concat(plume_list, dim='nemo_run')
    
    # Format the needed data
    file_isf_conc = file_conc_all['isfdraft_conc']

    xx = file_isf.x
    yy = file_isf.y
    dx = (xx[2] - xx[1]).values
    dy = (yy[2] - yy[1]).values
    grid_cell_area = abs(dx*dy)  
    grid_cell_area_weighted = file_isf_conc * grid_cell_area

    ice_draft_pos = file_other_all['corrected_isfdraft']
    ice_draft_neg = -ice_draft_pos
    
    param_var_of_int_2D = file_isf_all[['ISF_mask', 'latitude', 'longitude','dGL']]
    param_var_of_int_1D = file_isf_all[['front_bot_depth_max','front_bot_depth_avg']]

    geometry_info_2D = plume_charac_all.merge(param_var_of_int_2D).merge(ice_draft_pos).rename({'corrected_isfdraft':'ice_draft_pos'}).merge(grid_cell_area_weighted).rename({'isfdraft_conc':'grid_cell_area_weighted'}).merge(file_isf_conc)
    geometry_info_1D = param_var_of_int_1D
    
    # prepare the ice shelf masj
    isf_stack_mask = uf.create_stacked_mask(file_isf_all['ISF_mask'], file_isf_all.Nisf, ['y','x'], 'mask_coord')
    

    return geometry_info_2D, geometry_info_1D, isf_stack_mask, file_isf_all.Nisf, file_TS_all, target_melt_all, box_1D_all, box_2D_all

def load_data_nemo_tuning_CV(run_list, isf_list, tblock_run, tblock_start, tblock_end):
    file_isf_list = []
    file_other_list = []
    file_conc_list = []
    file_TS_list = []
    target_melt_list = []
    box_1D_list = []
    box_2D_list = []
    plume_list = []

    # make the domain a little smaller to make the computation even more efficient - file isf has already been made smaller at its creation
    map_lim = [-3000000,3000000]
    for n,nemo_run in enumerate(run_list):

        # File mask
        inputpath_mask = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/ANTARCTICA_IS_MASKS/nemo_5km_'+nemo_run+'/'
        file_isf_orig = xr.open_dataset(inputpath_mask+'nemo_5km_isf_masks_and_info_and_distance_new_oneFRIS.nc')
        file_isf = file_isf_orig.sel(Nisf=isf_list)
        file_isf_list.append(file_isf)

        inputpath_data='/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/NEMO_eORCA025.L121_'+nemo_run+'_ANT_STEREO/'
        file_other = xr.open_dataset(inputpath_data+'corrected_draft_bathy_isf.nc')#, chunks={'x': chunk_size, 'y': chunk_size})
        file_other_cut = uf.cut_domain_stereo(file_other, map_lim, map_lim)
        file_other_list.append(file_other_cut)

        file_conc = xr.open_dataset(inputpath_data+'isfdraft_conc_Ant_stereo.nc')
        file_conc_cut = uf.cut_domain_stereo(file_conc, map_lim, map_lim)
        file_conc_list.append(file_conc_cut)

        # Input profiles
        inputpath_profiles = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/T_S_PROF/nemo_5km_'+nemo_run+'/'
        file_TS_orig = xr.open_dataset(inputpath_profiles+'T_S_mean_prof_corrected_km_contshelf_and_offshore_1980-2018_oneFRIS.nc')
        if nemo_run == tblock_run:
            file_TS = file_TS_orig.sel(Nisf=isf_list).drop_sel(time=range(tblock_start,tblock_end+1))
        else:
            file_TS = file_TS_orig.sel(Nisf=isf_list)
        file_TS_list.append(file_TS)

        # File for target
        outputpath_melt = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/processed/MELT_RATE/nemo_5km_'+nemo_run+'/'
        NEMO_melt_rates_1D = xr.open_dataset(outputpath_melt+'melt_rates_1D_NEMO_oneFRIS.nc')
        if nemo_run == tblock_run:
            target_melt_Gt_yr = NEMO_melt_rates_1D['melt_Gt_per_y_tot'].sel(Nisf=isf_list).drop_sel(time=range(tblock_start,tblock_end+1))
        else:
            target_melt_Gt_yr = NEMO_melt_rates_1D['melt_Gt_per_y_tot'].sel(Nisf=isf_list)
        target_melt_Gt_yr = target_melt_Gt_yr.assign_coords({'time': np.arange(1,len(target_melt_Gt_yr.time)+1)+n*50})
        target_melt_list.append(target_melt_Gt_yr)

        # Box and plume characteristics
        inputpath_boxes = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/BOXES/nemo_5km_'+nemo_run+'/'
        box_charac_all_2D = xr.open_dataset(inputpath_boxes + 'nemo_5km_boxes_2D_oneFRIS.nc')
        box_2D_list.append(box_charac_all_2D)
        box_charac_all_1D = xr.open_dataset(inputpath_boxes + 'nemo_5km_boxes_1D_oneFRIS.nc')
        box_1D_list.append(box_charac_all_1D)

        inputpath_plumes = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/PLUMES/nemo_5km_'+nemo_run+'/'
        plume_charac = xr.open_dataset(inputpath_plumes+'nemo_5km_plume_characteristics_oneFRIS.nc')
        plume_list.append(plume_charac)

    file_isf_all = xr.concat(file_isf_list, dim='nemo_run')

    file_other_all = xr.concat(file_other_list, dim='nemo_run')
    file_conc_all = xr.concat(file_conc_list, dim='nemo_run')

    file_TS_all = xr.concat(file_TS_list, dim='nemo_run')

    target_melt_all = xr.concat(target_melt_list, dim='time')

    box_1D_all = xr.concat(box_1D_list, dim='nemo_run')
    box_2D_all = xr.concat(box_2D_list, dim='nemo_run')
    plume_charac_all = xr.concat(plume_list, dim='nemo_run')
    
    # Format the needed data
    file_isf_conc = file_conc_all['isfdraft_conc']

    xx = file_isf.x
    yy = file_isf.y
    dx = (xx[2] - xx[1]).values
    dy = (yy[2] - yy[1]).values
    grid_cell_area = abs(dx*dy)  
    grid_cell_area_weighted = file_isf_conc * grid_cell_area

    ice_draft_pos = file_other_all['corrected_isfdraft']
    ice_draft_neg = -ice_draft_pos
    
    param_var_of_int_2D = file_isf_all[['ISF_mask', 'latitude', 'longitude','dGL']]
    param_var_of_int_1D = file_isf_all[['front_bot_depth_max','front_bot_depth_avg']]

    geometry_info_2D = plume_charac_all.merge(param_var_of_int_2D).merge(ice_draft_pos).rename({'corrected_isfdraft':'ice_draft_pos'}).merge(grid_cell_area_weighted).rename({'isfdraft_conc':'grid_cell_area_weighted'}).merge(file_isf_conc)
    geometry_info_1D = param_var_of_int_1D
    
    # prepare the ice shelf masj
    isf_stack_mask = uf.create_stacked_mask(file_isf_all['ISF_mask'], file_isf_all.Nisf, ['y','x'], 'mask_coord')
    

    return geometry_info_2D, geometry_info_1D, isf_stack_mask, file_isf_all.Nisf, file_TS_all, target_melt_all, box_1D_all, box_2D_all

def load_data_nemo_tuning_BT(run_list):
    file_isf_list = []
    file_other_list = []
    file_conc_list = []
    file_TS_list = []
    target_melt_list = []
    box_1D_list = []
    box_2D_list = []
    plume_list = []
    time_list = []
    
    # make the domain a little smaller to make the computation even more efficient - file isf has already been made smaller at its creation
    map_lim = [-3000000,3000000]

    for n,nemo_run in enumerate(run_list):

        # File mask
        inputpath_mask = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/ANTARCTICA_IS_MASKS/nemo_5km_'+nemo_run+'/'
        file_isf_orig = xr.open_dataset(inputpath_mask+'nemo_5km_isf_masks_and_info_and_distance_new_oneFRIS.nc')
        nonnan_Nisf = file_isf_orig['Nisf'].where(np.isfinite(file_isf_orig['front_bot_depth_max']), drop=True).astype(int)
        file_isf_nonnan = file_isf_orig.sel(Nisf=nonnan_Nisf)
        large_isf = file_isf_nonnan['Nisf'].where(file_isf_nonnan['isf_area_here'] >= 2500, drop=True)
        file_isf = file_isf_nonnan.sel(Nisf=large_isf)
        file_isf_list.append(file_isf)

        inputpath_data='/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/NEMO_eORCA025.L121_'+nemo_run+'_ANT_STEREO/'
        file_other = xr.open_dataset(inputpath_data+'corrected_draft_bathy_isf.nc')#, chunks={'x': chunk_size, 'y': chunk_size})
        file_other_cut = uf.cut_domain_stereo(file_other, map_lim, map_lim)
        file_other_list.append(file_other_cut)

        file_conc = xr.open_dataset(inputpath_data+'isfdraft_conc_Ant_stereo.nc')
        file_conc_cut = uf.cut_domain_stereo(file_conc, map_lim, map_lim)
        file_conc_list.append(file_conc_cut)

        # Input profiles
        inputpath_profiles = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/T_S_PROF/nemo_5km_'+nemo_run+'/'
        file_TS_orig = xr.open_dataset(inputpath_profiles+'T_S_mean_prof_corrected_km_contshelf_and_offshore_1980-2018_oneFRIS.nc')
        file_TS = file_TS_orig.sel(Nisf=nonnan_Nisf)
        file_TS = file_TS.assign_coords({'time': np.arange(1,len(file_TS.time)+1)+n*50})
        time_list.append(file_TS_orig.time.values)
        file_TS_list.append(file_TS)

        # File for target
        outputpath_melt = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/processed/MELT_RATE/nemo_5km_'+nemo_run+'/'
        NEMO_melt_rates_1D = xr.open_dataset(outputpath_melt+'melt_rates_1D_NEMO_oneFRIS.nc')
        target_melt_Gt_yr = NEMO_melt_rates_1D['melt_Gt_per_y_tot'].sel(Nisf=file_isf.Nisf)
        target_melt_Gt_yr = target_melt_Gt_yr.assign_coords({'time': np.arange(1,len(target_melt_Gt_yr.time)+1)+n*50})
        target_melt_list.append(target_melt_Gt_yr)

        # Box and plume characteristics
        inputpath_boxes = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/BOXES/nemo_5km_'+nemo_run+'/'
        box_charac_all_2D = xr.open_dataset(inputpath_boxes + 'nemo_5km_boxes_2D_oneFRIS.nc')
        box_2D_list.append(box_charac_all_2D)
        box_charac_all_1D = xr.open_dataset(inputpath_boxes + 'nemo_5km_boxes_1D_oneFRIS.nc')
        box_1D_list.append(box_charac_all_1D)

        inputpath_plumes = '/bettik/burgardc/SCRIPTS/basal_melt_param/data/interim/PLUMES/nemo_5km_'+nemo_run+'/'
        plume_charac = xr.open_dataset(inputpath_plumes+'nemo_5km_plume_characteristics_oneFRIS.nc')
        plume_list.append(plume_charac)

    file_isf_all = xr.concat(file_isf_list, dim='nemo_run')
    file_isf_all = file_isf_all.assign_coords({'nemo_run': run_list})

    file_other_all = xr.concat(file_other_list, dim='nemo_run')
    file_conc_all = xr.concat(file_conc_list, dim='nemo_run')
    file_other_all = file_other_all.assign_coords({'nemo_run': run_list})
    file_conc_all = file_conc_all.assign_coords({'nemo_run': run_list})

    file_TS_all = xr.concat(file_TS_list, dim='nemo_run')
    file_TS_all = file_TS_all.assign_coords({'nemo_run': run_list})


    target_melt_all = xr.concat(target_melt_list, dim='time')

    box_1D_all = xr.concat(box_1D_list, dim='nemo_run')
    box_2D_all = xr.concat(box_2D_list, dim='nemo_run')
    plume_charac_all = xr.concat(plume_list, dim='nemo_run')
    box_1D_all = box_1D_all.assign_coords({'nemo_run': run_list})
    box_2D_all = box_2D_all.assign_coords({'nemo_run': run_list})
    plume_charac_all = plume_charac_all.assign_coords({'nemo_run': run_list})
    
    yy_list = np.concatenate( time_list, axis=0 )
    
    # Format the needed data
    file_isf_conc = file_conc_all['isfdraft_conc']

    xx = file_isf.x
    yy = file_isf.y
    dx = (xx[2] - xx[1]).values
    dy = (yy[2] - yy[1]).values
    grid_cell_area = abs(dx*dy)  
    grid_cell_area_weighted = file_isf_conc * grid_cell_area

    ice_draft_pos = file_other_all['corrected_isfdraft']
    ice_draft_neg = -ice_draft_pos
    
    param_var_of_int_2D = file_isf_all[['ISF_mask', 'latitude', 'longitude','dGL']]
    param_var_of_int_1D = file_isf_all[['front_bot_depth_max','front_bot_depth_avg']]

    geometry_info_2D = plume_charac_all.merge(param_var_of_int_2D).merge(ice_draft_pos).rename({'corrected_isfdraft':'ice_draft_pos'}).merge(grid_cell_area_weighted).rename({'isfdraft_conc':'grid_cell_area_weighted'}).merge(file_isf_conc)
    geometry_info_1D = param_var_of_int_1D
    
    # prepare the ice shelf masj
    isf_stack_mask = uf.create_stacked_mask(file_isf_all['ISF_mask'], file_isf_all.Nisf, ['y','x'], 'mask_coord')
    
    n = 0
    n_list = ['OPM006']
    for tt in range(1,len(file_TS_all.time)):
        if (file_TS_all.time[tt] - file_TS_all.time[tt-1]) > 1:
            n = n + 1
        n_list.append(run_list[n])
    
    res_da_time = xr.DataArray(data=yy_list, dims= 'time', coords={'time': file_TS_all.time}).to_dataset(name='years')
    res_da_runs = xr.DataArray(data=n_list, dims= 'time', coords={'time': file_TS_all.time}).to_dataset(name='run')
    idx_ds = xr.merge([res_da_time,res_da_runs])
    
    return geometry_info_2D, geometry_info_1D, isf_stack_mask, file_isf_all.Nisf, file_TS_all, target_melt_all, box_1D_all, box_2D_all, idx_ds


    

def tuning_param(option_param, tuning_approach, dom, 
                 file_TS_all, Nisf_all, target_melt_all,
                 geometry_info_2D, geometry_info_1D, isf_stack_mask,
                 box_2D_all, box_1D_all, 
                 plume_form=None, nD_config=None, pism_version=None, picop_opt=None):
    
    if option_param == 'plume':
        if plume_form == None:
            print('You want plume but missing plume_form! This is it, I quit...')
            return
        else:
            mparam = plume_form
    elif option_param == 'box': 
        if nD_config == None:
            print('You want box but missing nD_config! This is it, I quit...')
            return
        elif pism_version == None:
            print('You want box but missing pism_version! This is it, I quit...')
            return
        elif picop_opt == None:
            print('You want box but missing picop_opt! This is it, I quit...')
            return
        else:
            mparam = 'boxes_'+str(nD_config)+'_pism'+pism_version+'_picop'+picop_opt


    #############

    if picop_opt == 'yes':
        tuned_box_gammas = xr.DataArray(np.array([[[0.39e-5,0.41e-5,0.44e-5,0.39e-5],
                                                      [0.39e-5,0.41e-5,0.44e-5,0.39e-5]],
                                                 [[0.51e-5,0.73e-5,0.92e-5,0.63e-5],
                                                      [0.51e-5,0.73e-5,0.92e-5,0.63e-5]]]
                                                ), dims={'profile_domain': np.array([50,1000]), 'pism': ['no','yes'], 'config': range(1,5)})
        tuned_box_gammas = tuned_box_gammas.assign_coords({'profile_domain': np.array([50,1000]),'pism': ['no','yes'], 'config': range(1,5)})

        tuned_box_Cs = xr.DataArray(np.array([[[16.5e6,18.0e6,20.7e6,20.7e6],
                                                      [16.1e6,17.8e6,20.5e6,20.5e6]],
                                            [[0.14e6,0.14e6,0.14e6,0.13e6],
                                                      [0.14e6,0.14e6,0.14e6,0.13e6]]]), dims={'profile_domain': np.array([50,1000]), 'pism': ['no','yes'], 'config': range(1,5)})
        tuned_box_Cs = tuned_box_Cs.assign_coords({'profile_domain': np.array([50,1000]),'pism': ['no','yes'], 'config': range(1,5)})
    
    ### RUN THE TUNING

    filled_TS = file_TS_all.sel(profile_domain=dom)

    if tuning_approach == 'BT':
        dim_size = Nisf_all.values
        random_nisf_sample = np.random.choice(dim_size, size=len(dim_size), replace=True)

    else:
        random_nisf_sample = Nisf_all.values

    time_start = datetime.datetime.now()
    print(time_start)
    print('Tuning approach = ', tuning_approach)  
    print('Param = ', mparam)     
    print('NISF = ',random_nisf_sample) 

    if (option_param == 'plume') or (picop_opt == 'yes'):

        if picop_opt == 'yes':

            gamma_pico = tuned_box_gammas.sel(pism=pism_version,config=nD_config, profile_domain=dom).values
            C = tuned_box_Cs.sel(pism=pism_version,config=nD_config, profile_domain=dom).values
            picop_opt='yes'

        else:

            gamma_pico = None
            C = None
            nD_config = None
            pism_version='no'
            picop_opt='no'

        first_guess = [gamma_eff_T_lazero, E0_lazero]

        res_tuning = least_squares(resid_rmse_melt_Gt_yr, first_guess, 
                                bounds=(10**-15, 1000), jac=jacobian_func, 
                                args=(option_param, 'resid', random_nisf_sample, 
                                      filled_TS, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam,  
                                      target_melt_all,
                                      box_2D_all, box_1D_all, nD_config, 
                                      gamma_pico, C, 
                                      pism_version, picop_opt), 
                                verbose=2)
    
    
    elif (option_param == 'box') and (picop_opt == 'no'):

        first_guess = [gT_star_pico*10**5, C_pico/10**6]

        # define the tuning bounds
        b_gamma = [0.000001, 30] #(5*10**-6, 3*10**-4)
        b_C = [0.1, 100]
        bnds = (b_gamma,b_C)

        # check the constraints (m1 > 0 and m2 <= m1)
        con1 = {'type':'ineq','fun': PICO_constraints, 
                'args': (random_nisf_sample, filled_TS, geometry_info_2D, geometry_info_1D, 
                         isf_stack_mask, mparam, 'appenB', box_2D_all, box_1D_all, nD_config, 'nD_config', 
                         pism_version, 'no', False)} # f(x) >= 0

        cons = [con1]

        res_tuning = minimize(resid_rmse_melt_Gt_yr, first_guess, method='SLSQP', 
                              bounds=bnds, constraints=cons, jac=jacobian_func,
                              args=(option_param, 'rmse', random_nisf_sample, 
                                    filled_TS, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                                    target_melt_all, 
                                    box_2D_all, box_1D_all, nD_config, 
                                    None, None, 
                                    pism_version, 'no', False),
                   options={'ftol': 10**-6})


    else:
        print("I AM CONFUSED, I DON'T KNOW THIS param_option") 

    print('FINAL RESULT = ',res_tuning.x)
    time_end = datetime.datetime.now()
    print(time_end)
    
    return
    


def tuning_param_BT(option_param, tuning_approach, dom, 
                 file_TS_all, Nisf_all, time_idx, target_melt_all,
                 geometry_info_2D, geometry_info_1D, isf_stack_mask,
                 box_2D_all, box_1D_all, 
                 plume_form=None, nD_config=None, pism_version=None, picop_opt=None, run_list=None):
    
    if option_param == 'plume':
        if plume_form == None:
            print('You want plume but missing plume_form! This is it, I quit...')
            return
        else:
            mparam = plume_form
    elif option_param == 'box': 
        if nD_config == None:
            print('You want box but missing nD_config! This is it, I quit...')
            return
        elif pism_version == None:
            print('You want box but missing pism_version! This is it, I quit...')
            return
        elif picop_opt == None:
            print('You want box but missing picop_opt! This is it, I quit...')
            return
        else:
            mparam = 'boxes_'+str(nD_config)+'_pism'+pism_version+'_picop'+picop_opt


    #############

    if picop_opt == 'yes':
        tuned_box_gammas = xr.DataArray(np.array([[[0.39e-5,0.41e-5,0.44e-5,0.39e-5],
                                                      [0.39e-5,0.41e-5,0.44e-5,0.39e-5]],
                                                 [[0.51e-5,0.73e-5,0.92e-5,0.63e-5],
                                                      [0.51e-5,0.73e-5,0.92e-5,0.63e-5]]]
                                                ), dims={'profile_domain': np.array([50,1000]), 'pism': ['no','yes'], 'config': range(1,5)})
        tuned_box_gammas = tuned_box_gammas.assign_coords({'profile_domain': np.array([50,1000]),'pism': ['no','yes'], 'config': range(1,5)})

        tuned_box_Cs = xr.DataArray(np.array([[[16.5e6,18.0e6,20.7e6,20.7e6],
                                                      [16.1e6,17.8e6,20.5e6,20.5e6]],
                                            [[0.14e6,0.14e6,0.14e6,0.13e6],
                                                      [0.14e6,0.14e6,0.14e6,0.13e6]]]), dims={'profile_domain': np.array([50,1000]), 'pism': ['no','yes'], 'config': range(1,5)})
        tuned_box_Cs = tuned_box_Cs.assign_coords({'profile_domain': np.array([50,1000]),'pism': ['no','yes'], 'config': range(1,5)})
    
    ### RUN THE TUNING

    filled_TS = file_TS_all.sel(profile_domain=dom)
    if tuning_approach == 'bootstrap':
        random_nisf_sample = Nisf_all
    else:
        random_nisf_sample = Nisf_all.values
    

    time_start = datetime.datetime.now()
    print(time_start)
    print('Tuning approach = ', tuning_approach)  
    print('Param = ', mparam)     
    print('NISF = ',random_nisf_sample) 
    #if tuning_approach == 'bootstrap':
    print('Time blocks = ',time_idx)

    if (option_param == 'plume') or (picop_opt == 'yes'):

        if picop_opt == 'yes':

            gamma_pico = tuned_box_gammas.sel(pism=pism_version,config=nD_config, profile_domain=dom).values
            C = tuned_box_Cs.sel(pism=pism_version,config=nD_config, profile_domain=dom).values
            picop_opt='yes'

        else:

            gamma_pico = None
            C = None
            nD_config = None
            pism_version='no'
            picop_opt='no'

        first_guess = [gamma_eff_T_lazero, E0_lazero]

        res_tuning = least_squares(resid_rmse_melt_Gt_yr_BT, first_guess, 
                                bounds=(10**-15, 1000), jac=jacobian_func_BT, 
                                args=(option_param, 'resid', random_nisf_sample, time_idx,
                                      filled_TS, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam,  
                                      target_melt_all,
                                      box_2D_all, box_1D_all, nD_config, 
                                      gamma_pico, C, 
                                      pism_version, picop_opt), 
                                verbose=2)
    
    
    elif (option_param == 'box') and (picop_opt == 'no'):

        first_guess = [gT_star_pico*10**5, C_pico/10**6]

        # define the tuning bounds
        b_gamma = [0.000001, 30] #(5*10**-6, 3*10**-4)
        b_C = [0.1, 100]
        bnds = (b_gamma,b_C)

        # check the constraints (m1 > 0 and m2 <= m1)
        con1 = {'type':'ineq','fun': PICO_constraints_BT, 
                'args': (random_nisf_sample, filled_TS, geometry_info_2D, geometry_info_1D, 
                         isf_stack_mask, mparam, 'appenB', box_2D_all, box_1D_all, nD_config, 'nD_config', 
                         pism_version, 'no', time_idx, run_list, False)} # f(x) >= 0

        cons = [con1]

        res_tuning = minimize(resid_rmse_melt_Gt_yr_BT, first_guess, method='SLSQP', 
                              bounds=bnds, constraints=cons, jac=jacobian_func_BT,
                              args=(option_param, 'rmse', random_nisf_sample, time_idx,
                                    filled_TS, geometry_info_2D, geometry_info_1D, isf_stack_mask, mparam, 
                                    target_melt_all, 
                                    box_2D_all, box_1D_all, nD_config, 
                                    None, None, 
                                    pism_version, 'no', False),
                   options={'ftol': 10**-6})


    else:
        print("I AM CONFUSED, I DON'T KNOW THIS param_option") 

    print('FINAL RESULT = ',res_tuning.x)
    time_end = datetime.datetime.now()
    print(time_end)
    
    return
    