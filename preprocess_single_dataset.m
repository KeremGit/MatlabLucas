
function preprocess_single_dataset(inputFile, savePath, doSave)

if nargin < 3
    doSave = false;
end

fileConfig =  config();
capPath = fileConfig.capPath;

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

    %pop_eegplot( EEG, 1, 1, 1);
    %figure; pop_spectopo(EEG, 1, [0      262257.8125], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 64],'electrodes','off');
end
%% Debugging Step 1: Zipline data removal
%
EEG = pop_zapline_plus(EEG, 'noisefreqs','line','coarseFreqDetectPowerDiff',3,'chunkLength',0,'adaptiveNremove',1,'fixedNremove',1,'plotResults',0);

EEG = pop_zapline_plus(EEG, 'noisefreqs',[],'coarseFreqDetectPowerDiff',3,'chunkLength',0,'adaptiveNremove',1,'fixedNremove',1,'plotResults',0);

% Save the cleaned EEG dataset
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_zipline.set'], 'filepath', savePath);

    %pop_eegplot( EEG, 1, 1, 1);
    %figure; pop_spectopo(EEG, 1, [0      262257.8125], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 64],'electrodes','off');
end

%% Debugging Step 2: Clean Raw Data - Settings need editing ie burst criterion off
% Clean EEG data to remove artifacts (you can tweak the parameters)

num_channels_before = length(EEG.chanlocs);

EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidean');

num_channels_after = length(EEG.chanlocs);

if (num_channels_before ~= num_channels_after)
    EEG = pop_interp(EEG, ALLEEG(1).chanlocs, 'spherical');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','test_interpol','gui','off');
end
%% Need an if statement her to check if step 2 removed a channel

% leading to this code if yes - missing channels need to be interpolated
% else outlier checks for microstates will break due to uneven numbers of
% channels

% EEG = pop_interp(EEG, ALLEEG(1).chanlocs, 'spherical'
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','test_interpol','gui','off');

% On a side note i beleive we need to add the ALLEEG EEG CURRENTSET
% function to all steps outside of the if dosave component in order for the function to function properly
% it will probably break a few things

% the value ALLEEG(1) in the above function refers to the dataset that has
% just undergone CRD, i am uncertian if it will break when iterating

%%
EEG = pop_reref(EEG, []);  % Re-reference to the average of all channels (can specify specific channels)
EEG = pop_saveset(EEG, 'filename', [baseName, '_CRD.set'], 'filepath', savePath);

%figure; pop_spectopo(EEG, 1, [0      262257.8125], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 64],'electrodes','off');

%% Moved the first high pass 1 Hz filter here

% Apply a high-pass filter (e.g., 1Hz) or band-pass filter as needed
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 1);  % High-pass filter at 1Hz

% Save the cleaned EEG dataset
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_cleaned.set'], 'filepath', savePath);

end
%% Debugging Step 3: ICA for Artifact Removal
% Run ICA on the cleaned data (you can change the number of components or settings)
numChannels = size(EEG.data, 1);  % Number of channels in the dataset
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'rndreset', 'yes', ...
    'interrupt', 'on', 'pca', numChannels);

% Label ICA components
EEG = pop_iclabel(EEG, 'default');  % Label components based on predefined categories

% Save the ICA dataset
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_ICA.set'], 'filepath', savePath);

    %pop_eegplot( EEG, 0, 1, 1);
    %figure; pop_spectopo(EEG, 0, [0      262257.8125], 'EEG' , 'freq', [10], 'plotchan', 0, 'percent', 20, 'icacomps', [1:numChannels], 'nicamaps', 5, 'freqrange',[2 64],'electrodes','off');

end

%% Blink ERP Extraction Component
% Automatically assign vEOG IC based on ICLabel results

% Process blink events and epochs
processEEGWithBlinks(EEG, ALLEEG, CURRENTSET, baseName, savePath, doSave);

%% Back to Pre Blink ERP Extraction
% Flag artifacts (use pop_icflag for automatic removal)
EEG = pop_icflag(EEG, [NaN NaN; 0.90 1; 0.90 1; NaN NaN; 0.90 1; NaN NaN; NaN NaN]);

% Save the ICA dataset
EEG = pop_saveset(EEG, 'filename', [baseName, '_ICA.set'], 'filepath', savePath);

%pop_eegplot( EEG, 1, 1, 1);
%figure; pop_spectopo(EEG, 1, [0      262257.8125], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 64],'electrodes','off');

%pop_eegplot( EEG, 0, 1, 1);
%figure; pop_spectopo(EEG, 0, [0      262257.8125], 'EEG' , 'freq', [10], 'plotchan', 0, 'percent', 20, 'icacomps', [1:numChannels], 'nicamaps', 5, 'freqrange',[2 64],'electrodes','off');

% Import EEG CRD data then apply ica weights
EEG_CRD = pop_loadset('filename', [baseName '_CRD.set'], 'filepath', savePath);
EEG_CRD = pop_editset(EEG_CRD, 'icaweights', EEG.icaweights, 'icasphere', EEG.icasphere, 'icachansind', EEG.icachansind);

processEEG_ICARemoval(EEG_CRD, baseName, savePath, doSave, '');

end