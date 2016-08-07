function EEG = eeg_selectiveinterp(EEG,varargin)
% EEG = eeg_selectiveinterp(EEG,rej)
% EEG = eeg_selectiveinterp(EEG,elec, trials, ...)
%
% Perform a selective interpolation of certain electrodes on certain trials only.
% EEG is an epoched eeglab structure.
%
% Input methods: if only two inputs:
% rej should be a vector structure with fields 
%           - name: containing name or number of the electrodes to work with
%           - trials: bad epochs, on which the interpolation should be
%           performed.
% ex:  
% rej(1).name = 'F1';
% rej(1).trials = [35:51 105 152:166];
% rej(2).name = 22;
% rej(2).trials = [1:10];
%	EEG = eeg_selectiveinterp(EEG,rej);
%
%               if more than 2 inputs, they come in pairs of
%           - elec: name or number of electrode
%           - trials: bad epochs, on which the interpolation should be
%           performed.

% v0. Max 09.11.2011
% v0.1 Max 25.11.2011: added second input method.
% v0.2 Max 28.08.2012: correct bug when interp channel with no location
%                      information.

if nargin < 2
    error('at least two inputs required');
elseif nargin == 2
    rej = varargin{1};
elseif nargin > 2
    if rem(numel(varargin),2)
        error('elec, trials input should come in pairs.');
    end
    for i = 1:numel(varargin)/2
        rej(i).name = varargin{2*i-1};
        rej(i).trials = varargin{2*i};
    end
end

if ndims(EEG.data) ~= 3
   error('Data should be epoched')
end

for i_chan = 1:numel(rej)
    % only on bad trials
    EEGtmp = pop_select(EEG,'trial',rej(i_chan).trials);
    if isempty(EEG.chanlocs(chnb(rej(i_chan).name)).theta)
        disp(['Warning: No location information for channel ' rej(i_chan).name '. Channel NOT interpolated.'])
        continue
    end
    % interpolate that channel
    EEGtmp = eeg_interp(EEGtmp, chnb(rej(i_chan).name));
    % and paste back into the data.
    EEG.data(chnb(rej(i_chan).name),:,rej(i_chan).trials) = EEGtmp.data(chnb(rej(i_chan).name),:,:);
end
    

