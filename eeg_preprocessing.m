%% EEG Preprocessing Pipeline for Control and Experimental Datasets

cfg = config();

savePath = cfg.savePath;

controlFolder = fullfile(savePath, 'Processed Control');
experimentalFolder = fullfile(savePath, 'Processed Experimental');

% Ensure save directories exist
if ~exist(controlFolder, 'dir'), mkdir(controlFolder); end
if ~exist(experimentalFolder, 'dir'), mkdir(experimentalFolder); end

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

% --- Process Control Group ---
processGroup(cfg.basePathControl, controlFolder, 'Control');

% --- Process Experimental Group ---
processGroup(cfg.basePathADHD, experimentalFolder, 'Experimental');



%% Sub-function: Process each group
function processGroup(basePath)
files = dir(fullfile(basePath, '*.mat'));

for fileIdx = 1:length(files)
    inputFile = fullfile(basePath, files(fileIdx).name);
    preprocess_single_dataset(inputFile)

end
end
