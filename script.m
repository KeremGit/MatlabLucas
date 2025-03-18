
% Run this? need to do it again but it might save properly now?
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_importdata('dataformat','matlab','nbchan',0,'data','/MATLAB Drive/EEG Datasets/ADHD_part1/v3p.mat','setname','ADHDP3','srate',128,'subject','ADHD3','pnts',0,'xmin',0,'group','EXP','chanlocs','/MATLAB Drive/EEG Datasets/Standard-10-20-Cap19new/Standard-10-20-Cap19new.ced');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
EEG = pop_saveset( EEG, 'filename','ADHDP3.set','filepath','/MATLAB Drive/Preprocessing Data Sets 2/');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

pop_eegplot( EEG, 1, 1, 1); % This is just a visual aid for data quality inspection that will be removed in the final version. I believe this is true for all the eegplot commands

EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian'); % This command will remove a number of data channels (it starts with 19) based on data quality. many of the later commands use the number of remaining channels + 1 (the averaged re-reference)
% and the code will break if this value is incorrect

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','ADHDP3_CRD','savenew','/MATLAB Drive/Preprocessing Data Sets 2/ADHDP3_CRD.set','gui','off'); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',2,'study',0); 
EEG = pop_reref( EEG, []);

% The next step (Independent Component Analysis) will generate weights that
% will be applied to the data set that was just saved

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','ADHDP3_CRD_REREF','savenew','/MATLAB Drive/Preprocessing Data Sets 2/ADHDP3_CRD_REREF.set','gui','off'); 
EEG = pop_eegfiltnew(EEG, 'locutoff',1,'plotfreqz',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname','ADHDP3_CRD_REREF_HPASS','savenew','/MATLAB Drive/Preprocessing Data Sets 2/ADHDP3_CRD_REREF_HPASS.set','gui','off'); 
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on','pca',19);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'retrieve',3,'study',0); 
EEG = pop_saveset( EEG, 'filename','ADHDP3_CRD_REREF_HPASS_WICA.set','filepath','/MATLAB Drive/Preprocessing Data Sets 2/');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'retrieve',4,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'retrieve',3,'study',0); 
EEG = pop_loadset('filename','ADHDP3_CRD_REREF_HPASS_WICA.set','filepath','/MATLAB Drive/Preprocessing Data Sets 2/');

[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
ALLEEG = pop_delset( ALLEEG, [5] ); % I think this is an error, not sure it should be in here
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',4,'study',0); 
EEG = pop_saveset( EEG, 'filename','ADHDP3_CRD_REREF_HPASS_WICA.set','filepath','/MATLAB Drive/Preprocessing Data Sets 2/');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
[ALLEEG EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'retrieve',3,'study',0); 
EEG = pop_editset(EEG, 'icaweights', 'ALLEEG(4).icaweights', 'icasphere', 'ALLEEG(4).icasphere', 'icachansind', 'ALLEEG(4).icachansind');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_saveset( EEG, 'filename','ADHDP3_CRD_REREF_WICA.set','filepath','/MATLAB Drive/Preprocessing Data Sets 2/');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
pop_selectcomps(EEG, [1:19] );

% There is an odd interaction with the GUI where it doesnt seem to load the
% data sets in properly until i manually load one in, its just a minor
% inconvienience


% After that move on to generating microstates

% Currently also replaced the Reref Version without ICA, is that a problem?

% Including code below labels and prunes with ICA at 95% confidence
% flagging as artifacts



[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'retrieve',3,'study',0); 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'retrieve',5,'study',0); 
EEG = pop_iclabel(EEG, 'default');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_icflag(EEG, [NaN NaN;0.95 1;0.95 1;NaN NaN;0.95 1;NaN NaN;NaN NaN]);

% Am currently attempting to sort a problem for another part of my project
% that should go before the ICA pruning process. It involves identifying
% the power peaks in the components identifed as blink muscle movement as a temporal location and
% extracting them (probably to excel) turning them into a range value of 50
% ms before and 100 ms after, importing the value back into eeglab and
% using them to select epocs to generate a new data set that is just the
% blink epocs. This will be followed by additional processing but will
% likely be part of a seperate pipeline.

[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_subcomp( EEG, [], 0);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'savenew','/MATLAB Drive/Preprocessing Data Sets 2/ADHDP3_CRD_REREF pruned with ICA.set','gui','off');

% Probably Re-reference by average after ICA pruning?

% Added Extra filter at 0.5Hz 60 hz, is it nessasary? no clue. looks like
% gamma processes (up to 40-80hz range) are implicated in higher order
% processes like attention and motor control, so unless i can put a high
% pass in at over 80 i probably shouldnt and also trust the ICA to remove
% electrical noise or put a band pass in at the electrical section.

EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',60,'plotfreqz',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'setname','ADHDP3_CRD_REREF pruned with ICA Refiltered.5_60','savenew','/MATLAB Drive/Preprocessing Data Sets 2/untitled.set','gui','off'); 
pop_eegplot( EEG, 1, 1, 1);

% I think this is the end of the preprocessing and the final file should be
% saved here    