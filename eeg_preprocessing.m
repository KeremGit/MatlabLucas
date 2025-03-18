%% EEG Preprocessing Pipeline for Multiple Datasets

% Define file paths
basePaths = {'./files/ADHD/', './files/Control/'};
capPath = './files/Standard-10-20-Cap19new/Standard-10-20-Cap19new.ced';
savePath = './files/Preprocessing Data Sets 2/';
controlFolder = fullfile(savePath, 'Processed Control');
experimentalFolder = fullfile(savePath, 'Processed Experimental');

% Ensure save directories exist
if ~exist(controlFolder, 'dir'), mkdir(controlFolder); end
if ~exist(experimentalFolder, 'dir'), mkdir(experimentalFolder); end

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

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
            'xmin', 0, 'group', 'EXP', 'chanlocs', capPath);
        
        % Save raw EEG dataset (save raw data)
        EEG = pop_saveset(EEG, 'filename', [baseName, '_raw.set'], 'filepath', savePath);

        % Clean EEG data
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
            'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 20, ...
            'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian');
        
        % Re-referencing
        EEG = pop_reref(EEG, []);
        
        % High-pass filtering (1 Hz)
        EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 1);
        % EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 60, 'plotfreqz', 1);
        
        % Independent Component Analysis (ICA)
        numChannels = size(EEG.data, 1);
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'rndreset', 'yes', 'interrupt', 'on', 'pca', numChannels);
        
        % Label and flag ICA components
        EEG = pop_iclabel(EEG, 'default');
        EEG = pop_icflag(EEG, [NaN NaN;0.95 1;0.95 1;NaN NaN;0.95 1;NaN NaN;NaN NaN]);

        % Save ICA dataset
        if contains(basePath, 'Control', 'IgnoreCase', true)
            finalSavePath = controlFolder;
        else
            finalSavePath = experimentalFolder;
        end
        EEG = pop_saveset(EEG, 'filename', [baseName, '_Final.set'], 'filepath', finalSavePath);
        
        fprintf('Processed and saved: %s\n', baseName);
    end
end
