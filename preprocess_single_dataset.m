
function preprocess_single_dataset(inputFile, doSave)

if nargin < 2
    doSave = false;
end

fileConfig =  config();
capPath = fileConfig.capPath;
savePath = fileConfig.savePath;

% Ensure save directory exists
if ~exist(savePath, 'dir'), mkdir(savePath); end

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');
inputFile = fullfile(inputFile);
[~, baseName, ~] = fileparts(inputFile);

% Import EEG data
EEG = pop_importdata('dataformat', 'matlab', 'nbchan', 0, 'data', inputFile, ...
    'setname', baseName, 'srate', 128, 'subject', baseName, 'pnts', 0, ...
    'xmin', 0, 'group', 'EXP', 'chanlocs', capPath);

% Save raw EEG dataset (save raw data for reference)
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_raw.set'], 'filepath', savePath);
end
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
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_cleaned.set'], 'filepath', savePath);
end
%% Debugging Step 2: ICA for Artifact Removal
% Run ICA on the cleaned data (you can change the number of components or settings)
numChannels = size(EEG.data, 1);  % Number of channels in the dataset
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'rndreset', 'yes', ...
    'interrupt', 'on', 'pca', numChannels);

% Label ICA components
EEG = pop_iclabel(EEG, 'default');  % Label components based on predefined categories

% Save the ICA dataset
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_ICA.set'], 'filepath', savePath);
end

%% Blink ERP Extraction Component
% Automatically assign vEOG IC based on ICLabel results

% Process blink events and epochs
processEEGWithBlinks(EEG, ALLEEG, CURRENTSET, baseName, doSave);

%% Back to Pre Blink ERP Extraction
% Flag artifacts (use pop_icflag for automatic removal)
EEG = pop_icflag(EEG, [NaN NaN; 0.95 1; 0.95 1; NaN NaN; 0.95 1; NaN NaN; NaN NaN]);

% Save the ICA dataset
EEG = pop_saveset(EEG, 'filename', [baseName, '_ICA.set'], 'filepath', savePath);


% Import EEG CRD data then apply ica weights
EEG_CRD = pop_loadset('filename', [baseName '_CRD.set'], 'filepath', savePath);
EEG_CRD = pop_editset(EEG_CRD, 'icaweights', EEG.icaweights, 'icasphere', EEG.icasphere, 'icachansind', EEG.icachansind);

processEEG_ICARemoval(EEG_CRD, baseName, savePath, doSave, '');

end