function EEG = select_vEOG_IC(EEG, threshold)
% select_vEOG_IC - Automatically selects the vertical EOG IC based on ICLabel scores.
%
% Inputs:
%   EEG       - EEG dataset that has already gone through ICA and ICLabel
%   threshold - (Optional) Minimum probability to accept a component as vEOG (default = 0.9)
%
% Output:
%   EEG with EEG.etc.ICs4events.vEOG set to the best matching IC

if nargin < 2
    threshold = 0.9;
end

% Check for ICLabel results
if ~isfield(EEG.etc, 'ic_classification') || ...
        ~isfield(EEG.etc.ic_classification, 'ICLabel') || ...
        isempty(EEG.etc.ic_classification.ICLabel.classifications)
    error('ICLabel classifications not found in EEG structure.');
end

% Get ICLabel classifications
labels = EEG.etc.ic_classification.ICLabel.classifications;
eyeProbs = labels(:, 3);  % Column 3 corresponds to "Eye"

% Find component(s) with high Eye probability
[~, bestIC] = max(eyeProbs);  % Best IC based on highest eye probability
if eyeProbs(bestIC) < threshold
    warning('No IC met the threshold %.2f for Eye classification. Using best available: IC %d (Eye prob = %.2f)', ...
        threshold, bestIC, eyeProbs(bestIC));
end

% Assign best IC as vEOG
EEG.etc.ICs4events.vEOG = bestIC;
fprintf('Selected IC %d as vEOG (Eye prob = %.2f)\n', bestIC, eyeProbs(bestIC));

end
