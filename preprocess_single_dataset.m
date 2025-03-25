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

%% Debugging Step 1: Clean Raw Data
% Clean EEG data to remove artifacts (you can tweak the parameters)
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 20, ...
    'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidean');

% Save the cleaned EEG dataset
EEG = pop_saveset(EEG, 'filename', [baseName, '_cleaned.set'], 'filepath', outputFolder);

%% Debugging Step 2: ICA for Artifact Removal
% Run ICA on the cleaned data (you can change the number of components or settings)
numChannels = size(EEG.data, 1);  % Number of channels in the dataset
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'rndreset', 'yes', ...
    'interrupt', 'on', 'pca', numChannels);

% Label ICA components and flag artifacts (use pop_icflag for automatic removal)
EEG = pop_iclabel(EEG, 'default');  % Label components based on predefined categories
EEG = pop_icflag(EEG, [NaN NaN; 0.95 1; 0.95 1; NaN NaN; 0.95 1; NaN NaN; NaN NaN]);

% Save the ICA dataset
EEG = pop_saveset(EEG, 'filename', [baseName, '_ICA.set'], 'filepath', outputFolder);

% Automatically assign vEOG IC based on ICLabel results
EEG = select_vEOG_IC(EEG, 0.9);  % You can tweak the threshold if needed

% Now process blink events and epochs
[EEG, ALLEEG, CURRENTSET] = processEEGWithBlinks(EEG, ALLEEG, CURRENTSET);

% Save the dataset after blink event detection and epoching
EEG = pop_saveset(EEG, 'filename', [baseName, '_blinkProcessed.set'], 'filepath', outputFolder);

%% Debugging Step 3: Re-referencing Data (Optional)
% You can apply re-referencing to average reference or specific channels
EEG = pop_reref(EEG, []);  % Re-reference to the average of all channels (can specify specific channels)

% Save the re-referenced data
EEG = pop_saveset(EEG, 'filename', [baseName, '_re-referenced.set'], 'filepath', outputFolder);

%% Debugging Step 4: Filtering (Adjust if needed)
% Apply a high-pass filter (e.g., 1Hz) or band-pass filter as needed
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 1);  % High-pass filter at 1Hz

% Alternatively, you can use a band-pass filter between 0.5Hz and 60Hz
% EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 60, 'plotfreqz', 1);  % Band-pass filter

% Save the filtered data
EEG = pop_saveset(EEG, 'filename', [baseName, '_filtered.set'], 'filepath', outputFolder);

%% Debugging Step 5: Visualize EEG Data
% You can visualize the EEG data after each step
pop_eegplot(EEG, 1, 1, 1);  % Open EEG plot to visually inspect the data

%% Final Save of Processed Data
% Save the final dataset after all preprocessing steps
EEG = pop_saveset(EEG, 'filename', [baseName, '_final.set'], 'filepath', outputFolder);
fprintf('Processed and saved: %s\n', baseName);

