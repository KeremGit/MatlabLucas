%% EEG Preprocessing Pipeline

% Define file paths
basePath = '/MATLAB Drive/EEG Datasets/ADHD_part1/';
capPath = '/MATLAB Drive/EEG Datasets/Standard-10-20-Cap19new/';
savePath = '/MATLAB Drive/Preprocessing Data Sets 2/';
inputFile = fullfile(basePath, 'v3p.mat');
capFile = fullfile(capPath, 'Standard-10-20-Cap19new.ced');

% Initialize EEGLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Import EEG data
EEG = pop_importdata('dataformat', 'matlab', 'nbchan', 0, 'data', inputFile, ...
    'setname', 'ADHDP3', 'srate', 128, 'subject', 'ADHD3', 'pnts', 0, ...
    'xmin', 0, 'group', 'EXP', 'chanlocs', capFile);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');

% Save raw EEG dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

% Plot EEG data for visual inspection
pop_eegplot(EEG, 1, 1, 1);

%% Clean EEG data
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 20, ...
    'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian');

% Save cleaned dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3_CRD.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', 'ADHDP3_CRD', 'gui', 'off');

%% Re-referencing
EEG = pop_reref(EEG, []);

% Save re-referenced dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3_CRD_REREF.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', 'ADHDP3_CRD_REREF', 'gui', 'off');

%% High-pass filtering (1 Hz)
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 1);

% Save high-pass filtered dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3_CRD_REREF_HPASS.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname', 'ADHDP3_CRD_REREF_HPASS', 'gui', 'off');

%% Independent Component Analysis (ICA)
numChannels = size(EEG.data, 1); % Dynamically get the number of channels
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'rndreset', 'yes', 'interrupt', 'on', 'pca', numChannels);

% Save ICA dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3_CRD_REREF_HPASS_WICA.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% Apply ICA weights to dataset
EEG = pop_editset(EEG, 'icaweights', ALLEEG(4).icaweights, 'icasphere', ALLEEG(4).icasphere, 'icachansind', ALLEEG(4).icachansind);

% Save ICA-applied dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3_CRD_REREF_WICA.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

% Select ICA components for visualization
pop_selectcomps(EEG, 1:numChannels);

eeglab redraw;

%% ICA Component Labeling and Pruning
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag(EEG, [NaN NaN; 0.95 1; 0.95 1; NaN NaN; 0.95 1; NaN NaN; NaN NaN]);

% Remove identified artifact components
EEG = pop_subcomp(EEG, [], 0);

% Save ICA-pruned dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3_CRD_REREF_pruned_ICA.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 5, 'gui', 'off');

%% Final Filtering (0.5 Hz - 60 Hz)
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 60, 'plotfreqz', 1);

% Save final preprocessed dataset
EEG = pop_saveset(EEG, 'filename', 'ADHDP3_CRD_REREF_pruned_ICA_Refiltered.set', 'filepath', savePath);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 6, 'setname', 'Final Preprocessed Dataset', 'gui', 'off');

% Final visualization
pop_eegplot(EEG, 1, 1, 1);

% End of Preprocessing