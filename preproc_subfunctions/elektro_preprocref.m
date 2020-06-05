function [EEG] = elektro_preprocref(EEG, cfg, EP, id_idx)
%
% wm: THIS FUNCTION STILL NEEDS A PROPER DOCUMENTATION!

% (c) Niko Busch & Wanja Mössing
% (contact: niko.busch@gmail.com, w.a.moessing@gmail.com)
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program. If not, see <http://www.gnu.org/licenses/>.

if cfg.do_preproc_reref
    %robust average (requires PREP extension)
    if strcmp(cfg.preproc_reference, 'robust')
        %%settings for robust average reference
        fprintf('\n\nfunc_prepareEEG: computing robust reference...\n');
        
        % don't use channels as evaluation channels, of which we already
        % know that they are bad.
        if iscell(EP.S.interp_chans)
            evalChans = find(~ismember(...
                {EEG.chanlocs(cfg.data_chans).labels},...
                strsplit(EP.S.interp_chans{id_idx},',')));
        else
            evalChans = cfg.data_chans;
        end
        
        robustParams = struct('referenceChannels', evalChans,...
            'evaluationChannels', evalChans,...
            'rereference', cfg.data_chans,...
            'interpolationOrder', 'post-reference',...
            'correlationThreshold', 0.1e-99,...
            'ransacOff', true); %disable correlation threshold, as we don't want to detect half of the channels.
        
        % compute reference channel
        [~,robustRef] = performReference(EEG, robustParams);
        % add new robust reference channel to EEG
        EEG.data(end+1,:) = robustRef.referenceSignal;
        EEG.nbchan = size(EEG.data,1);
        EEG.chanlocs(end+1).labels = 'RobustRef';
        EEG.robustRef = robustRef;
        % pass this new reference to eeglab's default rereferencing
        % function. This is necessary, because PREP's performReference only
        % outputs an EEG structure where all channels are interpolated.
        [EEG, com] = pop_reref( EEG, 'RobustRef','keepref','on',...
            'exclude', cfg.data_chans(end)+1:EEG.nbchan-1);
    else
        % normal reference
        [EEG, com] = pop_reref( EEG, cfg.preproc_reference, ...
            'keepref','on', ...
            'exclude', cfg.data_chans(end)+1:EEG.nbchan);
    end
    EEG = eegh(com, EEG);
else
    disp('No rereferencing after import.')
end