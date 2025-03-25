function [EEG, ALLEEG, CURRENTSET] = processEEGWithBlinks(EEG, ALLEEG, CURRENTSET)
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

%% --- Part 1: Select ICs ---
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
if nargin >= 3
    [ALLEEG, EEG, CURRENTSET] = bemobil_filter(ALLEEG, EEG, CURRENTSET, 0.1, 40);
else
    EEG = bemobil_filter([], EEG, [], 0.1, 40); % if no ALLEEG provided
end
EEG = eeg_checkset(EEG);

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

end
