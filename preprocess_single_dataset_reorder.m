%% EEG Preprocessing Pipeline for Single Dataset

% Define file path
basePath = './files/ADHD/';  % Change to your dataset's directory
capPath = './files/Standard-10-20-Cap19new/Standard-10-20-Cap19new.ced';  % Your electrode layout
savePath = './files/Preprocessing Data Sets 2/';  % Output directory for processed data

% Ensure save directories exist
outputFolder = fullfile(savePath, 'Processed Single Dataset');
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end

% Load the dataset
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');  % Start EEGLAB without GUI

% Specify the file name for the dataset you want to process (change filename accordingly)
inputFile = fullfile(basePath, 'v3p.mat');  % Change to the actual dataset name
[~, baseName, ~] = fileparts(inputFile);

% Import EEG data
EEG = pop_importdata('dataformat', 'matlab', 'nbchan', 0, 'data', inputFile, ...
    'setname', baseName, 'srate', 128, 'subject', baseName, 'pnts', 0, ...
    'xmin', 0, 'group', 'EXP', 'chanlocs', capPath);

% Save raw EEG dataset (save raw data for reference)
EEG = pop_saveset(EEG, 'filename', [baseName, '_raw.set'], 'filepath', savePath);

%% Debugging Step 1: Clean Raw Data - Settings need editing ie burst criterion off
% Clean EEG data to remove artifacts (you can tweak the parameters)
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidean');

EEG = pop_reref(EEG, []);  % Re-reference to the average of all channels (can specify specific channels)

EEG = pop_saveset(EEG, 'filename', [baseName, '_CRD.set'], 'filepath', savePath);
%% Moved the first high pass 1 Hz filter here

% Apply a high-pass filter (e.g., 1Hz) or band-pass filter as needed
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 1);  % High-pass filter at 1Hz

% Save the cleaned EEG dataset
EEG = pop_saveset(EEG, 'filename', [baseName, '_cleaned.set'], 'filepath', outputFolder);

%% Debugging Step 2: ICA for Artifact Removal
% Run ICA on the cleaned data (you can change the number of components or settings)
numChannels = size(EEG.data, 1);  % Number of channels in the dataset
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'rndreset', 'yes', ...
    'interrupt', 'on', 'pca', numChannels);

% Label ICA components
EEG = pop_iclabel(EEG, 'default');  % Label components based on predefined categories

% Save the ICA dataset
EEG = pop_saveset(EEG, 'filename', [baseName, '_ICA.set'], 'filepath', outputFolder);

%% Blink ERP Extraction Component
% Automatically assign vEOG IC based on ICLabel results
EEG = select_vEOG_IC(EEG, 0.9);  % You can tweak the threshold if needed

% Now process blink events and epochs
processEEGWithBlinks(EEG, ALLEEG, CURRENTSET, baseName);

% Save the dataset after blink event detection and epoching
EEG = pop_saveset(EEG, 'filename', [baseName, '_blinkProcessed.set'], 'filepath', outputFolder);

%% Back to Pre Blink ERP Extraction

% Need load appropriate file function here

% Flag artifacts (use pop_icflag for automatic removal)
EEG = pop_icflag(EEG, [NaN NaN; 0.95 1; 0.95 1; NaN NaN; 0.95 1; NaN NaN; NaN NaN]);

% Save the ICA dataset
EEG = pop_saveset(EEG, 'filename', [baseName, '_ICA.set'], 'filepath', outputFolder);

% This here translates the ICA weights to the file file version without a
% filter, its a mess though and needs fixing
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

% Specify the file name for the dataset you want to process (change filename accordingly)
inputFile = fullfile(savePath, baseName, '_CRD.set');  % Change to the actual dataset name

baseName = baseName + "_CRD.set"

% Import EEG data
EEG = pop_loadset('filename', baseName, 'filepath', savePath);

[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'retrieve',3,'study',0); 
EEG = pop_editset(EEG, 'icaweights', 'ALLEEG(4).icaweights', 'icasphere', 'ALLEEG(4).icasphere', 'icachansind', 'ALLEEG(4).icachansind');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_saveset( EEG, 'filename','ADHDP3_CRD_REREF_WICA.set','filepath','/MATLAB Drive/Preprocessing Data Sets 2/');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
pop_selectcomps(EEG, [1:19] );
%% This is where the flagged components should be removed
% We may need to flag them for removal again
% Flag artifacts (use pop_icflag for automatic removal)
EEG = pop_icflag(EEG, [NaN NaN; 0.95 1; 0.95 1; NaN NaN; 0.95 1; NaN NaN; NaN NaN]);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_subcomp( EEG, [], 0);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'savenew','/MATLAB Drive/Preprocessing Data Sets 2/ADHDP3_CRD_REREF pruned with ICA.set','gui','off');

%% Debugging Step 3: Re-referencing Data again to average
% You can apply re-referencing to average reference or specific channels
EEG = pop_reref(EEG, []);  % Re-reference to the average of all channels (can specify specific channels)

% Save the re-referenced data
EEG = pop_saveset(EEG, 'filename', [baseName, '_re-referenced.set'], 'filepath', outputFolder);

%% Debugging Step 4: Filtering (Adjust if needed)

% Alternatively, you can use a band-pass filter between 0.5Hz and 60Hz -
% yeah we want this one
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 60, 'plotfreqz', 1);  % Band-pass filter

% Save the filtered data
EEG = pop_saveset(EEG, 'filename', [baseName, '_filtered.set'], 'filepath', outputFolder);

%% Debugging Step 5: Visualize EEG Data
% You can visualize the EEG data after each step
pop_eegplot(EEG, 1, 1, 1);  % Open EEG plot to visually inspect the data

%% Final Save of Processed Data
% Save the final dataset after all preprocessing steps
EEG = pop_saveset(EEG, 'filename', [baseName, '_final.set'], 'filepath', outputFolder);
fprintf('Processed and saved: %s\n', baseName);

