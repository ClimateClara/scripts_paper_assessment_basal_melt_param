
Scripts used for the publication "An assessment of basal melt parameterisations for Antarctic ice shelves"
========================================================================================================

These are the scripts that were developed and used for the publication: Burgard, C., Jourdain, N. C., Reese, R., Jenkins, A., and Mathiot, P.: An assessment of basal melt parameterisations for Antarctic ice shelves, The Cryosphere, https://doi.org/10.5194/tc-2022-32, in press, 2022.

*If you want to play around with the parameterisations and your own data, have a look at the package multimelt: https://github.com/ClimateClara/multimelt*


Useful functions are grouped in the package ``assess_param_funcs``. To install them and use them in further scripts, don't forget to run 

.. code-block:: bash

  pip install .
  
The scripts to format the data and produce the figures can be found in the folder ``scripts_and_notebooks``.

*Note - In the scripts, the NEMO runs are called 'OPM+number'. Here are the corresponding names given in the manuscript: OPM006=HIGHGETZ, OPM016=WARMROSS, OPM018=COLDAMU and OPM021=REALISTIC.*


Initial data formatting (from raw NEMO output to interesting variables gridded on stereographic grid)
-----------------------------------------------------------------------------------------------------

The scripts for the initial formatting of the data can be found in ``scripts_and_notebooks/data_formatting``. Start with ``prepare_data_NEMO.sh``, then move to ``custom_lsmask.ipynb`` and finally to ``regridding_vars_cdo.ipynb``. At this point you have the relevant NEMO fields on a stereographic grid.


Preprocess the data to be used for the parameterisations and further analysis
-----------------------------------------------------------------------------
The scripts to prepare the ice-shelf masks, the box and plume characteristics, and the temperature and salinity profiles can be found in ``scripts_and_notebooks/pre_processing``. 

``isf_mask_NEMO.ipynb`` and ``isf_mask_BedMachine.ipynb`` prepare masks of ice shelves, and plume and box characteristics, on the NEMO and Bedmachine grid (the latter is needed for Fig. 8) respectively. 

``prepare_reference_melt_file.ipynb`` prepares 2D and 1D metrics of the melt in NEMO for future comparison to the results of the parameterisations.

``T_S_profile_formatting_with_conversion.ipynb`` converts the 3D fields from conservative temperature to potential temperature and from absolute salinity to practical salinity.

``T_S_profiles_front.ipynb`` prepares the average temperature and salinity profiles in front of the ice shelf.

``T_S_profiles_Dutrieux14.ipynb`` converts the profiles given in Dutrieux et al. 2014 to the format needed for my formulation of the parameterisations (for Figure 8).


Conduct the tuning (cross validations, best estimates, bootstrap)
-----------------------------------------------------------------
The scripts to conduct the cross-validation, the best-estimate tuning and the tuning on different bootstrap samples can be found in ``scripts_and_notebooks/tuning``. 

For the simple parameterisations, run ``prepare_2D_thermal_forcing_simple.ipynb``, ``prepare_1D_thermal_forcing_term_simple_for_linreg.ipynb``, and ``tuning_cluster_ALL_CV_BT.ipynb``.

For the more complex ones, usee the bash script ``run_generalized_tuning_script.sh`` to call the python script ``run_generalized_tuning_from_bash_crossval.py`` and run the tuning on the different samples (either leave-one-ice-shelf-out or leave-one-time-block-out or the whole sample or a random bootstrap sample). Then group the tuneed parameters with ``group_CV_parameters.ipynb`` (cross-validation) and/or ``group_BT_parameters.ipynb`` (bootstrap).

The names of the parameterisations in the files and scripts are: 

    - 'linear_local' for the linear, local parameterisation; 
    - 'quadratic_local' for the quadratic, local parameterisation using a constant slope for all Antarctica; 'quadratic_local_cavslope' for the quadratic, local parameterisation using one slope on the cavity level of each ice shelf; 'quadratic_local_locslope' for the quadratic, local parameterisation using a slope on the grid-cell level; 
    - 'quadratic_mixed_mean' for the quadratic, semilocal parameterisation using a constant slope for all Antarctica; 'quadratic_mixed_cavslope' for the quadratic, semilocal parameterisation using one slope on the cavity level of each ice shelf; 'quadratic_mixed_locslope' for the quadratic, semilocal parameterisation using a slope on the grid-cell level; 
    - 'lazero19_2' for the plume parameterisation as suggested by Lazeroms et al. (2019);  'lazero19_modif2' for the modified plume parameterisation as suggested in this paper; 
    - 'boxes_$n_pism$i_picop$j' are the box and PICOP parameterisations. $n = number of the configuration, where '1' = 2 boxes, '2' = 5 boxes, '3' = 10 boxes, '4' = PICO boxes; $i is yes or no, where yes is heterogeneous boxes and no is homogeneous boxes; $j is yes or no, where yes is PICOP (using the plume parameterisation to infer the melt) and no is "normal" box parameterisation.



Run the parameterisations with different parameters
---------------------------------------------------
The scripts to run the parameterisations can be found in ``scripts_and_notebooks/apply_params``. 

``evalmetrics_results_CV.ipynb`` computes the integrated melt and the melt near the grounding line, applying the parameters of the cross-validation on the corresponding left out time block or ice shelf and applyong the original parameters.

``script_to_apply_all_param_basic_application.ipynb`` computes several 2D and 1D metrics resulting from the parameterisations for a given set of parameters for one NEMO run (useful for spatial patterns for example).

``apply_param_PIGL_dutrieux_BedMachine.ipynb`` computes the parameterisations using best-estimate parameters applied to BedMachine output and the Dutrieux profiles. Only for Pine Island. For Figure 8.

``apply_pointbypointRMSE_box1_forFigF1.ipynb`` computes the difference between parameterised and reference melt in box1 point by point (for the comparison in Fig. F1).


Final analysis and figures
--------------------------
The scripts to finalise the figures can be found in ``scripts_and_notebooks/figures``. 

Figures 2 and 3 are done with ``Figures_2_and_3.ipynb``.

Figures 4, 7, E1, E2, E3 and values for Tables 3, 5, 7, 9 are done with ``Figures_4_7_E1_E2_E3.ipynb`` and ``check_RMSE_orig_parameters.ipynb``.

Figure 5 is done with ``prepare_data_Figures_5_6.ipynb`` and ``Figure_5.ipynb``.

Figure 6 is done with ``prepare_data_Figures_5_6.ipynb`` and ``Figure_6.ipynb``.

Figure 8 is done with ``Figure_8a.ipynb`` and ``Figure_8b.ipynb``.

Figure 9 is done with ``Figure_9.ipynb``.

Figure F1 is composed of the left panel of the figure created with ``Figure_E1_leftpanel.ipynb`` and of the right panel of Fig. 7.

Figure B1 is done with ``Figure_B1.bash`` and scripts found in ``tools_fig_B1B2B3/VALSO/`` (this is the version downloaded from https://github.com/pmathiot/VALSO on October 11th 2022).

Figure B2 is done with ``Figure_B2.bash`` and scripts found in ``tools_fig_B1B2B3/PyChart/`` (this is the version downloaded from https://github.com/pmathiot/PyChart on October 11th 2022).

Figure B3 is done with ``Figure_B3.bash`` and scripts found in ``tools_fig_B1B2B3/PyChart/`` (this is the version downloaded from https://github.com/pmathiot/PyChart on October 11th 2022).

Quick figures (not looking as good as in the paper) B1, B2 and B3 can be made with ``reproduce_plots_appendix.ipynb``

