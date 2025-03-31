function processEEGWithBlinks(EEG, ALLEEG, CURRENTSET, baseName)
% processEEGWithBlinks - Detects blinks from vEOG IC, creates blink events, filters,
% and epochs EEG data based on specific stimulus markers.
%
% Inputs:
%   EEG         - EEG dataset with ICA and ICs4events already defined
%   ALLEEG      - Optional, ALLEEG structure for EEGLAB compatibility
%   CURRENTSET  - Optional, CURRENTSET index for EEGLAB
%
% Outputs:
%   EEG, ALLEEG, CURRENTSET - Updated EEG structures

basePath = './files/ADHD/';  % Change to your dataset's directory
capPath = './files/Standard-10-20-Cap19new/Standard-10-20-Cap19new.ced';  % Your electrode layout
savePath = './files/Preprocessing Data Sets 2/';  % Output directory for processed data

outputFolder = fullfile(savePath, 'Processed Single Dataset');
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end

%% --- Part 1: Select ICs ---
EEG.icaact = (EEG.icaweights * EEG.icasphere) * EEG.data(EEG.icachansind, :);
vEOG_IC = EEG.etc.ICs4events.vEOG;
abs_vEOG = abs(EEG.icaact(vEOG_IC, :));

% Apply 20-point moving median filter
smooth_vEOG = smoothdata(abs_vEOG, 'movmedian', 20);

%% --- Part 2: Blink Detection ---
MinPeakDistance = 25;
MinPeakProminence = double(prctile(smooth_vEOG, 90));
thresholdBlinks   = double(prctile(smooth_vEOG, 85));
MinPeakWidth      = 5;
MaxPeakWidth      = 80;

[blinkPks, blinkLocs] = findpeaks(smooth_vEOG, ...
    'MinPeakProminence', MinPeakProminence, ...
    'MinPeakDistance',  MinPeakDistance, ...
    'MinPeakHeight',    thresholdBlinks, ...
    'MinPeakWidth',     MinPeakWidth, ...
    'MaxPeakWidth',     MaxPeakWidth);

%% --- Part 3: Event Creation ---
for latency = blinkLocs
    i = numel(EEG.event) + 1;
    EEG.event(i).type = 'blink';
    EEG.event(i).latency = latency;
    EEG.event(i).duration = 1 / EEG.srate;
end
EEG = eeg_checkset(EEG, 'eventconsistency');

%% --- Part 4: Epoching ---
% Bandpass filter (0.1–40 Hz)
% if nargin >= 3
  %  [ALLEEG, EEG, CURRENTSET] = bemobil_filter(ALLEEG, EEG, CURRENTSET, 0.1, 40);
%else
 %   EEG = bemobil_filter([], EEG, [], 0.1, 40); % if no ALLEEG provided
%end
%EEG = eeg_checkset(EEG);

% Find 'Stim-60' and 'Stim-40' events
epoch_events = {};
count = 1;
for eventIdx = 1:length(EEG.event)
    if startsWith(EEG.event(eventIdx).type, 'Stim-60') || ...
            startsWith(EEG.event(eventIdx).type, 'Stim-40')
        epoch_events{count} = EEG.event(eventIdx).type;
        count = count + 1;
    end
end

% Epoch the data
EEG = pop_epoch(EEG, epoch_events, [-0.6 1.4], ...
    'newname', 'Stimulus ERP', 'epochinfo', 'yes');

if nargin >= 3
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'overwrite', 'on', 'gui', 'off');
end
EEG = eeg_checkset(EEG);

% Baseline correction (-500 to 0 ms)
EEG = pop_rmbase(EEG, [-500 0]);

EEG = pop_saveset(EEG, 'filename', [baseName, '_blinkProcessed.set'], 'filepath', outputFolder);

% Everything before here needs to before the dataset has been pruned with
% the ICA but the final preprocessing steps will need to happen after and
% then saved

EEG = pop_icflag(EEG, [NaN NaN; 0.95 1; 0.95 1; NaN NaN; 0.95 1; NaN NaN; NaN NaN]);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_subcomp( EEG, [], 0);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'savenew','/MATLAB Drive/Preprocessing Data Sets 2/ADHDP3_CRD_REREF pruned with ICA.set','gui','off');

%% Debugging Step 3: Re-referencing Data again to average
% You can apply re-referencing to average reference or specific channels
EEG = pop_reref(EEG, []);  % Re-reference to the average of all channels (can specify specific channels)

% Save the re-referenced data
EEG = pop_saveset(EEG, 'filename', [baseName, '_re-referenced.set'], 'filepath', outputFolder);

%% Debugging Step 4: Filtering (Adjust if needed)

% Alternatively, you can use a band-pass filter between 0.5Hz and 60Hz -
% yeah we want this one
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 60, 'plotfreqz', 1);  % Band-pass filter

% Save the filtered data
EEG = pop_saveset(EEG, 'filename', [baseName, '_filtered.set'], 'filepath', outputFolder);

%% Debugging Step 5: Visualize EEG Data
% You can visualize the EEG data after each step
pop_eegplot(EEG, 1, 1, 1);  % Open EEG plot to visually inspect the data

%% Final Save of Processed Data
% Save the final dataset after all preprocessing steps
EEG = pop_saveset(EEG, 'filename', [baseName, '_final.set'], 'filepath', outputFolder);
fprintf('Processed and saved: %s\n', baseName);

end
