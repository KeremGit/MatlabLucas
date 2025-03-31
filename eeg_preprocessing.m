%% EEG Preprocessing Pipeline for Control and Experimental Datasets

cfg = config();

capPath = cfg.capPath;
savePath = cfg.savePath;

controlFolder = fullfile(savePath, 'Processed Control');
experimentalFolder = fullfile(savePath, 'Processed Experimental');

% Ensure save directories exist
if ~exist(controlFolder, 'dir'), mkdir(controlFolder); end
if ~exist(experimentalFolder, 'dir'), mkdir(experimentalFolder); end

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

% --- Process Control Group ---
processGroup(cfg.basePathControl, controlFolder, capPath, 'Control');

% --- Process Experimental Group ---
processGroup(cfg.basePath, experimentalFolder, capPath, 'Experimental');



%% Sub-function: Process each group
function processGroup(basePath, saveFolder, capPath, groupName)
files = dir(fullfile(basePath, '*.mat'));

for fileIdx = 1:length(files)
    inputFile = fullfile(basePath, files(fileIdx).name);
    [~, baseName, ~] = fileparts(files(fileIdx).name);

    % Import EEG data
    EEG = pop_importdata('dataformat', 'matlab', 'nbchan', 0, 'data', inputFile, ...
        'setname', baseName, 'srate', 128, 'subject', baseName, 'pnts', 0, ...
        'xmin', 0, 'group', groupName, 'chanlocs', capPath);

    % Save raw EEG dataset
    EEG = pop_saveset(EEG, 'filename', [baseName, '_raw.set'], 'filepath', saveFolder);

    % Clean EEG data
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
        'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 20, ...
        'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian');

    % Re-referencing
    EEG = pop_reref(EEG, []);

    % High-pass filtering
    EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 1);

    % Run ICA
    numChannels = size(EEG.data, 1);
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, ...
        'rndreset', 'yes', 'interrupt', 'on', 'pca', numChannels);

    % Label and flag ICA components
    EEG = pop_iclabel(EEG, 'default');
    EEG = pop_icflag(EEG, [NaN NaN;0.95 1;0.95 1;NaN NaN;0.95 1;NaN NaN;NaN NaN]);

    % Save final dataset
    EEG = pop_saveset(EEG, 'filename', [baseName, '_Final.set'], 'filepath', saveFolder);

    fprintf('[%s] Processed and saved: %s\n', groupName, baseName);
end
end
