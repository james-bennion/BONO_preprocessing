%% **** Summarise BONO EEG data ******************************************

% This script integrates the raw data files, rescued marker files, and properties of the sessions (e.g. multiple .easy files/sessions) into one summary table.

% Created by James Bennion, Birkbeck, Jul 2026
% ************************************************************************
%% Setup
raw_folder = '';                % folder containing raw data
rescuedmarkers_folder = '';     % folder containing rescued markers files
out_folder = '';                % output folder where you want to save the summary

summary_table_path = fullfile(out_folder, 'summary_table_events.csv');

raw_dirs = dir(raw_folder);
raw_dirs = raw_dirs([raw_dirs.isdir] & ~startsWith({raw_dirs.name}, '.'));

marker_dirs = dir(rescuedmarkers_folder);
marker_dirs = marker_dirs([marker_dirs.isdir] & ~startsWith({marker_dirs.name}, '.'));

raw_ids = {raw_dirs.name}';
marker_ids = {marker_dirs.name}';

%% Basic checks
rescuedmarkers_filecheck = ismember(raw_ids, marker_ids);

session_count = zeros(length(raw_ids), 1);
multiplesessions_check = zeros(length(raw_ids), 1);

easyfile_count = zeros(length(raw_ids), 1);
multiple_easy_check = zeros(length(raw_ids), 1);

events_exist = repmat("NA", length(raw_ids), 1);

%% Loop through subjects
for i = 1:length(raw_ids)

    subject_path = fullfile(raw_folder, raw_ids{i});

    %% Check multiple sessions
    session_dirs = dir(subject_path);
    session_dirs = session_dirs([session_dirs.isdir] & ...
        ~startsWith({session_dirs.name}, '.'));

    session_count(i) = length(session_dirs);
    multiplesessions_check(i) = session_count(i) > 1;

    total_easy = 0;
    multiple_easy_flag = 0;

    %% Loop through sessions
    for j = 1:length(session_dirs)

        enobio_path = fullfile(subject_path, session_dirs(j).name, 'enobio');

        if isfolder(enobio_path)

            easy_files = dir(fullfile(enobio_path, '*.easy'));
            n_easy = length(easy_files);

            total_easy = total_easy + n_easy;

            if n_easy > 1
                multiple_easy_flag = 1;
            end
        end
    end

    easyfile_count(i) = total_easy;
    multiple_easy_check(i) = multiple_easy_flag;

    %% Check that EEG.events (i.e. markers) exist for the simple cases
    % Simple cases are those with no rescued markers, single sessions, and single .easy files

    if rescuedmarkers_filecheck(i) == 0 && ...
       multiplesessions_check(i) == 0 && ...
       multiple_easy_check(i) == 0

        for j = 1:length(session_dirs)
            enobio_path = fullfile(subject_path, session_dirs(j).name, 'enobio');
            if isfolder(enobio_path)
                easy_files = dir(fullfile(enobio_path, '*.easy'));
                if ~isempty(easy_files)
                    easy_path = fullfile(enobio_path, easy_files(1).name);
                    try
                        EEG = pop_easy(easy_path, 0, 0, []);
                        if ~isempty(EEG.event)
                            events_exist(i) = "1";
                        else
                            events_exist(i) = "0";
                        end
                    catch
                        events_exist(i) = "unreadable"; 
                    end
                end
            end
        end
    end
end

%% Build summary table
summary_table = table(raw_ids, rescuedmarkers_filecheck, ...
    multiplesessions_check, session_count, ...
    multiple_easy_check, easyfile_count, ...
    events_exist, ...
    'VariableNames', {'subject_id', 'rescuedmarkers_filecheck', ...
    'multiplesessions_check', 'session_count', ...
    'multiple_easy_check', 'easyfile_count', ...
    'events_exist'});

%% Save
writetable(summary_table, summary_table_path);