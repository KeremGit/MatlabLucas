function EEG = processEEG_ICARemoval(EEG, baseName, savePath, doSave, tag)
% preprocessEEG - Applies ICA component removal, re-referencing, filtering, and saves the dataset
%
% Inputs:
%   EEG      - EEGLAB EEG structure
%   baseName - Base filename for saving
%   savePath - Directory where files will be saved
%   doSave   - Boolean flag to save at each step
%   tag      - Optional tag for file naming (e.g., 'blink', 'muscle')

if nargin < 5
    tag = '';
elseif ~isempty(tag)
    tag = [tag '-'];  % add hyphen only if tag is not empty
end

% Step 1: Flag & remove components
EEG = pop_icflag(EEG, [NaN NaN; 0.95 1; 0.95 1; NaN NaN; 0.95 1; NaN NaN; NaN NaN]);
EEG = pop_subcomp(EEG, [], 0);
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_', tag, 'pruned.set'], 'filepath', savePath);
end

% Step 2: Re-reference to average
EEG = pop_reref(EEG, []);
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_', tag, 're-referenced.set'], 'filepath', savePath);
end

% Step 3: Band-pass filter (0.5 - 60 Hz)
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 60, 'plotfreqz', 1);
if doSave
    EEG = pop_saveset(EEG, 'filename', [baseName, '_', tag, 'filtered.set'], 'filepath', savePath);
end

% Final save
EEG = pop_saveset(EEG, 'filename', [baseName, '_', tag, 'final.set'], 'filepath', savePath);
fprintf('Processed and saved: %s_%sfinal.set\n', baseName, tag);
end
