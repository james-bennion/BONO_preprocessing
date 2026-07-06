%% **** Script to extract power & PLI/Coh into simple spreadsheets *******

% This is a quick data wrangling script to extract the power, PLI, and Coherence values that are in fiddly .mat structures from Rianne's
% functions into spreadsheets if you wanted to do data analysis outside of MATLAB.

% Output CSVs will have following structure:
%   spectral_power: condition, participant_id, ntrials, <band cols>
%   wpli:           condition, participant_id, ntrials, band, channel_1, channel_2, value

% Created by James Bennion, Birkbeck, Jul 2026

% ************************************************************************
%% Paths & Setup
clear; clc;
spectral_power_dir = 'YOUR PATH TO POWER RESULTS';
wpli_dir           = 'YOUR PATH TO WPLI RESULTS';
output_dir         = 'YOUR DESIRED OUTPUT PATH';

if ~exist(output_dir, 'dir'); mkdir(output_dir); end

% Channel labels
channel_labels = {'P7','P4','Cz','Pz','P3','P8','Oz','T8','PO8',...
                  'C4','F4','AF8','Fz','C3','F3','AF7','T7','PO7','Fpz'};
n_channels = numel(channel_labels);

% Frequency bands
bands.Delta = [1  4];
bands.Theta = [4  8];
bands.Alpha = [8  13];
bands.Beta  = [13 30];
bands.Gamma = [30 48];
band_names  = fieldnames(bands);

%% Power

sp_files = dir(fullfile(spectral_power_dir, '*.mat'));
sp_rows  = {};   % will collect one cell-row per participant per condition

for f = 1:numel(sp_files)
   fpath       = fullfile(sp_files(f).folder, sp_files(f).name);
   fname       = sp_files(f).name;        
   participant = erase(fname, '_Power_data.mat');

   if ~ismember(fname(1), '0123456789')  
       fprintf('[SKIP] %s\n', fname);
       continue
   end

   try
       loaded = load(fpath);
       D      = loaded.DATA;
        
       band_fields = fieldnames(D);
       band_fields = band_fields(ismember(band_fields, {'Delta','Theta','Alpha','Beta','Gamma'}));

       for row = 1:numel(D)
           cond_str = strtrim(lower(D(row).Cond));
           nt       = D(row).Ntrials;

           if nt < 1
               fprintf('[SKIP] %s - %s has no trials\n', participant, cond_str);
               continue
           end

           for ch = 1:n_channels
               entry.condition      = cond_str;
               entry.channel        = channel_labels{ch};

               for b = 1:numel(band_fields)
                   bf       = band_fields{b};
                   val      = D(row).(bf);     % 19x1 for this condition
                   entry.(bf) = val(ch);
               end

               entry.participant_id = participant;
               entry.ntrials        = nt;
               sp_rows{end+1}       = entry;
           end
       end

   catch e
       fprintf('[WARN] Spectral power — could not load %s: %s\n', fpath, e.message);
   end
end

% convert to table and write
if ~isempty(sp_rows)
   sp_table = struct2table([sp_rows{:}]);
   writetable(sp_table, fullfile(output_dir, 'spectral_power.csv'));
   fprintf('[SAVED] spectral_power.csv  (%d rows)\n', height(sp_table));
else
   fprintf('[WARNING] No spectral power data extracted.\n');
end

%% Connectivity

wpli_files = dir(fullfile(wpli_dir, '*.mat'));
wpli_rows  = {};

for f = 1:numel(wpli_files)
    fpath       = fullfile(wpli_files(f).folder, wpli_files(f).name);
    fname       = wpli_files(f).name;      
    participant = erase(fname, '_wpli_data.mat');

    clear glob_PLI glob_dPLI glob_WPLI glob_ubPLI glob_dbWPLI ...
          glob_Coh glob_iCoh glob_Coherency glob_CohZ_mag glob_CohZ_imag ...
          freq_vec data_fc

    if ~ismember(fname(1), '0123456789')   
        fprintf('[SKIP] %s\n', fname);
        continue
    end

    try
        loaded   = load(fpath);
        data_fc  = loaded.DATA_fc;

        for ci = 1:numel(data_fc)
            cond_str    = strtrim(lower(data_fc(ci).Cond));
            nt          = data_fc(ci).Ntrials;

            if nt < 1
                fprintf('[SKIP] %s - %s has no trials\n', participant, cond_str);
                continue
            end
            
            freq_vec = data_fc(ci).FC_freqs;
            glob_PLI = data_fc(ci).FC_globPLI;
            glob_dPLI = data_fc(ci).FC_globdPLI;
            glob_WPLI = data_fc(ci).FC_globWPLI;
            glob_ubPLI = data_fc(ci).FC_globubPLI;
            glob_dbWPLI = data_fc(ci).FC_globdbWPLI;
            glob_Coh = data_fc(ci).FC_globCoh;
            glob_iCoh = data_fc(ci).FC_globiCoh;
            glob_Coherency = data_fc(ci).FC_globCoherency;
            glob_CohZ_mag = data_fc(ci).FC_globCohZ_mag;
            glob_CohZ_imag = data_fc(ci).FC_globCohZ_imag;

        
            for b = 1:numel(band_names)
                band  = band_names{b};
                f_lo  = bands.(band)(1);
                f_hi  = bands.(band)(2);
                f_idx = freq_vec >= f_lo & freq_vec <= f_hi;

                if ~any(f_idx)
                    fprintf('[WARN] %s - %s - %s: no frequencies in band\n', ...
                        participant, cond_str, band);
                    continue
                end
        
                clear entry
                entry.participant_id = participant;
                entry.condition      = cond_str;
                entry.ntrials        = nt;
                entry.band           = band;
                entry.PLI       = mean(glob_PLI(f_idx));
                entry.dPLI      = mean(glob_dPLI(f_idx));
                entry.WPLI      = mean(glob_WPLI(f_idx));
                entry.ubPLI     = mean(glob_ubPLI(f_idx));
                entry.dbWPLI    = mean(glob_dbWPLI(f_idx));
                entry.Coh       = mean(glob_Coh(f_idx));
                entry.iCoh      = mean(glob_iCoh(f_idx));
                entry.Coherency = mean(glob_Coherency(f_idx));
                entry.CohZ_mag  = mean(glob_CohZ_mag(f_idx));
                entry.CohZ_imag = mean(glob_CohZ_imag(f_idx));                
                wpli_rows{end+1} = entry;
            end
        end

    catch e
        fprintf('[WARN] wPLI — could not load %s: %s\n', fpath, e.message);
    end
end

%% Convert to table and write
if ~isempty(wpli_rows)
    wpli_table = struct2table([wpli_rows{:}]);
    writetable(wpli_table, fullfile(output_dir, 'fc_global_bands.csv'));
    fprintf('[SAVED] fc_global_bands.csv (%d rows)\n', height(wpli_table));
else
    fprintf('[WARN] No FC data extracted.\n');
end
fprintf('\nDone.\n');