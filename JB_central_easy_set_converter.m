%% **** Central Correction & Conversion Script ***************************

% This script serves to centrally convert (.easy to .set) and correct
% missing markers to the raw BONO data before being put directly into the
% different miniMADE preprocessing forks.

% More efficient to do it once centrally here than multiple times at the
% start of each miniMADE run.

% Uses the summary table from 'JB_summarise_data_incevents'
% Requires function 'fJB_convert_correct_easy_set'

% Created by James Bennion, Birkbeck, Jul 2026
% ************************************************************************
%% Setup & Paths
clear
clc

addpath(genpath('YOUR EEGLAB PATH')); 
eeglab nogui;

addpath('YOUR FIELDTRIP PATH');
ft_defaults
addpath('YOUR PATH FOR OTHER SCRIPTS DEPENDED UPON HERE');

addpath(genpath('YOUR LMTOOLS PATH'));

rawdata_location = 'YOUR RAW DATA PATH';
marker_location = 'YOUR PATH CONTAINING RESCUED MARKER FILES';
summary_location = 'YOUR SUMMARY TABLE';
output_location = 'YOUR DESIRED OUTPUT PATH';


fJB_convert_correct_easy_set(rawdata_location, marker_location, summary_location, output_location)

