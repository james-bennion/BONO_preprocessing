function fJB_convert_correct_easy_set(root_folder, marker_folder, csv_path, out_folder)
    %% Convert .easy files to .set for miniMADE pipeline
    % For participants with rescuedmarkers_filecheck == 1: apply marker correction first
    % For participants with rescuedmarkers_filecheck == 0: simple .easy to .set conversion
    % Skips participants with multiple .easy files or multiple ses folders

    % Created by James Bennion, Birkbeck, 2026

    %% Make outdir if doesn't exist
    if ~exist(out_folder, 'dir')
        mkdir(out_folder);
    end

    %% Load CSV
    csv = readtable(csv_path);
    fprintf('Loaded CSV with %i rows\n', height(csv));

    %% Get participant folders
    ppt_dirs = dir(root_folder);
    ppt_dirs = ppt_dirs([ppt_dirs.isdir] & ~startsWith({ppt_dirs.name}, '.'));
    fprintf('Found %i participant folders\n', numel(ppt_dirs));

    %% Initialise tracker
    tracker_file       = fullfile(out_folder, 'conversion_tracker.mat');
    conversion_tracker = table();
    fprintf('Starting fresh tracker\n');

    %% Loop through participants
    for pp = 1:numel(ppt_dirs)

        ppt_name    = ppt_dirs(pp).name;
        fprintf('\n--- Processing: %s (%i/%i) ---\n', ppt_name, pp, numel(ppt_dirs));

        % Initialise tracker row for this participant
        skipped     = 0;
        skip_reason = '';
        set_location = '';

        %% Find matching CSV row
        csv_row = find(csv.subject_id == str2double(ppt_name));
        if isempty(csv_row)
            fprintf('  No CSV entry found for %s, skipping\n', ppt_name);
            skipped     = 1;
            skip_reason = 'no_csv';
            NewRow.ID          = {ppt_name};
            NewRow.Skipped     = skipped;
            NewRow.SkipReason  = {skip_reason};
            NewRow.SetLocation = {set_location};
            conversion_tracker = [conversion_tracker; struct2table(NewRow)];
            save(tracker_file, 'conversion_tracker');
            continue
        end

        needs_markers = csv.rescuedmarkers_filecheck(csv_row);
        fprintf('  rescuedmarkers_filecheck = %i\n', needs_markers);

        %% Check output already exists
        out_ppt_folder = fullfile(out_folder, ppt_name);
        set_check      = dir(fullfile(out_ppt_folder, '*.set'));
        if ~isempty(set_check)
            fprintf('  .set already exists, skipping\n');
            continue
        end

        %% Find session folder
        ppt_path = fullfile(root_folder, ppt_name);
        ses_dirs = dir(ppt_path);
        ses_dirs = ses_dirs([ses_dirs.isdir] & ~startsWith({ses_dirs.name}, '.'));

        if isempty(ses_dirs)
            fprintf('  No session folders found, skipping\n');
            skipped     = 1;
            skip_reason = 'no_ses_folders';
            NewRow.ID          = {ppt_name};
            NewRow.Skipped     = skipped;
            NewRow.SkipReason  = {skip_reason};
            NewRow.SetLocation = {set_location};
            conversion_tracker = [conversion_tracker; struct2table(NewRow)];
            save(tracker_file, 'conversion_tracker');
            continue
        end

        if numel(ses_dirs) > 1
            fprintf('  Multiple session folders found, skipping\n');
            skipped     = 1;
            skip_reason = 'multiple_ses_folders';
            NewRow.ID          = {ppt_name};
            NewRow.Skipped     = skipped;
            NewRow.SkipReason  = {skip_reason};
            NewRow.SetLocation = {set_location};
            conversion_tracker = [conversion_tracker; struct2table(NewRow)];
            save(tracker_file, 'conversion_tracker');
            continue
        end

        %% Find .easy file
        enobio_path = fullfile(ppt_path, ses_dirs.name, 'enobio');

        if ~isfolder(enobio_path)
            fprintf('  No enobio folder found, skipping\n');
            skipped     = 1;
            skip_reason = 'no_enobio_folder';
            NewRow.ID          = {ppt_name};
            NewRow.Skipped     = skipped;
            NewRow.SkipReason  = {skip_reason};
            NewRow.SetLocation = {set_location};
            conversion_tracker = [conversion_tracker; struct2table(NewRow)];
            save(tracker_file, 'conversion_tracker');
            continue
        end

        easy_files = dir(fullfile(enobio_path, '*.easy'));

        if isempty(easy_files)
            fprintf('  No .easy file found, skipping\n');
            skipped     = 1;
            skip_reason = 'no_easy';
            NewRow.ID          = {ppt_name};
            NewRow.Skipped     = skipped;
            NewRow.SkipReason  = {skip_reason};
            NewRow.SetLocation = {set_location};
            conversion_tracker = [conversion_tracker; struct2table(NewRow)];
            save(tracker_file, 'conversion_tracker');
            continue
        end

        if numel(easy_files) > 1
            fprintf('  Multiple .easy files found, skipping\n');
            skipped     = 1;
            skip_reason = 'multiple_easy';
            NewRow.ID          = {ppt_name};
            NewRow.Skipped     = skipped;
            NewRow.SkipReason  = {skip_reason};
            NewRow.SetLocation = {set_location};
            conversion_tracker = [conversion_tracker; struct2table(NewRow)];
            save(tracker_file, 'conversion_tracker');
            continue
        end

        easy_path = fullfile(easy_files.folder, easy_files.name);
        fprintf('  Found .easy: %s\n', easy_files.name);

        %% Create output folder for this participant
        if ~exist(out_ppt_folder, 'dir')
            mkdir(out_ppt_folder);
        end

        out_name = sprintf('%s_corrected', ppt_name);

        try
            if needs_markers == 1
                %% Marker correction fork
                fprintf('  Applying marker correction...\n');

                marker_ppt_path = fullfile(marker_folder, ppt_name);
                if ~isfolder(marker_ppt_path)
                    fprintf('  No matching marker folder for %s, skipping\n', ppt_name);
                    skipped     = 1;
                    skip_reason = 'no_marker_folder';
                    NewRow.ID          = {ppt_name};
                    NewRow.Skipped     = skipped;
                    NewRow.SkipReason  = {skip_reason};
                    NewRow.SetLocation = {set_location};
                    conversion_tracker = [conversion_tracker; struct2table(NewRow)];
                    save(tracker_file, 'conversion_tracker');
                    continue
                end

                marker_ses_dirs = dir(marker_ppt_path);
                marker_ses_dirs = marker_ses_dirs([marker_ses_dirs.isdir] & ...
                    ~startsWith({marker_ses_dirs.name}, '.') & ...
                    ~startsWith({marker_ses_dirs.name}, 'ses'));

                if isempty(marker_ses_dirs)
                    fprintf('  No session folder in marker directory, skipping\n');
                    skipped     = 1;
                    skip_reason = 'no_marker_ses_folder';
                    NewRow.ID          = {ppt_name};
                    NewRow.Skipped     = skipped;
                    NewRow.SkipReason  = {skip_reason};
                    NewRow.SetLocation = {set_location};
                    conversion_tracker = [conversion_tracker; struct2table(NewRow)];
                    save(tracker_file, 'conversion_tracker');
                    continue
                end

                tsv_files = dir(fullfile(marker_ppt_path, marker_ses_dirs(1).name, '*.tsv'));
                if isempty(tsv_files)
                    fprintf('  No .tsv file found in marker folder, skipping\n');
                    skipped     = 1;
                    skip_reason = 'no_tsv';
                    NewRow.ID          = {ppt_name};
                    NewRow.Skipped     = skipped;
                    NewRow.SkipReason  = {skip_reason};
                    NewRow.SetLocation = {set_location};
                    conversion_tracker = [conversion_tracker; struct2table(NewRow)];
                    save(tracker_file, 'conversion_tracker');
                    continue
                end

                tsv_path = fullfile(tsv_files(1).folder, tsv_files(1).name);
                fprintf('  Found .tsv: %s\n', tsv_files(1).name);

                fJB_correct_markers_from_tsv(tsv_path, easy_path, out_ppt_folder, out_name);
                fprintf('  Saved corrected .set\n');

            else
                %% Simple conversion fork
                fprintf('  Simple .easy to .set conversion...\n');
                EEG = pop_easy(easy_path, 0, 0, []);
                EEG = eeg_checkset(EEG);
                EEG = pop_saveset(EEG, 'filename', [out_name '.set'], 'filepath', out_ppt_folder);
                fprintf('  Saved .set\n');
            end

            set_location = fullfile(out_ppt_folder, [out_name '.set']);

        catch ME
            fprintf('  ERROR: %s\n', ME.message);
            fprintf('  Line: %i\n', ME.stack(1).line);
            skipped     = 1;
            skip_reason = ['error: ' ME.message];
        end

        %% Update tracker
        NewRow.ID          = {ppt_name};
        NewRow.Skipped     = skipped;
        NewRow.SkipReason  = {skip_reason};
        NewRow.SetLocation = {set_location};
        conversion_tracker = [conversion_tracker; struct2table(NewRow)];
        save(tracker_file, 'conversion_tracker');

    end % participants

    fprintf('\nDone. Output in: %s\n', out_folder);
end