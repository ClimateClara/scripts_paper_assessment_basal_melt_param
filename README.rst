
Scripts used for the publication "An assessment of basal melt parameterisations for Antarctic ice shelves"
========================================================================================================

These are the scripts that were developed and used for the publication: Burgard, C., Jourdain, N. C., Reese, R., Jenkins, A., and Mathiot, P.: An assessment of basal melt parameterisations for Antarctic ice shelves, The Cryosphere Discuss. [preprint], https://doi.org/10.5194/tc-2022-32, in review, 2022.

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


Run the parameterisations with different parameters
---------------------------------------------------
The scripts to run the parameterisations can be found in ``scripts_and_notebooks/apply_params``. 

``evalmetrics_results_CV.ipynb`` computes the integrated melt and the melt near the grounding line, applying the parameters of the cross-validation on the corresponding left out time block or ice shelf. 

``script_to_apply_all_param_basic_application.ipynb`` computes several 2D and 1D metrics resulting from the parameterisations for a given set of parameters for one NEMO run (useful for spatial patterns for example).

``apply_param_PIGL_dutrieux_BedMachine.ipynb`` computes the parameterisations using best-estimate parameters applied to BedMachine output and the Dutrieux profiles. Only for Pine Island. For Figure 8.


Final analysis and figures
--------------------------
The scripts to finalise the figures can be found in ``scripts_and_notebooks/figures``. 

Figures 1 and 2 are done with ``Figures_1_and_2.ipynb``.
Figures 4, 7, D1, D2, D3 and values for Tables 3, 5, 7, 9 are done with ``Figures_4_7_D1_D2_D3.ipynb``.
Figure 5 is done with ``prepare_data_Figures_5_6.ipynb`` and ``Figure_5.ipynb``.
Figure 6 is done with ``prepare_data_Figures_5_6.ipynb`` and ``Figure_6.ipynb``.
Figure 8 is done with ``Figure_8a.ipynb`` and ``Figure_8b.ipynb``.
Figure 9 is done with ``Figure_9.ipynb``.
Figure E1 is composed of the left panel of the figure created with ``Figure_E1_leftpanel.ipynb`` and of the right panel of Fig. 7.

Scripts for Figure B1/B2/B3 .

