
file_paths = config();

filePattern = fullfile(folderPath, '*_final.set');
ADHD_directory  = fullfile(file_paths.savePath, 'Processed ADHD');
Control_directory = fullfile(file_paths.savePath, 'Processed Control');

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% loops through every final ADHD file
for k = 1:length(dir(ADHD_directory))
    EEG = pop_loadset('filename', files(k).name, 'filepath', files(k).folder);
    % Add to ALLEEG
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, k - 1, 'study', 0);
end

%% Generate microstates across all imported data sets within studies from 4 - 7 possible maps
all_sets = 1:length(ALLEEG);

[EEG, CURRENTSET] = pop_FindMSMaps(ALLEEG, all_sets, 'ClustPar', struct('GFPPeaks',1,'IgnorePolarity',1,'MaxClasses',7,'MaxMaps',Inf,'MinClasses',4,'Normalize',1,'Restarts',20,'UseAAHC',0));
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, all_sets,'study',0);


%% Generate grand mean microstates for both control and ADHD seperatly and save

EEG = pop_CombMSMaps(ALLEEG, all_sets, 'MeanName', 'Mean_<name>', 'IgnorePolarity', 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, all_sets ,'setname','Mean_test','gui','off');
% EEG = pop_saveset(EEG,'filename','grand_mean_adhd.set','filepath', file_paths.microstate );


%% Order Grand Mean microstates by variance (or in accordance to Maps in existing research?)

grand_mean_set_index = length(ALLEEG);
% Confirm by debugging, but I'm pretty sure rather than checking the length we could be using CURRENTSET as the index. Confirm when CURRENTSET is increasing.
[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, grand_mean_set_index, 'TemplateSet', 'manual', 'Classes', 7, 'SortOrder', [1 2 3 4 5 6 7], 'NewLabels', {'A', 'B', 'C', 'D', 'E', 'F', 'G'});
[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, grand_mean_set_index, 'TemplateSet', 'own', 'TemplateClasses', 7, 'IgnorePolarity', 1, 'Stepwise', 1);

%% Order individual Microstate maps by variance in accordance to Grand Mean Maps

[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, all_sets, 'TemplateSet', grand_mean_set_index, 'IgnorePolarity', 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, all_sets ,'study',0);


%% Data Quality Check and Outlier detection
[EEG CURRENTSET] = pop_DetectOutliers(ALLEEG, all_sets, 'Classes', 7);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, all_sets ,'study',0);

% Need to work out how to automate the exclusion and deletion at p < .05
% Repeat for classes 4 - 7

setsTable = pop_CheckData(ALLEEG, all_sets);

% Same issue with auto exclude


%% Backfitting Grand Mean Templates onto individual data sets

[EEG, CURRENTSET] = pop_FitMSMaps(ALLEEG, all_sets, 'FitPar', struct('Classes',6,'PeakFit',1), 'TemplateSet', 9);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, all_sets ,'study',0);

%% Move on to data analysis and comparisons
