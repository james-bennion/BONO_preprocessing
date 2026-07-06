%% JB Full Preproc Script for Spectral Power

% Just a record of the exact preproc I did for power

% You might need some custom functions from Luke Mason/Rianne Haartsen to run this. 
% If you don't have access to these, feel free to email me: ucbtj23@ucl.ac.uk

% Created by James Bennion, Birkbeck, Jul 2026

% ************************************************************************
%% User input: user provide relevant information to be used for data processing
% Preprocessing of EEG data involves using some common parameters for
% every subject. This part of the script initializes the common parameters.

clear % clear matlab workspace
clc % clear matlab command window

% add path to MADE pipeline
addpath(genpath('C:\Users\benni\Documents\MATLAB\MADE-EEG-preprocessing-pipeline-master'))

addpath(genpath('C:\Users\benni\Documents\MATLAB\toolboxes\eeglab2026.0.0')); 
eeglab nogui;

addpath('C:\Users\benni\Documents\MATLAB\toolboxes\fieldtrip-20250106');
ft_defaults
addpath('C:\Users\benni\Documents\MATLAB\projects\BONO\scripts');

addpath(genpath('C:\Users\benni\Documents\MATLAB\projects\BONO\scripts\lm_tools'));

% Do you want to use miniMADE (recommended for low density (<32 channels) systems)
run_miniMADE = 1; % 0 = NO (run full MADE pipeline),  = YES (run MADE pipeline with minimal preprocessing steps)
% Note: Running miniMADE will skip the FASTER and ICA steps. Epoch level interpolation can still be performed, but is not recommended
% miniMADE also skips interim saving regardless of user selection

% 1. Enter the path where you would like the intermediate converted .set files to be saved
set_location = 'C:\Users\benni\Documents\MATLAB\projects\BONO\data\full_sets';

% 2. Enter the path of the folder where you want to save the processed data
output_location = 'C:\Users\benni\Documents\MATLAB\projects\BONO\data\full_preproc_power';


% 3. Enter the path of the channel location file
%channel_locations = 'C:\Users\benni\Documents\MATLAB\projects\BONO\scripts\eegtools\fieldtrip-20180925\template\layout\EEG1010.lay';

% 4. Do your data need correction for anti-aliasing filter and/or task related time offset?
adjust_time_offset = 0; % 0 = NO (no correction), 1 = YES (correct time offset)
% If your data need correction for time offset, initialize the offset time (in milliseconds)
filter_timeoffset   = 0; % anti-aliasing time offset (in milliseconds). 0 = No time offset
stimulus_timeoffset = 0; % stimulus related time offset (in milliseconds). 0 = No time offset
response_timeoffset = 0; % response related time offset (in milliseconds). 0 = No time offset
stimulus_markers = {'xxx', 'xxx'}; % enter the stimulus makers that need to be adjusted for time offset
respose_markers  = {'xxx', 'xxx'}; % enter the response makers that need to be adjusted for time offset

% 5. Do you want to down sample the data?
down_sample = 0; % 0 = NO (no down sampling), 1 = YES (down sampling)
sampling_rate = 500; % set sampling rate (in Hz), if you want to down sample

% 6. Do you want to delete the outer layer of the channels? (Rationale has been described in MADE manuscript)
%    This function can also be used to down sample electrodes. For example, if EEG was recorded with 128 channels but you would
%    like to analyse only 64 channels, you can assign the list of channnels to be excluded in the 'outerlayer_channel' variable.    
delete_outerlayer = 1; % 0 = NO (do not delete outer layer), 1 = YES (delete outerlayer);
% If you want to delete outer layer, make a list of channels to be deleted
outerlayer_channel = {'O2'}; % list of channels
% recommended list for EGI 128 channel net: {'E17' 'E38' 'E43' 'E44' 'E48' 'E49' 'E113' 'E114' 'E119' 'E120' 'E121' 'E125' 'E126' 'E127' 'E128' 'E56' 'E63' 'E68' 'E73' 'E81' 'E88' 'E94' 'E99' 'E107'}

% 7. Initialize the filters
highpass = 0.1; % High-pass frequency
lowpass  = 48; % Low-pass frequency. We recommend low-pass filter at/below line noise frequency (see manuscript for detail)

% 8. Are you processing task-related or resting-state EEG data?
task_eeg = 4; % 0 = resting, 1 = task, 4 = resting & dynamic videos with onset/offset markers
taskonset_event_markers = {'10', '11'}; % enter all the event/condition markers; reflecting the onset of the condition - study specific

% 9. Do you want to epoch/segment your data?
epoch_data = 1; % 0 = NO (do not epoch), 1= YES (epoch data)
rest_epoch_length = 2; % epoch length in seconds
taskoffset_event_markers = {'19', '19'}; % enter all the event/condition markers; reflecting the offset of the condition - study specific
overlap_epoch = 1;     % 0 = NO (do not create overlapping epoch), 1 = YES (50% overlapping epoch)
dummy_events ={'910','911'}; % enter dummy events name

% 10. Do you want to remove/correct baseline?
remove_baseline = 1; % 0 = NO (no baseline correction), 1 = YES (baseline correction)
baseline_window = []; % baseline period in milliseconds (MS), [] = entire epoch

% 11. Do you want to remove artifact laden epoch based on voltage threshold?
voltthres_rejection = 1; % 0 = NO, 1 = YES
volt_threshold = [-120 120]; % lower and upper threshold (in uV)

% 12. Do you want to perform epoch level channel interpolation for artifact laden epoch? (see manuscript for detail)
% Note: interpolation is not recommended for systems with less than 20 channels
interp_epoch = 1; % 0 = NO, 1 = YES.
frontal_channels = {'AF8', 'AF7', 'Fpz'}; % If you set interp_epoch = 1, enter the list of frontal channels to check (see manuscript for detail)
% recommended list for EGI 128 channel net: {'E1', 'E8', 'E14', 'E21', 'E25', 'E32', 'E17'}
% recommended list for EGI 64 channel net: {'E1', 'E5', 'E10', 'E17'}

%13. Do you want to interpolate the bad channels that were removed from data?
% Note: because miniMADE automatically skips FASTER and ICA, this field will not affect miniMADE preprocessing
interp_channels = 1; % 0 = NO (Do not interpolate), 1 = YES (interpolate missing channels)

% 14. Do you want to rereference your data?
rerefer_data = 1; % 0 = NO, 1 = YES
reref=[]; % Enter electrode name/s or number/s to be used for rereferencing
% For channel name/s enter, reref = {'channel_name', 'channel_name'};
% For channel number/s enter, reref = [channel_number, channel_number];
% For average rereference enter, reref = []; default is average rereference

% 15. Do you want to save interim results?
save_interim_result = 0; % 0 = NO (Do not save) 1 = YES (save interim results)

% 16. How do you want to save your data? .set or .mat
output_format = 1; % 1 = .set (EEGLAB data structure), 2 = .mat (Matlab data structure), 3 = BIDS format
% If you chose BIDS format, specify subject number location in the file name and the task name
subject_number_loc = [1 2]; % should enter as [start stop] locations (e.g., par001_eeg.mff would be entered as [4 6])
task_name = 'task_name'; % should enter the eeg task name you want included in the file name

% ---------------- ADVANCED OPTIONS ---------------- %
% 17. Do you want to allow missing channels in epochs?
% Note: matlab matrices do not allow for missing rows (channels for data matrix). As such, channels removed from epochs will be replaced with
%       NaNs, which will need to be removed when averaging epochs (in the case of ERPs) or calculating other metrics (e.g., spectral power)
allow_missing_chans = 0; % this will replace bad channels with NaNs, 0 = NO and 1 = YES
% If allow_missing_chans = 1 (YES), volt_threshold values will be used to determine which channels are bad and will be replaced with NaN
% If allow_missing_chans = 1 (YES), interp_epoch & interp_channels CANNOT also = 1 (YES)
% If allow_missing_chans = 1 (YES), an average rereference cannot be used (reref cannot = [])
blink_check = 0; % this will check for blinks using the frontal_channels (defined in #12) and remove epochs containing them before replacing bad channels with NaNs
% This field will only be considered if allow_missing_chans = 1 (YES)
% WARNING: Make sure frontal_channels contains a list of frontal channels to check... If this variable is not properly defined the code will crash
chan_thresh = 0.8; % acceptable values are 0-1 and represent the percent of channels that must be good to keep an epoch
% for example: chan_thresh = 0.8 would remove epochs where greater than 80% of channels were replaced by NaNs

% ********* no need to edit beyond this point for EGI .mff data **********
% ********* for non-.mff data format edit data import function ***********
% ********* below using relevant data import plugin from EEGLAB **********

%% Read files to analyse
ppt_dirs = dir(set_location);
ppt_dirs = ppt_dirs([ppt_dirs.isdir] & ~startsWith({ppt_dirs.name}, '.'));
fprintf('Found %i participant folders\n', numel(ppt_dirs));

%% Check whether EEGLAB and all necessary plugins are in Matlab path.
if exist('eeglab','file')==0
    error(['Please make sure EEGLAB is on your Matlab path. Please see EEGLAB' ...
        'wiki page for download and instalation instructions']);
end

if exist('pop_firws', 'file')==0
    error(['Please make sure  "firfilt" plugin is in EEGLAB plugin folder and on Matlab path.' ...
        ' Please see EEGLAB wiki page for download and instalation instructions of plugins.']);
end

if exist('channel_properties', 'file')==0
    error(['Please make sure "FASTER" plugin is in EEGLAB plugin folder and on Matlab path.' ...
        ' Please see EEGLAB wiki page for download and instalation instructions of plugins.']);
end

if exist('ADJUST', 'file')==0
    error(['Please make sure you download modified "ADJUST" plugin from GitHub (link is in MADE manuscript)' ...
        ' and ADJUST is in EEGLAB plugin folder and on Matlab path.']);
end

%% Check that ADVANCED pipeline selections are compatible with other preprocessing selections
if allow_missing_chans == 1 && (interp_epoch == 1 || interp_channels == 1)
    error(['The allow_missing_chans option (ADVANCED) cannot be turned on if channel interpolation is on...' ...
        ' allow_missing_chans does not allow for channel interpolation. Please make sure interp_epoch and interp_channels are off']);
end

if allow_missing_chans == 1 && rerefer_data == 1 && isempty(reref)
    error(['An average rereference cannot be used if the allow_missing_chans option (ADVANCED) is on...' ...
        ' allow_missing_chans does not allow for average reference. Please ensure only a subset of channels are used for rereferencing']);
end

if allow_missing_chans == 1 && voltthres_rejection == 0
    warning('voltage threshold rejection thresholds will still be used to select bad channels and replace them with NaNs');
end

%% Create output folders to save data
if output_format < 3 % if not BIDS format
    if save_interim_result ==1
        if exist([output_location filesep 'filtered_data'], 'dir') == 0
            mkdir([output_location filesep 'filtered_data'])
        end
        if exist([output_location filesep 'ica_data'], 'dir') == 0
            mkdir([output_location filesep 'ica_data'])
        end
    end
    if exist([output_location filesep 'processed_data'], 'dir') == 0
        mkdir([output_location filesep 'processed_data'])
    end
elseif output_format == 3 % if BIDS format
    if exist([ output_location filesep 'derivatives']) == 0
        mkdir([ output_location filesep 'derivatives'])
    end
    if exist([ output_location filesep 'derivatives' filesep 'eegpreprocess']) == 0
        mkdir([ output_location filesep 'derivatives' filesep 'eegpreprocess'])
    end
    output_location_derivatives = [output_location filesep 'derivatives'];
end

%% Initialize output variables

% epoch rejection
total_epochs_before_artifact_rejection=[];
total_epochs_after_artifact_rejection=[];
total_channels_interpolated=[];
% marker presence
N_TaskOnsetMarkers = [];
% AR info
AR1_blinks = [];
Neps_postAR1 = [];
AR2a_thresholds = [];
AR2b_flat = [];
AR2c_jumps = [];
AR2_thr_flat_jump = []; % contains the channels interpolated per trial
Eps_BAD_InvalidInterp = []; % trials with more than 20% channels interpolated
Neps_postAR2 = [];
Chan_labels_curr = [];

curdate=datestr(now,'dd-mm-yyyy'); % set current date here so that table won't crash if date changes

%% Load or initialise tracker
tracker_file = fullfile(output_location, 'SP_miniMADE_preproc_record.mat');
SP_preproc_record = table();
fprintf('Starting fresh tracker\n');

%% Loop over all participant folders
for subject = 1:numel(ppt_dirs)

    subject_folder = ppt_dirs(subject).name;
    subject_path   = fullfile(set_location, subject_folder);
    ppt_out_folder = fullfile(output_location, 'processed_data', subject_folder);
    if ~exist(ppt_out_folder, 'dir')
        mkdir(ppt_out_folder);
    end

    % find .set files in participant folder
    set_files = dir(fullfile(subject_path, '**', '*.set'));
    if isempty(set_files)
        warning('No .set file found for %s, skipping', subject_folder);
        continue
    end

    EEG=[];
    savedDataPath = NaN;
    
    fprintf('\n\n\n*** Processing subject %d (%s) ***\n\n\n', subject, subject_folder);

        %% Initialize output variables
    
        % epoch rejection
        total_epochs_before_artifact_rejection(subject)=0;
        total_epochs_after_artifact_rejection(subject)=0;
        total_channels_interpolated(subject)=0;
        % marker presence
        N_TaskOnsetMarkers = [];
        % AR info
        AR1_badFrontCh = [];
        AR1_blinks = [];
        Neps_postAR1 = 0;
        AR2a_thresholds = [];
        AR2b_flat = [];
        AR2c_jumps = [];
        AR2_thr_flat_jump = []; % contains the channels interpolated per trial
        Eps_BAD_InvalidInterp = []; % trials with more than 20% channels interpolated
        Neps_postAR2 = 0;
        Chan_labels_curr = [];
        
        curdate=datestr(now,'dd-mm-yyyy');

    try
        %% STEP 1: Import .set file
        set_file = fullfile(set_files(1).folder, set_files(1).name);
        EEG = pop_loadset(set_file);
        EEG = eeg_checkset(EEG);

        %% STEP 2: Fix channel labels and load coordinates
        Chan_names = {'P7','P4','Cz','Pz','P3','P8','Oz','O2','T8','PO8',...
                      'C4','F4','AF8','Fz','C3','F3','AF7','T7','PO7','Fpz'};
        if strcmp(EEG.chanlocs(1).labels,'Ch1') && EEG.nbchan == 20
            for cc = 1:EEG.nbchan
                EEG.chanlocs(cc).labels = Chan_names{cc};
            end
        end

        % store current labels then load coordinates
        EEG_x.chanlocs = EEG.chanlocs;
        EEG = pop_chanedit(EEG, 'lookup', 'standard-10-5-cap385.elp');
        EEG = eeg_checkset(EEG);
        % restore correct labels
        for cc = 1:size(EEG.chanlocs,2)
            EEG.chanlocs(cc).labels = EEG_x.chanlocs(cc).labels;
        end
        clear cc EEG_x

        % Check whether the channel locations were properly imported
        if size(EEG.data, 1) ~= length(EEG.chanlocs)
            error('The size of the data does not match with channel numbers.');
        end

        % Double check matches SP layout order and reorder if not
        load('C:\Users\benni\Documents\MATLAB\projects\BONO\scripts\SP_20ch_layout_labels.mat');
        Ch_ord_new = zeros(length(SP_20ch_layout_labels), 1);
        for ch_lo = 1:length(SP_20ch_layout_labels)
            match = find(strcmp(SP_20ch_layout_labels{ch_lo}, {EEG.chanlocs.labels}));
            if isempty(match)
                fprintf(' Warning: layout channel %s not found in data\n',  SP_20ch_layout_labels{ch_lo});
            else
                Ch_ord_new(ch_lo) = match;
            end
        end

        if ~isequal(Ch_ord_new, (1:EEG.nbchan)')
            fprintf(' Reordering channels to match SP layout\n');
            EEG.data = EEG.data(Ch_ord_new, :);
            EEG.chanlocs = EEG.chanlocs(Ch_ord_new);
            EEG = eeg_checkset(EEG);
        else
            fprintf(' Channels already in correct SP layout order\n');
        end

        clear ch_lo match Ch_ord_new SP_20ch_layout_labels

        % if reref is a vector (type double) instead of a cell array, grab the electrode name(s)
        if ~iscell(reref); reref = {EEG.chanlocs(reref).labels}; end

        %% STEP 3: Adjust anti-aliasing and task related time offset
        if adjust_time_offset==1
            if filter_timeoffset~=0
                for aafto=1:length(EEG.event)
                    EEG.event(aafto).latency=EEG.event(aafto).latency+(filter_timeoffset/1000)*EEG.srate;
                end
            end
            if stimulus_timeoffset~=0
                for sto=1:length(EEG.event)
                    for sm=1:length(stimulus_markers)
                        if strcmp(EEG.event(sto).type, stimulus_markers{sm})
                            EEG.event(sto).latency=EEG.event(sto).latency+(stimulus_timeoffset/1000)*EEG.srate;
                        end
                    end
                end
            end
            if response_timeoffset~=0
                for rto=1:length(EEG.event)
                    for rm=1:length(respose_markers)
                        if strcmp(EEG.event(rto).type, respose_markers{rm})
                            EEG.event(rto).latency=EEG.event(rto).latency-(response_timeoffset/1000)*EEG.srate;
                        end
                    end
                end
            end
        end

        %% STEP 4: Change sampling rate
        if down_sample==1
            if floor(sampling_rate) > EEG.srate
                error ('Sampling rate cannot be higher than recorded sampling rate');
            elseif floor(sampling_rate) ~= EEG.srate
                EEG = pop_resample( EEG, sampling_rate);
                EEG = eeg_checkset( EEG );
            end
        end

        %% STEP 5: Delete outer layer of channels
        chans_labels=cell(1,EEG.nbchan);
        for i=1:EEG.nbchan
            chans_labels{i}= EEG.chanlocs(i).labels;
        end
        [chans,chansidx] = ismember(outerlayer_channel, chans_labels);
        outerlayer_channel_idx = chansidx(chansidx ~= 0);
        if delete_outerlayer==1
            if isempty(outerlayer_channel_idx)==1
                error(['None of the outer layer channels present in channel locations of data.'...
                    ' Make sure outer layer channels are present in channel labels of data (EEG.chanlocs.labels).']);
            else
                EEG = pop_select( EEG,'nochannel', outerlayer_channel_idx);
                EEG = eeg_checkset( EEG );
            end
        end

        %% STEP 6: Filter data
        high_transband = highpass;
        low_transband = 10;
        
        hp_fl_order = 3.3 / (high_transband / EEG.srate);
        lp_fl_order = 3.3 / (low_transband / EEG.srate);
        
        if mod(floor(hp_fl_order),2) == 0
            hp_fl_order=floor(hp_fl_order);
        elseif mod(floor(hp_fl_order),2) == 1
            hp_fl_order=floor(hp_fl_order)+1;
        end
        
        if mod(floor(lp_fl_order),2) == 0
            lp_fl_order=floor(lp_fl_order)+2;
        elseif mod(floor(lp_fl_order),2) == 1
            lp_fl_order=floor(lp_fl_order)+1;
        end
        
        high_cutoff = highpass/2;
        low_cutoff = lowpass + (low_transband/2);
        
        EEG = eeg_checkset( EEG );
        EEG = pop_firws(EEG, 'fcutoff', high_cutoff, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', hp_fl_order, 'minphase', 0);
        EEG = eeg_checkset( EEG );
        
        EEG = eeg_checkset( EEG );
        EEG = pop_firws(EEG, 'fcutoff', low_cutoff, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', lp_fl_order, 'minphase', 0);
        EEG = eeg_checkset( EEG );

        EEG = pop_eegfiltnew(EEG, 49, 51, [], 1); % notch at 50Hz
        EEG = eeg_checkset(EEG);

        % RH: try outs to remove line noise
        % remove Line noise and harmonics at 50 and 100Hz
        % From Github from Tim Mullen
        % add folder
        %addpath(genpath('/Users/riannehaartsen/Documents/MATLAB/eeglab2024.0/plugins/cleanline-master'))
        % reduce line noise
        %EEG = pop_cleanline(EEG, 'Bandwidth',4,'ChanCompIndices',[1:EEG.nbchan] ,...
        %    'SignalType','Channels','ComputeSpectralPower',true,'LineFrequencies',[50 100] ,...
        %    'NormalizeSpectrum',false,'LineAlpha',0.01,'PaddingFactor',2,'PlotFigures',false,...
        %    'ScanForLines',true,'SmoothingFactor',100,'VerbosityLevel',1,'SlidingWinLength',4,...
        %    'SlidingWinStep',2);

        %% STEP 12: Segment data into fixed length epochs
        if epoch_data==1
            if task_eeg ==1 % task eeg
                EEG = eeg_checkset(EEG);
                EEG = pop_epoch(EEG, task_event_markers, task_epoch_length, 'epochinfo', 'yes');
            elseif task_eeg==0 % resting eeg
                if overlap_epoch==1
                    EEG=eeg_regepochs(EEG,'recurrence',(rest_epoch_length/2),'limits',[0 rest_epoch_length], 'rmbase', [NaN], 'eventtype', char(dummy_events));
                    EEG = eeg_checkset(EEG);
                else
                    EEG=eeg_regepochs(EEG,'recurrence',rest_epoch_length,'limits',[0 rest_epoch_length], 'rmbase', [NaN], 'eventtype', char(dummy_events));
                    EEG = eeg_checkset(EEG);
                end
    
            elseif task_eeg==4 % resting & dynamic videos eeg - 4 conditions
    
                    % 1. Name of eyes close and eyes open markers
                    rest_event_markers = taskonset_event_markers; % video markers
                    % 2. Name of new eyes close and eyes open markers
                    new_rest_markers = dummy_events; % enter markers for epochs
                    % 3. Does the data have a trial end marker?
                    trial_end_marker = 1; % 0=NO (no trial end marker in data), 1=YES (data have trial end marker)
                    trial_end_marker_name= taskoffset_event_markers; % enter trial end marker name
                    % 5. Do you want to create overlapping epoch?
                    overlap_epoch = 0; % 0 = NO (do not create overlapping epoch), 1 = YES (50% overlapping epoch)
    
                    % Insert markers
                    if overlap_epoch==1
                        time_samples = (rest_epoch_length/2)*EEG.srate; % convert time window into samples or data points
                    else
                        time_samples = rest_epoch_length*EEG.srate;
                    end
                    
                    EEG.urevent_all = EEG.event; 
                    EEG.urevent = EEG.event;
                    EEG.event = [];

                    tm=1;
                    for ue=1:length(EEG.urevent)
                        for rm=1:length(rest_event_markers)
                            if strcmp(num2str(EEG.urevent(ue).type), rest_event_markers{rm})
                                if trial_end_marker == 1
                                    for te=ue:length(EEG.urevent)
                                        if strcmp(num2str(EEG.urevent(te).type), trial_end_marker_name{rm})
                                            trial_end_latency = EEG.urevent(te).latency;
                                            break;
                                        end
                                    end
                                else
                                    if ue < length(EEG.urevent)
                                        trial_end_latency=EEG.urevent(ue+1).latency-rest_epoch_length-time_samples;
                                    else
                                        trial_end_latency=length(EEG.times)-rest_epoch_length-time_samples;
                                    end
                                end
                                event_times = EEG.urevent(ue).latency;
                                while (event_times+time_samples) < trial_end_latency
                                    EEG.event(tm).type = str2double(new_rest_markers{rm});
                                    EEG.event(tm).latency = event_times;
                                    event_times = event_times+time_samples;
                                    tm=tm+1;
                                end
                            end
                        end
                    end
                    
                    % adjust the new EEG.events.value and duration
                    for eps = 1:length(EEG.event)
                            EEG.event(eps).value = 'EEGdummy';
                            EEG.event(eps).duration = 1;
                    end
                    % adjust the latencies to round numbers
                    for eps = 1:length(EEG.event)
                            EEG.event(eps).latency = round(EEG.event(eps).latency);
                    end
                    
                    % restore and adjust the EEG.urevent 
                        Nlasturevent = length(EEG.urevent_all);
                        NewUrevents = EEG.urevent_all;
                        NewEvents = EEG.event;
                        for eps = 1:length(EEG.event)
                            % add event into EEG.urevent
                            NewUrevents(Nlasturevent + eps).type = NewEvents(eps).type;
                            NewUrevents(Nlasturevent + eps).latency = NewEvents(eps).latency;
                            NewUrevents(Nlasturevent + eps).duration = NewEvents(eps).duration;
                            NewUrevents(Nlasturevent + eps).urevent = Nlasturevent + eps;
                            % add in index urevent_orig into event field
                            EEG.event(eps).urevent = Nlasturevent + eps;
                        end
                        EEG.urevent = NewUrevents;      

                    % create epoch
                        EEG = eeg_checkset(EEG);
                        EEG = pop_epoch(EEG, new_rest_markers, [0 rest_epoch_length], 'epochinfo', 'yes');
                        EEG = eeg_checkset(EEG);

                        clear tm ue rm trial_end_marker rest_event_markers new_rest_markers event_times trial_end_latency
                        clear Nlasturevent NewUrevents NewEvents
            end
                    
        end
        
        total_epochs_before_artifact_rejection(subject)=EEG.trials;
        
        % check onset markers present for later
        N_TaskOnsetMarkers = zeros(2,size(taskonset_event_markers,2));
        for ss = 1:size(taskonset_event_markers,2)
            curr_marker_onset = taskonset_event_markers{1,ss};  % keep as string
            curr_offset       = taskoffset_event_markers{1,ss}; % keep as string
            count = 0;
            for rr = 1:size(EEG.urevent,1)-2
                rr_type   = num2str(EEG.urevent(rr).type);
                rr1_type  = num2str(EEG.urevent(rr+1).type);
                rr2_type  = num2str(EEG.urevent(rr+2).type);
                if strcmp(rr_type, curr_marker_onset) && strcmp(rr1_type, curr_offset)
                    count = count + 1;
                elseif strcmp(rr_type, curr_marker_onset) && strcmp(rr1_type, '5') && strcmp(rr2_type, curr_offset)
                    count = count + 1;
                elseif strcmp(rr_type, curr_marker_onset) && strcmp(rr1_type, '6') && strcmp(rr2_type, curr_offset)
                    count = count + 1;
                end
            end
            N_TaskOnsetMarkers(:,ss) = [str2double(curr_marker_onset); count];
        end
        clear ss curr_marker_onset curr_offset count rr

        %% STEP 13: Remove baseline
        if remove_baseline==1
            if isempty(baseline_window) % set up for entire epoch
                baseline_window = [EEG.times(1) EEG.times(end)]; % set start and stop times for the baseline window
            end
            EEG = eeg_checkset( EEG );
            EEG = pop_rmbase( EEG, baseline_window);
        end
        
        %% STEP 14: Artifact rejection

        for cc = 1:size(EEG.chanlocs,2)
            Chan_labels_curr{1,cc} = EEG.chanlocs(cc).labels;
        end

        all_bad_epochs=0;
        if allow_missing_chans == 0 
            if voltthres_rejection==1 % check voltage threshold rejection
                if interp_epoch==1 % check epoch level channel interpolation
                    % first pass: loop through frontal channels and reject bad epochs
                    blinkLen = 0.05;
                    maxsd = 2.5;
                    maxr2 = 0.6;
                    EEG_foreog = EEG;

                    % get number of chans/trials
                    numChans = size(EEG_foreog.data, 1);
                    numTrials = EEG_foreog.trials;

                    % Filter data 3-10Hz
                    highpass_eog = 3; lowpass_eog = 10;

                    high_transband_eog = highpass_eog; % high pass transition band
                    low_transband_eog = 10; % low pass transition band
                    hp_eog_fl_order = 3.3 / (high_transband_eog / EEG.srate);
                    lp_eog_fl_order = 3.3 / (low_transband_eog / EEG.srate);
                    
                    if mod(floor(hp_eog_fl_order),2) == 0
                        hp_eog_fl_order=floor(hp_eog_fl_order);
                    elseif mod(floor(hp_eog_fl_order),2) == 1
                        hp_eog_fl_order=floor(hp_eog_fl_order)+1;
                    end
                    
                    if mod(floor(lp_eog_fl_order),2) == 0
                        lp_eog_fl_order=floor(lp_eog_fl_order)+2;
                    elseif mod(floor(lp_eog_fl_order),2) == 1
                        lp_eog_fl_order=floor(lp_eog_fl_order)+1;
                    end
                    
                    high_cutoff_eog = highpass_eog/2;
                    low_cutoff_eog = lowpass_eog + (low_transband_eog/2);

                    EEG_foreog = eeg_checkset( EEG_foreog );
                    EEG_foreog = pop_firws(EEG_foreog, 'fcutoff', high_cutoff_eog, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', hp_eog_fl_order, 'minphase', 0);
                    EEG_foreog = eeg_checkset( EEG_foreog );
                    
                    EEG_foreog = eeg_checkset( EEG_foreog );
                    EEG_foreog = pop_firws(EEG_foreog, 'fcutoff', low_cutoff_eog, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', lp_eog_fl_order, 'minphase', 0);
                    EEG_foreog = eeg_checkset( EEG_foreog );

                    % compute channel z-scores for each trial
                    lens = repmat(size(EEG_foreog.data,2),[1,size(EEG_foreog.data,3)]);
                    for tt = 1:size(EEG_foreog.data,3)
                        if tt == 1
                            cont = EEG_foreog.data(:,:,1);
                        else
                            cont = [cont EEG_foreog.data(:,:,tt)];
                        end
                    end
                    zcont = zscore(cont, [], 2);
                    zData = EEG_foreog;
                    for tr = 1:zData.trials
                        s1 = 1 + ((tr - 1) * lens(tr));
                        s2 = tr * lens(tr);
                        zData.data(:,:,tr) = zcont(:, s1:s2);
                    end
                    zcrit = zData.data > maxsd;
                    
                    blink = false(numChans, numTrials);
                    drift = false(numChans, numTrials);

                    % get indices for frontal channels
                    chans=[]; chansidx=[];chans_labels2=[];
                    chans_labels2=cell(1,EEG.nbchan);
                    for i=1:EEG.nbchan
                        chans_labels2{i}= EEG.chanlocs(i).labels;
                    end
                    [chans,chansidx] = ismember(frontal_channels, chans_labels2);
                    frontal_channels_idx = chansidx(chansidx ~= 0);

                    for tr = 1:numTrials
                        for ch = 1:numChans
                            if any(ismember(frontal_channels_idx,ch))
                                s1 = 1; s2 = length(zData.times); 
                                ct = findcontig2(zcrit(ch, s1:s2, tr)', 1);
                                if ~isempty(ct)
                                    len = ct(:, 3) / zData.srate;
                                    blink(ch, tr) = any(len > blinkLen);
                                end             
                                if ~blink(ch, tr)
                                    [~, gof] = fit(EEG_foreog.times', double(EEG.data(ch, :, tr)'),...
                                        'poly2');
                                    drift(ch, tr) = gof.rsquare >= .65;
                                    clear gof
                                end
                            end
                        end
                    end
                    
                    % collate for tracking
                    AR1_badFrontCh = [blink(frontal_channels_idx,:); drift(frontal_channels_idx,:)];
                    badepoch=zeros(1, EEG.trials);
                        for ii=1:size(AR1_badFrontCh, 2)
                            bad_blink = sum(AR1_badFrontCh([1:3],ii),1);
                            bad_drift = sum(AR1_badFrontCh([4:6],ii),1);
                            if bad_blink >= 2 
                                badepoch(ii)= 1;
                            elseif bad_drift >= 2 
                                badepoch(ii)= 1;
                            elseif bad_blink >= 2 && bad_drift >= 2
                                badepoch(ii)= 1;
                            end
                        end
                        badepoch=logical(badepoch);
                    AR1_blinks = badepoch;

                    clear blinkLen maxsd maxr2 EEG_foreog numChans numTrials
                    clear highpass_eog lowpass_eog low_transband_eog high_transband_eog
                    clear hp_eog_fl_order lp_eog_fl_order high_cutoff_eog low_cutoff_eog
                    clear lens tt cont zcont zData zcrit tr s1 s2 blink drift ch
                   
                    % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
                    if sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
                        all_bad_epochs=1;
                        warning(['No usable data for subject ', subject_folder]);
                        Neps_postAR1 = 0;
                    else
                        EEG = pop_rejepoch( EEG, badepoch, 0);
                        EEG = eeg_checkset(EEG);
                        Neps_postAR1 = EEG.trials;
                    end
    
                    % second pass: loop through all channels and interpolate remaining bad channels at the epoch level
                    if all_bad_epochs==1
                        warning(['No usable data for subject ', subject_folder]);
                    else
                        % Interpolate artifacted data for all remaining channels
                        badChans = zeros(EEG.nbchan, EEG.trials);
                        % Find artifacted epochs by detecting outlier voltage but don't remove
                        for ch=1:EEG.nbchan
                            EEG = pop_eegthresh(EEG,1, ch, volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax,0,0);
                            EEG = eeg_checkset(EEG);
                            EEG = eeg_rejsuperpose(EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                            badChans(ch,:) = EEG.reject.rejglobal;
                        end
                        AR2a_thresholds = badChans; 

                        AR2b_flat = zeros(EEG.nbchan, EEG.trials);
                        AR2c_jumps = zeros(EEG.nbchan, EEG.trials);
                        tmpData = zeros(EEG.nbchan, EEG.pnts, EEG.trials);
                        if run_miniMADE == 0
                            for e = 1:EEG.trials
                                EEGe = []; EEGe_interp = []; badChanNum = [];
                                EEGe = pop_selectevent( EEG, 'epoch', e, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');
                                badChanNum = find(badChans(:,e)==1);
                                EEGe_interp = eeg_interp(EEGe,badChanNum);
                                tmpData(:,:,e) = EEGe_interp.data;
                            end
                        elseif run_miniMADE == 1
                            for e = 1:EEG.trials
                                EEGe = []; EEGe_interp = []; badChanNum = [];
                                EEGe = pop_selectevent( EEG, 'epoch',e,'deleteevents','off','deleteepochs','on','invertepochs','off');
                                badChanNum = find(badChans(:,e)==1);

                                % find and add flat chans to the bad chans list
                                flatChanNum = find(range(EEGe.data,2) < 1);
                                badChanNum  = unique([badChanNum; flatChanNum]);

                                % find chans with a large jump/deflection
                                Timepersample = 1/EEGe.srate; Steps = .004/Timepersample;
                                Npoints = length(EEGe.data);
                                differences = zeros(size(EEGe.data,1), Npoints - Steps);
                                for ii = 1:(Npoints - Steps)
                                    differences(:,ii) = EEGe.data(:,(ii + Steps)) - EEGe.data(:,ii);
                                end
                                [jump_chans, ~] = find(abs(differences) > 100); 
                                badChanNum = unique([badChanNum; unique(jump_chans)]);

                                % interpolate using bad channel list with extra checks
                                if length(badChanNum) < EEGe.nbchan - 1
                                    EEGe_interp = eeg_interp(EEGe,badChanNum);
                                    if size(EEGe_interp.data, 1) == EEG.nbchan
                                        tmpData(:,:,e) = EEGe_interp.data;
                                    else
                                        fprintf('    Epoch %i: wrong channel count after interp, marking bad\n', e);
                                        tmpData(:,:,e) = EEGe.data;
                                        badChans(:,e) = 1;
                                    end
                                else
                                    fprintf('    Epoch %i: too many bad channels (%i/%i), marking for rejection\n', ...
                                        e, length(badChanNum), EEGe.nbchan);
                                    tmpData(:,:,e) = EEGe.data;
                                    badChans(:,e) = 1;
                                end
                                badChans(badChanNum,e) = 1;

                                if ~isempty(flatChanNum)
                                    AR2b_flat(flatChanNum,e) = 1;
                                end
                                if ~isempty(jump_chans)
                                    AR2c_jumps(jump_chans,e) = 1;
                                end
                                AR2_thr_flat_jump = badChans;
                            end
                        end
                        EEG.data = tmpData;
    
                        % If more than 20% of channels in an epoch were interpolated, reject that epoch
                        badepoch=zeros(1, EEG.trials);
                        for ei=1:EEG.trials
                            NumbadChan = badChans(:,ei);
                            if sum(NumbadChan) > round((20/100)* size(chans_labels2,2))
                                badepoch (ei)= sum(NumbadChan);
                            end
                        end
                        badepoch=logical(badepoch);
                        Eps_BAD_InvalidInterp = badepoch;
                    end
                    % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
                    if sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
                        all_bad_epochs=1;
                        warning(['No usable data for subject ', subject_folder]);
                        Neps_postAR2 = 0;
                    else
                        EEG = pop_rejepoch(EEG, badepoch, 0);
                        EEG = eeg_checkset(EEG);
                        Neps_postAR2 = EEG.trials;
                    end

                else % if no epoch level channel interpolation
                    if run_miniMADE == 0
                        EEG = pop_eegthresh(EEG, 1, (1:EEG.nbchan), volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax, 0, 0);
                        EEG = eeg_checkset(EEG);
                        EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                    elseif run_miniMADE == 1
                        badChans = zeros(EEG.nbchan, EEG.trials);
                        for ch=1:EEG.nbchan
                            EEG = pop_eegthresh(EEG,1, ch, volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax,0,0);
                            EEG = eeg_checkset(EEG);
                            EEG = eeg_rejsuperpose(EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                            badChans(ch,:) = EEG.reject.rejglobal;
                        end
                        tmpData = zeros(EEG.nbchan, EEG.pnts, EEG.trials);
                        for e = 1:EEG.trials
                            EEGe = []; badChanNum = [];
                            EEGe = pop_selectevent( EEG, 'epoch',e,'deleteevents','off','deleteepochs','on','invertepochs','off');
                            badChanNum = find(badChans(:,e)==1);
                            flatChanNum = find(range(EEGe.data,2) < 1);
                            badChanNum  = unique([badChanNum; flatChanNum]);
                            [jump_chans, ~] = find( abs(diff(EEGe.data,1,2) ./ repmat(diff(1:EEGe.pnts),EEGe.nbchan,1)) > 50);
                            badChanNum = unique([badChanNum; unique(jump_chans)]);
                            badChans(badChanNum,e) = 1;
                        end
                        badepoch=zeros(1, EEG.trials);
                        for ei=1:EEG.trials
                            if sum(badChans(:,ei)) > 0
                                badepoch (ei)= 1;
                            end
                        end
                        badepoch=logical(badepoch);
                    end
                    % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
                    rejthresh_sum = 0;
                    if isfield(EEG, 'reject') && isfield(EEG.reject, 'rejthresh') && ~isempty(EEG.reject.rejthresh)
                        rejthresh_sum = sum(EEG.reject.rejthresh);
                    end
                    if rejthresh_sum==EEG.trials || rejthresh_sum+1==EEG.trials || sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
                        all_bad_epochs=1;
                        warning(['No usable data for subject ', subject_folder]);
                    else
                        if run_miniMADE == 0
                            EEG = pop_rejepoch(EEG,(EEG.reject.rejthresh), 0);
                            EEG = eeg_checkset(EEG);
                        elseif run_miniMADE == 1
                            EEG = pop_rejepoch(EEG, badepoch, 0);
                            EEG = eeg_checkset(EEG);
                        end
                    end
                end % end of epoch level channel interpolation if statement
            end % end of voltage threshold rejection if statement
            
        elseif allow_missing_chans == 1 % If advanced option to replace bad channels with NaNs is selected
            if rerefer_data==1
                if iscell(reref)==1
                    reref_idx=zeros(1, length(reref));
                    for rr=1:length(reref)
                        reref_idx(rr)=find(strcmp({EEG.chanlocs.labels}, reref{rr}));
                    end
                    reref_chans = reref_idx;
                else
                    reref_chans = reref; 
                end
                EEG = pop_eegthresh(EEG, 1, reref_chans, volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax, 0, 0);
                EEG = eeg_checkset( EEG );
                EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                
                if length(find(EEG.reject.rejthresh)) == EEG.trials || length(find(EEG.reject.rejthresh))+1 == EEG.trials
                    all_bad_epochs = 1;
                else
                    EEG = pop_rejepoch( EEG, (EEG.reject.rejthresh), 0);
                    EEG = eeg_checkset(EEG);
                    EEG = eeg_checkset(EEG);
                    EEG = pop_reref( EEG, reref_chans);
                end
            end
            
            chans=[]; chans_labels2=[];
            chans_labels2=cell(1,EEG.nbchan);
            for i=1:EEG.nbchan
                chans_labels2{i}= EEG.chanlocs(i).labels;
            end
                
            if all_bad_epochs == 0 && blink_check == 1
                frontal_channels_idx=zeros(1, length(frontal_channels));
                for rr=1:length(frontal_channels)
                    frontal_channels_idx(rr)=find(strcmp({EEG.chanlocs.labels}, frontal_channels{rr}));
                end
                EEG = pop_eegthresh(EEG, 1, frontal_channels_idx, volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax, 0, 0);
                EEG = eeg_checkset( EEG );
                EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                blink_epochs = find(sum(EEG.reject.rejthreshE(frontal_channels_idx,:))==length(frontal_channels_idx));
                if length(blink_epochs) == EEG.trials || length(blink_epochs)+1 == EEG.trials
                    all_bad_epochs = 1;
                else
                    EEG = pop_rejepoch( EEG, blink_epochs, 0);
                    EEG = eeg_checkset(EEG);
                end
            end
            
            if all_bad_epochs == 0
                badChans = zeros(EEG.nbchan, EEG.trials);
                for ch=1:EEG.nbchan
                    EEG = pop_eegthresh(EEG,1, ch, volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax,0,0);
                    EEG = eeg_checkset(EEG);
                    EEG = eeg_rejsuperpose(EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                    badChans(ch,:) = EEG.reject.rejglobal;
                end
                tmpData = zeros(EEG.nbchan, EEG.pnts, EEG.trials);
                for e = 1:EEG.trials
                    EEGe = []; badChanNum = [];
                    EEGe = pop_selectevent( EEG, 'epoch',e,'deleteevents','off','deleteepochs','on','invertepochs','off');
                    badChanNum = find(badChans(:,e)==1);
                    flatChanNum = [find(range(EEGe.data(:,1:(EEG.pnts/2)),2) < 1); find(range(EEGe.data(:,(EEG.pnts/2):EEG.pnts),2) < 1)];
                    badChanNum  = unique([badChanNum; unique(flatChanNum)]);
                    [jump_chans, ~] = find( abs(diff(EEGe.data,1,2) ./ repmat(diff(1:EEGe.pnts),EEGe.nbchan,1)) > 50);
                    badChanNum = unique([badChanNum; unique(jump_chans)]);
                    badChans(badChanNum,e) = 1;
                    EEGe = eeg_checkset( EEGe );
                    EEGe.data(badChanNum,:) = NaN;
                    tmpData(:,:,e) = EEGe.data;
                end
                EEG.data = tmpData;
                
                badepoch=zeros(1, EEG.trials);
                for ei=1:EEG.trials
                    if sum(badChans(:,ei)) > chan_thresh*EEG.nbchan
                        badepoch(ei)= 1;
                    end
                end
                badepoch=logical(badepoch);
                if sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
                    all_bad_epochs=1;
                    warning(['No usable data for subject ', subject_folder]);
                else
                    EEG = pop_rejepoch(EEG, badepoch, 0);
                    EEG = eeg_checkset(EEG);
                    badChans = badChans(:,~badepoch);
                end
                    
                total_epochs_by_chan_after_artifact_rejection = {'';[]}; badChansSum = [];
                total_epochs_by_chan_after_artifact_rejection(1,1:EEG.nbchan) = strcat(chans_labels2,'_total_epochs_after_artifact_rejection');
                badChansSum = sum((badChans-1)*-1,2)'; 
                for cch = 1:EEG.nbchan
                    total_epochs_by_chan_after_artifact_rejection{2,cch} = badChansSum(cch);
                end
            else
                total_epochs_by_chan_after_artifact_rejection = {'';[]}; badChansSum = [];
                total_epochs_by_chan_after_artifact_rejection(1,1:EEG.nbchan) = strcat(chans_labels2,'_total_epochs_after_artifact_rejection');
                for cch = 1:EEG.nbchan
                    total_epochs_by_chan_after_artifact_rejection{2,cch} = 0;
                end
            end
            total_epochs_by_chan_after_artifact_rejection{1,EEG.nbchan+1} = 'datafile_names';
            total_epochs_by_chan_after_artifact_rejection{2,EEG.nbchan+1} = subject_folder;
        end % end advanced option to use NaNs
        
        % if all epochs are found bad during artifact rejection
        if all_bad_epochs==1
            total_epochs_after_artifact_rejection(subject)=0;
            total_channels_interpolated(subject)=0;
            if output_format==1
                EEG = eeg_checkset(EEG);
                EEG = pop_editset(EEG, 'setname', [subject_folder '_no_usable_data_all_bad_epochs']);
                EEG = pop_saveset(EEG, 'filename', [subject_folder '_no_usable_data_all_bad_epochs.set'], ...
                    'filepath', ppt_out_folder);
            elseif output_format==2
                save([[output_location filesep 'processed_data' filesep] subject_folder '_no_usable_data_all_bad_epochs.mat'], 'EEG');
            end
            continue % ignore rest of the processing and go to next datafile
        else
            total_epochs_after_artifact_rejection(subject)=EEG.trials;
        end
        
        %% STEP 15: Interpolate deleted channels - not for low-density
        
        %% STEP 16: Rereference data
        if allow_missing_chans == 0
            if rerefer_data==1
                if iscell(reref)==1
                    reref_idx=zeros(1, length(reref));
                    for rr=1:length(reref)
                        reref_idx(rr)=find(strcmp({EEG.chanlocs.labels}, reref{rr}));
                    end
                    EEG = eeg_checkset(EEG);
                    EEG = pop_reref( EEG, reref_idx);
                else
                    EEG = eeg_checkset(EEG);
                    EEG = pop_reref(EEG, reref);
                end
            end
        end
        
        %% Save processed data
        savedDataPath = fullfile(ppt_out_folder, [subject_folder '_processed_data.set']);
        if output_format==1
            EEG = eeg_checkset(EEG);
            EEG = pop_editset(EEG, 'setname', [subject_folder '_processed_data']);
            EEG = pop_saveset(EEG, 'filename', [subject_folder '_processed_data.set'], ...
                'filepath', ppt_out_folder);
        elseif output_format==2
            save([[output_location filesep 'processed_data' filesep] subject_folder '_processed_data.mat'], 'EEG');
        end

        catch ME
                fprintf('ERROR processing %s:\n%s\n', subject_folder, ME.message);
                fprintf('Error on line: %i\n', ME.stack(1).line);
                for k = 1:length(ME.stack)
                    fprintf('  Stack %i: %s line %i\n', k, ME.stack(k).name, ME.stack(k).line);
                end
                if length(total_epochs_before_artifact_rejection) < subject || isempty(total_epochs_before_artifact_rejection(subject))
                    total_epochs_before_artifact_rejection(subject) = NaN;
                end 
                if length(total_epochs_after_artifact_rejection) < subject || isempty(total_epochs_after_artifact_rejection(subject))
                    total_epochs_after_artifact_rejection(subject) = NaN;
                end
                continue
            end

    %% Update tracker
    NewRow.ID                 = {subject_folder};
    NewRow.PreprocEEG         = {savedDataPath};
    NewRow.EpsBefore          = total_epochs_before_artifact_rejection(subject);
    NewRow.EpsAfter           = total_epochs_after_artifact_rejection(subject);
    NewRow.Neps_postAR1       = Neps_postAR1;
    NewRow.Neps_postAR2       = Neps_postAR2;
    NewRow.N_TaskOnsetMarkers = {N_TaskOnsetMarkers};
    NewRow.Chan_labels        = {Chan_labels_curr};

    TrackerNew        = struct2table(NewRow);
    SP_preproc_record = [SP_preproc_record; TrackerNew];
    save(tracker_file, 'SP_preproc_record');

    fprintf('\n*** Done: %s | Before AR: %i | After AR: %i ***\n', ...
        subject_folder, ...
        total_epochs_before_artifact_rejection(subject), ...
        total_epochs_after_artifact_rejection(subject));

end % end of subject loop

disp('Done')

