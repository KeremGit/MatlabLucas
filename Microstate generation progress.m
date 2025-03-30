% Load EEGLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Load your EEG datasets for Controls and ADHD
EEG_Controls = pop_loadset('filename', 'controls.set', 'filepath', 'path_to_your_data');
EEG_ADHD = pop_loadset('filename', 'adhd.set', 'filepath', 'path_to_your_data');

% Preprocess the data (example: bandpass filter)
EEG_Controls = pop_eegfiltnew(EEG_Controls, 1, 30);
EEG_ADHD = pop_eegfiltnew(EEG_ADHD, 1, 30);

% Run microstate analysis for Controls
EEG_Controls = pop_micro_selectdata(EEG_Controls, 'datatype', 'spontaneous');
EEG_Controls = pop_micro_segment(EEG_Controls, 'algorithm', 'modkmeans', 'Nmicrostates', 4);

% Run microstate analysis for ADHD
EEG_ADHD = pop_micro_selectdata(EEG_ADHD, 'datatype', 'spontaneous');
EEG_ADHD = pop_micro_segment(EEG_ADHD, 'algorithm', 'modkmeans', 'Nmicrostates', 4);

% Save the results
pop_saveset(EEG_Controls, 'filename', 'controls_microstates.set', 'filepath', 'path_to_save');
pop_saveset(EEG_ADHD, 'filename', 'adhd_microstates.set', 'filepath', 'path_to_save');

%% Personally im about 50% lost


[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename',{'ADHDP3.set','ADHDP3_CRD.set','ADHDP3_CRD_REREF.set','ADHDP3_CRD_REREF_WICA.set','ADHDP3_CRD_REREF_HPASS.set','ADHDP3_CRD_REREF_HPASS_WICA.set','ADHDP3_CRD_REREF pruned with ICA.set','untitled.set'},'filepath','/MATLAB Drive/Preprocessing Data Sets 2/');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'study',0); 
setsTable = pop_CheckData(ALLEEG, [1 2 3 4 5 6 7 8])
[EEG, CURRENTSET] = pop_FindMSMaps(ALLEEG, 8, 'ClustPar', struct('GFPPeaks',1,'IgnorePolarity',1,'MaxClasses',7,'MaxMaps',Inf,'MinClasses',4,'Normalize',1,'Restarts',20,'UseAAHC',0));
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'setname','ADHDP3 with initial microstates','gui','off'); 
[EEG, CURRENTSET] = pop_FindMSMaps(ALLEEG, 7, 'ClustPar', struct('GFPPeaks',1,'IgnorePolarity',1,'MaxClasses',7,'MaxMaps',Inf,'MinClasses',4,'Normalize',1,'Restarts',20,'UseAAHC',0));
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'setname','ADHDP3_CRD_REREF pruned with ICA microstates','gui','off'); 
EEG = pop_CombMSMaps(ALLEEG, [9 10], 'MeanName', 'Mean_<name>', 'IgnorePolarity', 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 10,'setname','Mean_Maps','gui','off'); 
fig_h = pop_ShowIndMSMaps(ALLEEG, 11, 'Classes', [4 5 6 7], 'Visible', 1);
[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, 11, 'TemplateSet', 'manual', 'Classes', 6, 'SortOrder', [1 2 3 4 5 6], 'NewLabels', {'A', 'B', 'C', 'D', 'E', 'F'});
[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, 11, 'TemplateSet', 'manual', 'Classes', 5, 'SortOrder', [1 2 3 4 5], 'NewLabels', {'A', 'B', 'C', 'D', 'E'});
[ALLEEG, EEG, CURRENTSET] = pop_SortMSMaps(ALLEEG, [9 10], 'TemplateSet', 11, 'Classes', [5 6], 'IgnorePolarity', 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 11,'setname','Mean_Maps_sorted','gui','off'); 
sharedVarTable = pop_CompareMSMaps(ALLEEG, [], [], [], 'Classes', 6, 'gui', 1);
[EEG CURRENTSET] = pop_DetectOutliers(ALLEEG, [9 10], 'Classes', 5);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [9 10] ,'study',0); 
[EEG, CURRENTSET] = pop_FitMSMaps(ALLEEG, 8, 'FitPar', struct('Classes',5,'PeakFit',1), 'TemplateSet', 12);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'setname','ADHDP3_Backfitted','gui','off'); 