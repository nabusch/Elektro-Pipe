function [EEG, EP, CONTEEG] = elektro_checklatency(EEG, cfg, id_idx, EP, CONTEEG)
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

if ~isempty(cfg.checklatency)
    elektro_status('checking trigger latencies');
    %find all latencies
    badtrls = [];
    tridx = 0;
    for iTrigger = cfg.checklatency
        tridx=tridx+1;
        for iEpoch=1:length(EEG.epoch)
            if cfg.coregister_Eyelink
                idx = strcmp(num2str(iTrigger),EEG.epoch(iEpoch).eventtype);
            else
                if iscell(EEG.epoch(iEpoch).eventtype)
                    idx = cell2mat(EEG.epoch(iEpoch).eventtype)==iTrigger;
                else
                    idx = [EEG.epoch(iEpoch).eventtype]==iTrigger;
                end
            end
            if any(idx)
                trigLatency(tridx,iEpoch) = EEG.epoch(iEpoch).eventlatency(idx);
            else
                trigLatency(tridx,iEpoch) = {9e+99}; %in the rare case that the current trigger does not appear in the epoch
            end
        end
        badtrls = [badtrls,find([trigLatency{tridx,:}]-median([trigLatency{tridx,:}])>cfg.allowedlatency)];
    end
    EEG.latencyBasedRejection = badtrls;
    %create a plot and store which trials look weird. These can later be
    %deleted after coregistration with behavioral data.
    set(0,'DefaultFigureVisible','off');
    figure;
    for iPlot=1:length(cfg.checklatency)
        subplot(ceil(length(cfg.checklatency)/3),3,iPlot);
        histogram([trigLatency{iPlot,:}]);
        xlabel('[ms]');ylabel('N trials');
        title(['Trigger ',num2str(cfg.checklatency(iPlot))]);
    end
    
    % suptitle is nice to have but not necessary and only available in the
    % Bioinformatics Toolbox
    v = ver;
    if ismember('Bioinformatics Toolbox',{v.Name})
        suptitle(['Deleted ',num2str(length(EEG.latencyBasedRejection)),...
            ' trials']);
    end
    
    %temporarily store how many trials have been deleted and add that to
    %table.
    fid = fopen([cfg.dir_eeg,filesep,'badlatency.txt'],'a');
    fprintf(fid,num2str(length(EEG.latencyBasedRejection)));
    fclose(fid);
    EP.S.N_BadLatencyRejections(id_idx) = val;
    
    
    
    set(0,'DefaultFigureVisible','off');
    
    
    
    % in case we're using the unfold-pipe, deleting epochs is useless. But
    % we want to keep the latencies of those trials, to later interpolate
    % the respective time-windows.
    if cfg.keep_continuous && ~isempty(badtrls)
        ipoch = 0;
        for irej = badtrls
            [foundlow, foundhigh] = deal(false);
            ipoch = ipoch + 1;
            % find the urevent index of the target trigger
            tmpidx = [EEG.epoch(irej).eventtype{:}] == cfg.trig_target;
            urindx = EEG.epoch(irej).eventurevent{tmpidx};
            % sanity check
            assert(EEG.urevent(urindx).type == cfg.trig_target,...
                ['Urevent and found event do not match. This is a ',...
                'serious error and could have various reasons. ',...
                'You should check this!']);
            % get the preceding and the following trial interrupting
            % triggers in the urevent structure
            k = 0;
            while ~(foundlow && foundhigh)
                k = k + 1;
                mindx = urindx - k;
                maxdx = urindx + k;
                if mindx <= 0 && ~foundlow
                    msg = sprintf(['Trial %i does not seem to be ',...
                        'preceded by a cfg.trig_trial_onset. Assuming ',...
                        'that it''s the first trial in the data track'],...
                        irej);
                    warning(msg);
                    foundlow = true;
                    minurindx(ipoch) = 1;
                elseif ~foundlow
                    if EEG.urevent(mindx).type == cfg.trig_trial_onset
                        foundlow = true;
                        minurindx(ipoch) = mindx;
                    end
                end
                if maxdx >= length(EEG.urevent) && ~foundhigh
                    msg = sprintf(['Trial %i does not seem to be ',...
                        'followed by a cfg.trig_trial_onset. Assuming ',...
                        'that it''s the last trial in the data track'],...
                        irej);
                    warning(msg);
                    foundhigh = true;
                    maxurindx(ipoch) = length(EEG.urevent);
                elseif ~foundhigh
                    if EEG.urevent(maxdx).type == cfg.trig_trial_onset
                        foundhigh = true;
                        maxurindx(ipoch) = maxdx;
                    end
                end
            end
        end
        % get the latency information for later interpolation in unfold
        if isfield(EEG, 'uf_rej_latencies')
            startidx = size(EEG.uf_rej_latencies,1);
        else
            startidx = 0;
        end
        for irej = 1:length(minurindx)
            EEG.uf_rej_latencies(startidx + irej, 1) = ...
                EEG.urevent(minurindx(irej)).latency;
            EEG.uf_rej_latencies(startidx + irej, 2) = ...
                EEG.urevent(maxurindx(irej)).latency;
            EEG.uf_rej_latencies(startidx + irej, 3) = badtrls(irej);
            EEG.uf_rej_latencies(startidx + irej, 4) = 1;
        end
        CONTEEG.uf_rej_latencies = EEG.uf_rej_latencies;
    end
end
end