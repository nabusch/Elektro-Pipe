function [EEG, CONTEEG] = elektro_epoch(EEG, cfg, CONTEEG)
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
if cfg.keep_continuous
    CONTEEG = EEG;
end
%% actual epoching
[EEG, ~, com] = pop_epoch( EEG, strread(num2str(cfg.trig_target),'%s')',...
    [cfg.epoch_tmin cfg.epoch_tmax], ...
    'newname', 'BDF file epochs', 'epochinfo', 'yes');
EEG = eegh(com, EEG);

%% remove all epochs containing triggers specified in CFG.trig_omit
% or not containing all triggers in CFG.trig_omit_inv
if ~isempty(cfg.trig_omit) || ~isempty(cfg.trig_omit_inv)
    rejidx = zeros(1,length(EEG.epoch));
    if cfg.coregister_Eyelink %coregistered triggers contain strings
        for i=1:length(EEG.epoch)
            switch cfg.trig_omit_inv_mode
                case {'AND', 'and', 'And'}
                    if sum(ismember(num2str(cfg.trig_omit(:)),...
                            EEG.epoch(i).eventtype(:)))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~all(ismember(num2str(cfg.trig_omit_inv(:)),...
                            EEG.epoch(i).eventtype(:))))
                        rejidx(i) =  1;
                    end
                case {'OR', 'or', 'Or'}
                    if sum(ismember(num2str(cfg.trig_omit(:)),...
                            EEG.epoch(i).eventtype(:)))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~any(ismember(num2str(cfg.trig_omit_inv(:)),...
                            EEG.epoch(i).eventtype(:))))
                        rejidx(i) =  1;
                    end
            end
        end
    else
        for i=1:length(EEG.epoch)
            switch cfg.trig_omit_inv_mode
                case {'AND', 'and', 'And'}
                    if sum(ismember(cfg.trig_omit,[EEG.epoch(i).eventtype{:}]))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~all(ismember(cfg.trig_omit_inv,[EEG.epoch(i).eventtype{:}])))
                        rejidx(i) =  1;
                    end
                case {'OR','Or','or'}
                    if sum(ismember(cfg.trig_omit,[EEG.epoch(i).eventtype{:}]))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~any(ismember(cfg.trig_omit_inv,[EEG.epoch(i).eventtype{:}])))
                        rejidx(i) =  1;
                    end
            end
        end
    end
    
    %% in case we're using the unfold-pipe, deleting these epochs is useless. 
    % But we want to keep the latencies of those trials, to later null
    % the respective time-windows in the design matrix.
    if cfg.keep_continuous
        ipoch = 0;
        for irej = find(rejidx)
            [foundlow, foundhigh] = deal(false);
            ipoch = ipoch + 1;
            % find the urevent index of the target trigger
            if cfg.coregister_Eyelink
                tmpidx = find(strcmp({EEG.epoch(irej).eventtype{:}},...
                    num2str(cfg.trig_target)));
            else
                tmpidx = find([EEG.epoch(irej).eventtype{:}] == cfg.trig_target);
            end
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
        rejtrls = find(rejidx);
        if ~isempty(rejtrls)
            for irej = 1:length(minurindx)
                EEG.uf_rej_latencies(irej, 1) = ...
                    EEG.urevent(minurindx(irej)).latency;
                EEG.uf_rej_latencies(irej, 2) = ...
                    EEG.urevent(maxurindx(irej)).latency;
                EEG.uf_rej_latencies(irej, 3) = rejtrls(irej);
                EEG.uf_rej_latencies(irej, 4) = 0;
            end
            CONTEEG.uf_rej_latencies = EEG.uf_rej_latencies;
        end
    end
    EEG = pop_rejepoch(EEG, rejidx, 0);
    EEG = eegh(com, EEG);
end

end