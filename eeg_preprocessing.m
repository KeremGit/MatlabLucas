%% EEG Preprocessing Pipeline for Control and Experimental Datasets

cfg = config();

savePath = cfg.savePath;

controlFolder = fullfile(savePath, 'Processed Control');
experimentalFolder = fullfile(savePath, 'Processed ADHD');

% Ensure save directories exist
if ~exist(controlFolder, 'dir'), mkdir(controlFolder); end
if ~exist(experimentalFolder, 'dir'), mkdir(experimentalFolder); end

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

% --- Process Experimental Group ---
processGroup(cfg.basePathADHD, experimentalFolder);


% --- Process Control Group ---
processGroup(cfg.basePathControl, controlFolder);


%% Sub-function: Process each group
function processGroup(basePath, savePath)
files = dir(fullfile(basePath, '*.mat'));

for fileIdx = 1:length(files)
    inputFile = fullfile(basePath, files(fileIdx).name);
    preprocess_single_dataset(inputFile, savePath, true) 

end
end
