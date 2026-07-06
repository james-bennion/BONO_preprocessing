function EEG = fJB_correct_markers_from_tsv(tsv_path, easy_path, out_dir, out_name)

%% Add paths
% Add eeglab (only if using this function in isolation, otherwise will automatically
% recognise added in other script and not load in each time)
if ~exist('eeglab', 'file')
    addpath(genpath('C:\Users\benni\Documents\MATLAB\toolboxes\eeglab2026.0.0')); 
    eeglab nogui;
end

%% Read .tsv
fprintf('Reading TSV: %s\n', tsv_path);
tsv = readtable(tsv_path, 'FileType', 'delimitedtext', 'Delimiter', '\t');
tsv_markers = tsv.Marker;

fprintf('  %d rows x %d cols\n', size(tsv, 1), size(tsv, 2));

%% Load .easy via eeglab
fprintf('Loading .easy: %s\n', easy_path);

EEG = pop_easy(easy_path, 0, 0, []);
EEG = eeg_checkset(EEG);

%% Check number of rows in .tsv matches .easy
% I.e., are there the same number of samples in each?
assert(height(tsv) == EEG.pnts, 'Row count mismatch: TSV has %d rows, EEG has %d samples.', height(tsv), EEG.pnts);

fprintf('Sample counts match (%d samples)\n', EEG.pnts);

%% Add markers from .tsv to EEG.event in .easy
fprintf('Adding markers into EEG.event...\n');

event_rows = find(~isnan(tsv_markers) & tsv_markers ~= 0);
fprintf('  Marker events found: %d\n', numel(event_rows));

types    = arrayfun(@(x) num2str(x), tsv_markers(event_rows), 'UniformOutput', false);
latencies = num2cell(event_rows);
durations = num2cell(ones(numel(event_rows), 1));
EEG.event = struct('type', types, 'latency', latencies, 'duration', durations);

EEG = eeg_checkset(EEG, 'eventconsistency');

fprintf('  %d events added to EEG.event.\n', numel(EEG.event));

%% Save files
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fprintf('Saving to: %s\n', fullfile(out_dir, [out_name '.set']));

EEG = pop_saveset(EEG, 'filename', [out_name '.set'], 'filepath', out_dir);

fprintf('Done.\n');

end