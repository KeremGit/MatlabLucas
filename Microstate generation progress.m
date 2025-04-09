% Import all dtata sets from group control or group microstates

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename',{'v10p_final.set','v12p_final.set','v14p_final.set','v15p_final.set','v173_final.set','v177_final.set','v179_final.set','v181_final.set','v183_final.set'},'filepath','/MATLAB Drive/MatlabLucas/files/Preprocessing Data Sets 2/Processed ADHD/');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 9,'retrieve',1,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',2,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',3,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'retrieve',4,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'retrieve',4,'study',0); 

% Below only exists because of the issue regarding varying numbers of
% channels that should be solved with the interpolate electordes function
% in preprocess single dataset

ALLEEG = pop_delset( ALLEEG, [4] );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'retrieve',5,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'retrieve',6,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'retrieve',7,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'retrieve',8,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'retrieve',9,'study',0); 
ALLEEG = pop_delset( ALLEEG, [9] );
%% Create two seperate studies - one for ADHD sets and one for Control



%% Generate microstates across all imported data sets within studies from 4 - 7 possible maps

[EEG, CURRENTSET] = pop_FindMSMaps(ALLEEG, [1 2 3 5 6 7 8], 'ClustPar', struct('GFPPeaks',1,'IgnorePolarity',1,'MaxClasses',7,'MaxMaps',Inf,'MinClasses',4,'Normalize',1,'Restarts',20,'UseAAHC',0));
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:3 5 6:8] ,'study',0); 


%% Generate grand mean microstates for both control and ADHD seperatly and save

EEG = pop_CombMSMaps(ALLEEG, [1 2 3 5 6 7 8], 'MeanName', 'Mean_<name>', 'IgnorePolarity', 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:3 5 6:8] ,'setname','Mean_test','gui','off'); 

%% Order Grand Mean microstates by variance (or in accordance to Maps in existing research?)

[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, 4, 'TemplateSet', 'manual', 'Classes', 7, 'SortOrder', [1 2 3 4 5 6 7], 'NewLabels', {'A', 'B', 'C', 'D', 'E', 'F', 'G'});
[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, 4, 'TemplateSet', 'own', 'TemplateClasses', 7, 'IgnorePolarity', 1, 'Stepwise', 1);

%% Order individual Microstate maps by variance in accordance to Grand Mean Maps

[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, [1 2 3 5 6 7 8], 'TemplateSet', 4, 'IgnorePolarity', 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','Mean_test_sorted','gui','off'); 
[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, [1 2 3 5 6 7 8], 'TemplateSet', 9, 'IgnorePolarity', 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:3 5 6:8] ,'study',0); 


%% Data Quality Check and Outlier detection
[EEG CURRENTSET] = pop_DetectOutliers(ALLEEG, [1 2 3 5 6 7 8], 'Classes', 7);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:3 5 6:8] ,'study',0); 

% Need to work out how to automate the exclusion and deletion at p < .05
% Repeat for classes 4 - 7

setsTable = pop_CheckData(ALLEEG, [1 2 3 5 6 7 8])

% Same issue with auto exclude


%% Backfitting Grand Mean Templates onto individual data sets

[EEG, CURRENTSET] = pop_FitMSMaps(ALLEEG, [1 2 3 5 6 7 8], 'FitPar', struct('Classes',6,'PeakFit',1), 'TemplateSet', 9);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:3 5 6:8] ,'study',0); 

%% Move on to data analysis and comparisons 
