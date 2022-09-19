import matplotlib.pyplot as plt
import numpy as np
import cartopy
import cartopy.crs as ccrs
import xarray as xr
from scipy.stats import zscore

def plot_compare_melt_abs(ds, ds_summary, kisf, isf_name):
    
    """
    Figure comparing spatial melt under different parametrizations and profile domains for one ice shelf.
    
    This function produces a figure showing the melt pattern (in m ice per year) for one ice shelf under different parameterizations and the total melt in Gt per year.
    
    Parameters
    ----------
    ds : xarray.Dataset
        dataset containing the spatial pattern of the melt rate in the variable ``melt_m_ice_per_y``, with coordinates ``[x,y,param,profile_domain]``
    ds_summary : xarray.Dataset
        dataset containing the integrated variable of the melt rate in the variable ``melt_Gt_per_y_tot'``, with coordinates ``[Nisf,param,profile_domain]``
    kisf : int
        ID of the ice shelf of interest
    isf_name : str
        name of the ice shelf of interest
        
    Returns
    -------
   f : figure
       figure comparing spatial melt under different parametrizations and profile domains for the ice shelf of interest
    """
    
    param_nb = len(ds.param)
    domain_nb = len(ds.profile_domain)

    f = plt.figure()
    f.set_size_inches(4*param_nb, 4*domain_nb)

    ax={}

    i = 0
    for dom in ds.profile_domain:
        for mparam in ds.param:
            print(i)

            if i == 0:
                ax[i] = f.add_subplot(domain_nb,param_nb,i+1)
            else:
                ax[i] = f.add_subplot(domain_nb,param_nb,i+1,sharex=ax[0], sharey=ax[0])

            plotted_var = ds['melt_m_ice_per_y'].sel(param=mparam, profile_domain=dom)
            abs0 = ax[i].pcolormesh(ds.x/10**6, ds.y/10**6, plotted_var,rasterized=True)#,alpha=alph,s=siz,edgecolors='None')
            f.colorbar(abs0, ax=ax[i], shrink=1.0,orientation='vertical', label='Melt rate [m of ice per year]')
            ax[i].set_title(str(dom.values)+' '+str(mparam.values)+'\n'+'Total melt in Gt/yr = '+str(np.round(ds_summary['melt_Gt_per_y_tot'].sel(param=mparam,Nisf=kisf,profile_domain=dom).values,2)))
            f.suptitle(isf_name+' ice shelf - ID: '+str(kisf))

            if i not in param_nb*np.arange(domain_nb):
                plt.setp(ax[i].get_yticklabels(), visible=False)
            if i not in np.arange(param_nb*domain_nb-param_nb,param_nb*domain_nb):
                plt.setp(ax[i].get_xticklabels(), visible=False)

            i = i+1
        
    f.tight_layout()
    return f

def plot_compare_melt_obs_diff(obs_2D, obs_Gt_per_y, computed_2D, computed_Gt_per_y, kisf, isf_name):
    
    param_nb = len(ds.param)
    domain_nb = len(ds.profile_domain)

    f = plt.figure()
    f.set_size_inches(4*param_nb, 4*domain_nb)

    ax={}

    i = 0
    for dom in ds.profile_domain:
        for mparam in ds.param:
            print(i)

            if i == 0:
                ax[i] = f.add_subplot(domain_nb,param_nb,i+1)
            else:
                ax[i] = f.add_subplot(domain_nb,param_nb,i+1,sharex=ax[0], sharey=ax[0])

            plotted_var = ds['melt_m_ice_per_y'].sel(param=mparam, profile_domain=dom)
            abs0 = ax[i].pcolormesh(ds.x/10**6, ds.y/10**6, plotted_var,rasterized=True)#,alpha=alph,s=siz,edgecolors='None')
            f.colorbar(abs0, ax=ax[i], shrink=1.0,orientation='vertical', label='Melt rate [m of ice per year]')
            ax[i].set_title(str(dom.values)+' '+str(mparam.values)+'\n'+'Total melt in Gt/yr = '+str(np.round(ds_summary['melt_Gt_per_y_tot'].sel(param=mparam,Nisf=kisf,profile_domain=dom).values,2)))
            f.suptitle(isf_name+' ice shelf - ID: '+str(kisf))

            if i not in param_nb*np.arange(domain_nb):
                plt.setp(ax[i].get_yticklabels(), visible=False)
            if i not in np.arange(param_nb*domain_nb-param_nb,param_nb*domain_nb):
                plt.setp(ax[i].get_xticklabels(), visible=False)

            i = i+1
        
    f.tight_layout()
    return f

def plot_compare_melt_obs_diff(obs_2D, obs_Gt_per_y, ds, ds_summary, kisf, isf_name):
    
    param_nb = len(ds.param)
    domain_nb = len(ds.profile_domain)

    f = plt.figure()
    f.set_size_inches(5*param_nb, 4*domain_nb)

    ax={}
            
    i = 0        
    for dom in ds.profile_domain:
        if i == 0:
            ax[i] = f.add_subplot(domain_nb,param_nb+1,i+1)
        else: 
            ax[i] = f.add_subplot(domain_nb,param_nb+1,i+1,sharex=ax[0], sharey=ax[0]) 
            
        plotted_var = obs_2D
        abs0 = ax[i].pcolormesh(ds.x/10**6, ds.y/10**6, plotted_var,rasterized=True)#,alpha=alph,s=siz,edgecolors='None')
        f.colorbar(abs0, ax=ax[i], shrink=1.0,orientation='vertical', label='Melt rate [m of ice per year]')
        ax[i].set_title('NEMO reference \n'+'Total melt in Gt/yr = '+str(np.round(obs_Gt_per_y.values,2)))
        f.suptitle(isf_name+' ice shelf - ID: '+str(kisf))
        
        i = i+1    
            
        for mparam in ds.param:
            print(i)

            ax[i] = f.add_subplot(domain_nb,param_nb+1,i+1,sharex=ax[0], sharey=ax[0])

            plotted_var = ds['melt_m_ice_per_y'].sel(param=mparam, profile_domain=dom) - obs_2D
            abs0 = ax[i].pcolormesh(ds.x/10**6, ds.y/10**6, plotted_var,rasterized=True)#,alpha=alph,s=siz,edgecolors='None')
            f.colorbar(abs0, ax=ax[i], shrink=1.0,orientation='vertical', label='Melt rate [m of ice per year]')
            ax[i].set_title(str(dom.values)+' '+str(mparam.values)+'\n'+'Total melt in Gt/yr = '+str(np.round(ds_summary['melt_Gt_per_y_tot'].sel(param=mparam,Nisf=kisf,profile_domain=dom).values,2)))
            f.suptitle(isf_name+' ice shelf - ID: '+str(kisf))

            if i not in param_nb*np.arange(domain_nb):
                plt.setp(ax[i].get_yticklabels(), visible=False)
            if i not in np.arange(param_nb*domain_nb-param_nb,param_nb*domain_nb):
                plt.setp(ax[i].get_xticklabels(), visible=False)

            i = i+1
        
    f.tight_layout()
    return f

def plot_melt_map(lon, lat, melt_2D):
    f = plt.figure()
    ax = plt.axes(projection=ccrs.SouthPolarStereo(central_longitude=0,true_scale_latitude=-71))
    ax.coastlines(resolution='50m', linewidth=0.5)
    map0 = ax.pcolormesh(lon,lat,melt_2D,transform=ccrs.PlateCarree(), rasterized=True)
    ax.set_extent([-180, 180, -90, -60], crs=ccrs.PlateCarree())
    plt.colorbar(map0)
    return f

def corrcoeff_nan(img1,img2):
    c_11 = xr.cov(img1, img1)
    c_22 = xr.cov(img2, img2)
    c_12 = xr.cov(img1, img2)
    ccoeff = c_12 / np.sqrt(c_11 * c_22)
    return ccoeff

def variation_xr(img):
    var = img.std(['x','y'])/img.mean(['x','y'])
    return var

def SPAEF(sim, obs):
    """
    Spatial efficiency metric
    1 - sqrt((correlation-1)**2 + (ratio_cov-1)**2 + (histogram_intersec-1)**2)
    """

    bins=np.around(np.sqrt(len(obs)),0).astype(int)
    #compute corr coeff
    alpha = corrcoeff_nan(sim,obs)
    #compute ratio of CV
    beta = variation_xr(sim)/variation_xr(obs)
    ##compute zscore mean=0, std=1
    obs=xr.apply_ufunc(zscore,obs,kwargs={'nan_policy':'omit'})
    sim=xr.apply_ufunc(zscore,sim,kwargs={'nan_policy':'omit'})
    #compute histograms
    obs_np = obs.values
    hobs, binobs = np.histogram(obs_np[np.isfinite(obs_np)], bins=bins)
    sim_np = sim.values
    hsim, binsim = np.histogram(sim_np[np.isfinite(sim_np)], bins=bins)
    #hobs_xr = xr.plot.hist(obs, bins=bins)[0]
    #hsim_xr = xr.plot.hist(sim, bins=bins)[0]
    #convert int to float, critical conversion for the result
    hobs=np.float64(hobs)
    hsim=np.float64(hsim)
    #find the overlapping of two histogram      
    minima = np.minimum(hsim, hobs)
    #compute the fraction of intersection area to the observed histogram area, hist intersection/overlap index   
    gamma = np.sum(minima)/np.sum(hobs)
    #compute SPAEF finally with three vital components
    spaef = 1 - np.sqrt( (alpha.values-1)**2 + (beta-1)**2 + (gamma-1)**2 )  
    
    return spaef.values, alpha.values, beta.values, gamma