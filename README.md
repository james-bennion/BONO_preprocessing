This repository contains the functions I used for preprocessing the BONO EEG data and some other useful scripts.

The main dependencies you'll need are the MADE pipeline (https://github.com/ChildDevLab), EEGLAB, and FieldTrip.
You might need some custom functions to run these scripts that aren't included here. If you don't already have access to them, feel free to email me (ucbtj23@ucl.ac.uk).
Also if anything doesn't work or you have any questions, feel free to get in touch at the same email. Happy to help!

Quick guide to each script (in approximate order of preprocessing steps):
- JB_summarise_data_inc_events: using the folders of raw and rescued marker files, summarises the overall dataset into a .csv. Used in later scripts for converting files.
- fJB_correct_markers_from_tsv: the function that corrects the missing markers, used in the other scripts.
- fJB_convert_correct_easy_set: converts .easy to .set files and corrects missing markers, in one go.
- JB_central_easy_set_converter: just loops through your directory and converts and corrects missing markers for the raw data. Easier to run once here centrally if you have multiple preprocessing forks to come, rather than at the start of each.
- JB_full_BONO_preproc_PLI_Coh/complexity/power: just a record of the exact pipeline and parameters I used.
- JB_parallel_comp_preproc: adapts the miniMADE pipeline to use the MATLAB parallel computing toolbox to speed up the preprocessing when doing many participants.
- JB_extract_power_PLI_Coh: this is for using after calculating power, PLI, or coherence using Rianne's scripts. Those scripts store the values in a .mat but you might want them in a .csv format to analyse elsewhere, which is what this script provides.
