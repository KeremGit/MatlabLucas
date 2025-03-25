% Part 1 Select ICs

temp_vEOG = abs(EEG.icaact(EEG.etc.ICs4events.vEOG,:));

% 20 point median filter
% B = smoothdata(A,method,window) specifies the length of
% the window used by the smoothing method. For example,
% smoothdata(A,'movmedian',5) smooths the data in A by
% taking the median over a five-element sliding window.

smoothICvEOG = smoothdata(temp_vEOG,'movmedian',20);


% Part 2 Blink Detection

% blink detection using moving median and first derivative
% initialize and define all parameters for blink detection
blinkLocs = [];
blinkPks = [];
MinPeakDistance = 25;
MinPeakProminence = double(prctile(smoothICvEOG,90));
thresholdBlinks = double(prctile(smoothICvEOG,85));
MinPeakWidth = 5;
MaxPeakWidth = 80;

% find peaks in the smoothed vertical EOG
[blinkPks, blinkLocs] = findpeaks(smoothICvEOG, ...
    'MinPeakProminence', MinPeakProminence, ...
    'MinPeakDistance',  MinPeakDistance, ...
    'MinPeakHeight',    thresholdBlinks, ...
    'MinPeakWidth',     MinPeakWidth, ...
    'MaxPeakWidth',     MaxPeakWidth);


% Part 3 Event Creation

% create blink events
event_latencies = blinkLocs;

for latency = event_latencies
    i = numel(EEG.event) + 1;
    EEG.event(i).type = 'blink';
    EEG.event(i).latency = latency;
    EEG.event(i).duration = 1/EEG.srate;
end

EEG = eeg_checkset(EEG, 'eventconsistency');
event_latencies = [];



% Part 4 Epoching

% filter at 40 cut off
[ALLEEG, EEG, CURRENTSET] = bemobil_filter(ALLEEG, EEG, CURRENTSET, 0.1, 40);
EEG = eeg_checkset(EEG);

count = 1;
epoch_events = [];

for eventIdx = 1:length(EEG.event)
    if startsWith(EEG.event(eventIdx).type, 'Stim-60') == 1 || ...
            startsWith(EEG.event(eventIdx).type, 'Stim-40') == 1
        epoch_events{count} = EEG.event(eventIdx).type;
        count = count + 1;
    end
end


% cut data in epochs
EEG = pop_epoch(EEG, epoch_events, [-0.6 1.4], ...
    'newname', 'Stimulus ERP', 'epochinfo', 'yes');

[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1, ...
    'overwrite', 'on', 'gui', 'off');
EEG = eeg_checkset(EEG);

% define baseline period
EEG = pop_rmbase(EEG, [-500 0]);
