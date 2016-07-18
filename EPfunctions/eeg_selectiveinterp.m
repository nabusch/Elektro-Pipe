function varargout = pop_selectiveinterp(EEG, varargin)

% [EEG, com] = pop_selectiveinterp(EEG)
% interpolate electrodes selected in EEG.reject.rejmanualE
%
% EEG = pop_selectiveinterp(EEG,rej)
% EEG = pop_selectiveinterp(EEG,elec, trials, ...)
%
% Perform a selective interpolation of certain electrodes on certain trials only.
% EEG is an epoched eeglab structure.
%
% Input methods:
%   if only two inputs:
% rej should be a vector structure with fields 
%           - name: containing name or number of the electrodes to work with
%           - trials: bad epochs, on which the interpolation should be
%           performed.
% ex:  
% rej(1).name = 'F1';
% rej(1).trials = [35:51 105 152:166];
% rej(2).name = 22;
% rej(2).trials = [1:10];
%	EEG = pop_selectiveinterp(EEG,rej);
%
%               
%   if more than 2 inputs, they come in pairs of
%           - elec: name or number of electrode
%           - trials: bad epochs, on which the interpolation should be
%           performed.


if nargin == 1
    rejE = EEG.reject.rejmanualE;
elseif nargin == 2
    rejE = varargin{1};
elseif nargin > 2
    if rem(numel(varargin),2)
        error('[elec, trials] input should come in pairs.');
    end
    for i = 1:numel(varargin)/2
        rej(i).name = varargin{2*i-1};
        rej(i).trials = varargin{2*i};
    end
    rejE = false(size(EEG.data,1),size(EEG.data,3));
    for i = 1:numel(rej)
        rejE(chnb(rej(i).name),rej(i).trials) = true;
    end
end

if any(rejE(:))
    GUIBACKCOLOR = [  0.6600    0.7600    1.0000];
    rep = questdlg('Now I am going to interpolate single electrodes you have marked.');
    
    switch rep
        case 'Yes'
            [trials interp] = rejE2struct(rejE);
            EEG.selectiveinterp = interp;
            EEG = eeg_selectiveinterp(EEG,interp);
            % in the case when only EEG was given as input
            % update rejmanual and history to document what has just been
            % done...
            if nargin == 1
                EEG.reject.rejmanualE = zeros(size(EEG.reject.rejmanualE));
                EEG.reject.rejmanual(trials) = 0;
                strcom = 'EEG = pop_selectiveinterp(EEG';
                for i = 1:numel(interp)
                    [dum ename] = chnb(interp(i).name);
                    strcom = [strcom ', ''' ename{1} ''', [' num2str(interp(i).trials') ']'];
                end
                strcom = [strcom ');'];
                varargout{2} = strcom;
            end
            varargout{1} = EEG;
        case 'No'
            [dum EEG.selectiveinterp] = rejE2struct(rejE);
            varargout{1} = EEG;
            return
        case 'Cancel'
            error('Operation canceled');
    end

else
    msgbox('No single electrodes were selected. No selective interpolation.')
    varargout{1} = EEG;
    varargout{2} = '';
    return;
end
function [trials interp] = rejE2struct(rejE)
[elecs,trials] = find(rejE);
ew = unique(elecs);
for iel = 1:numel(ew)
    interp(iel).name = ew(iel);
    interp(iel).trials = trials(elecs == ew(iel));
end
