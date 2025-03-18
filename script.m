%% EEG Preprocessing Pipeline for Multiple Datasets

% Define file paths
basePaths = {'/files/ADHD_part1/', '/files/ADHD_part2/', ...
             '/files/Control_part1/', '/files/Control_part2/'};
capPath = '/files/Standard-10-20-Cap19new/';
savePath = '/files/Preprocessing Data Sets 2/';
controlFolder = fullfile(savePath, 'Processed Control');
experimentalFolder = fullfile(savePath, 'Processed Experimental');

% Ensure save directories exist
if ~exist(controlFolder, 'dir'), mkdir(controlFolder); end
if ~exist(experimentalFolder, 'dir'), mkdir(experimentalFolder); end

% Initialize EEGLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Process datasets from multiple folders
for dirIdx = 1:length(basePaths)
    basePath = basePaths{dirIdx};
    files = dir(fullfile(basePath, '*.mat'));
    
    for fileIdx = 1:length(files)
        inputFile = fullfile(basePath, files(fileIdx).name);
        [~, baseName, ~] = fileparts(files(fileIdx).name);
        
        % Import EEG data
        EEG = pop_importdata('dataformat', 'matlab', 'nbchan', 0, 'data', inputFile, ...
            'setname', baseName, 'srate', 128, 'subject', baseName, 'pnts', 0, ...
            'xmin', 0, 'group', 'EXP', 'chanlocs', capFile);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');
        
        % Save raw EEG dataset
        EEG = pop_saveset(EEG, 'filename', [baseName, '.set'], 'filepath', savePath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

        % Clean EEG data
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
            'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 20, ...
            'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian');

        % Save cleaned dataset
        EEG = pop_saveset(EEG, 'filename', [baseName, '_CRD.set'], 'filepath', savePath);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [baseName, '_CRD'], 'gui', 'off');

        % Re-referencing
        EEG = pop_reref(EEG, []);
        
        % Save re-referenced dataset
        EEG = pop_saveset(EEG, 'filename', [baseName, '_CRD_REREF.set'], 'filepath', savePath);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', [baseName, '_CRD_REREF'], 'gui', 'off');
        
        % High-pass filtering (1 Hz)
        EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 1);
        
        % Save high-pass filtered dataset
        EEG = pop_saveset(EEG, 'filename', [baseName, '_CRD_REREF_HPASS.set'], 'filepath', savePath);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname', [baseName, '_CRD_REREF_HPASS'], 'gui', 'off');
        
        % Independent Component Analysis (ICA)
        numChannels = size(EEG.data, 1);
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'rndreset', 'yes', 'interrupt', 'on', 'pca', numChannels);
        
        % Save ICA dataset
        EEG = pop_saveset(EEG, 'filename', [baseName, '_CRD_REREF_HPASS_WICA.set'], 'filepath', savePath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        % Apply ICA weights to dataset
        EEG = pop_editset(EEG, 'icaweights', ALLEEG(4).icaweights, 'icasphere', ALLEEG(4).icasphere, 'icachansind', ALLEEG(4).icachansind);
        
        % Save ICA-applied dataset
        EEG = pop_saveset(EEG, 'filename', [baseName, '_CRD_REREF_WICA.set'], 'filepath', savePath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        % Classify dataset as Control or Experimental
        if contains(basePath, 'Control', 'IgnoreCase', true)
            finalSavePath = controlFolder;
        else
            finalSavePath = experimentalFolder;
        end
        
        % Save final dataset in respective folder
        EEG = pop_saveset(EEG, 'filename', [baseName, '_Final.set'], 'filepath', finalSavePath);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        fprintf('Processed and saved: %s\n', baseName);
    end
end

eeglab redraw;

% End of Preprocessing
