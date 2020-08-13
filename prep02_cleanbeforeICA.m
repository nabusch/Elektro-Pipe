% This script is used for automatic artifact rejection prior to ICA.
%
% Note: pop_eegplot cannot be meaninfully used to select artefactual
% components from within a function. Therefore, prep02 needs to be a script
% until eeg_browser can fully replace eegplot.
%
% (c) Niko Busch & Wanja Mössing 
% (contact: niko.busch@gmail.com; w.a.moessing@gmail.com)
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

%% get configuration
[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
addpath(cfg_dir);
EP.S = readtable(EP.st_file);
who_idx = get_subjects(EP);
cfg_fun = str2func(cfg_name);
elektro_status('Detecting artifacts');

%% loop over subjects and reject artifacts
for isub = 1:length(who_idx)
    clear global eegrej
    
    % get subject's config
    CFG = cfg_fun(who_idx(isub), EP.S);

    % Write a status message to the command line.
    fprintf('\nNow working on subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));

    % ---------------------------------------------------------------------
    % Load data set.
    % ---------------------------------------------------------------------
    if ~any([CFG.do_rej_thresh, CFG.do_rej_trend, CFG.do_rej_trend,...
            CFG.do_rej_prob, CFG.do_rej_kurt])
        disp(['No artifact detection configured, creating symbolic links',...
            ' of prep01 files to save time and memory.']);
        ln_pat = ['ln -s ',...
            fullfile(CFG.dir_eeg, [CFG.subject_name, '_import%s.%s ']),...
            fullfile(CFG.dir_eeg, [CFG.subject_name, '_CleanBeforeICA%s.%s'])];
        exis_pat = fullfile(CFG.dir_eeg, [CFG.subject_name, '_CleanBeforeICA%s.%s']);
        f_x = {'', '', 'CONT', 'CONT'};
        f_y = {'set', 'fdt', 'set', 'fdt'};
        f_exists = cellfun(@(x, y) exist(sprintf(exis_pat, x, y), 'file'),...
            f_x, f_y);
        if isunix
            for i_ex_f = find(f_exists == 2)
                delete(sprintf(exis_pat, f_x{i_ex_f}, f_y{i_ex_f}));
            end
            system(sprintf(ln_pat, '', 'set', '', 'set'));
            system(sprintf(ln_pat, '', 'fdt', '', 'fdt'));
            if CFG.keep_continuous
                system(sprintf(ln_pat, 'CONT', 'set', 'CONT', 'set'));
                system(sprintf(ln_pat, 'CONT', 'fdt', 'CONT', 'fdt'));
            end
            continue
        else
           error(['Linux only! If you really must run this on Windows and'...
               ' don''t want to reject artifact with prep02,\nconsider '...
               'renaming prep01 files for prep03']);
        end
    end
    
    EEG = pop_loadset('filename', [CFG.subject_name '_import.set'] , ...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
    
    if CFG.keep_continuous
        CONTEEG = pop_loadset('filename', [CFG.subject_name '_importCONT.set'] , ...
            'filepath', CFG.dir_eeg, 'loadmode', 'all');
    end
    
    % get amount of initial trials to store the amount of deleted ones in
    % the end
    nUrTrials = size(EEG.data, 3);
    
    %% --------------------------------------------------------------------
    % Run multiple algorithms to get a good selection of artifacts
    % ---------------------------------------------------------------------
    
    % In case some channels should not be used for detection, extract the
    % proper indeces
    [~, interp_chans] = elektro_chanlabeltransformer(...
        EP.S.interp_chans(who_idx(isub)), EEG.chanlocs);
    UsedChans = CFG.data_chans;
    if CFG.ignore_interp_chans
        UsedChans = setdiff(UsedChans, interp_chans);
    end
    if strcmp(CFG.preproc_reference, 'robust') & CFG.do_preproc_reref
        % exclude the artificial robust reference channel and those
        % channels detected as bad.
        UsedChans = setdiff(UsedChans,...
            [EEG.robustRef.badChannels.all,...
            find(strcmp({EEG.chanlocs.labels},'RobustRef'))]);
    end
    
    % ---------------------------------------------------------------------
    % 1. Amplitude criterion
    %    Thresholds should usually be higher than blinks, to delete very
    %    extreme values but leave blinks to ICA.
    % ---------------------------------------------------------------------
    if CFG.do_rej_thresh
        fprintf(['\n================================================\n',...
            'Testing amplitute criterion (auto artifact detection)',...
            '...\n================================================\n']);
        EEG = pop_eegthresh(EEG, 1, UsedChans, ...
            -CFG.rej_thresh, CFG.rej_thresh, ...
            CFG.rej_thresh_tmin, CFG.rej_thresh_tmax, 1, 0);
    end
    plotRej.thr = trial2eegplot(EEG.reject.rejthresh, EEG.reject.rejthreshE,...
        EEG.pnts, EEG.reject.rejthreshcol);
    
    % ---------------------------------------------------------------------
    % 2. Reject abnormal trends
    %    Linear drifts can occur due to artifactual currents.
    %    This function fits a linear
    % ---------------------------------------------------------------------
    if CFG.do_rej_trend
        fprintf(['\n================================================\n',...
            'Searching for abnormal trends (auto artifact detection)',...
            '...\n================================================\n']);
        EEG = pop_rejtrend(EEG, 1, UsedChans, CFG.rej_trend_winsize,...
            CFG.rej_trend_maxSlope, CFG.rej_trend_minR, 1, 0, 0);
    end
    plotRej.trend = trial2eegplot(EEG.reject.rejconst, EEG.reject.rejconstE,...
        EEG.pnts, EEG.reject.rejconstcol);
    
    % ---------------------------------------------------------------------
    % 3. Reject improbable data
    %    Create a probability distribution for all data and reject trials
    %    that are highly improbable.
    % ---------------------------------------------------------------------
    if CFG.do_rej_prob
        if ~isempty(CFG.preproc_reference) && ...
                ~strcmp(CFG.preproc_reference, 'robust')
            error(sprintf([...
                'Average reference is mandatory for artifact detection',...
                ' via joint probability.\nConsider changing your CFG.']));
        end
        fprintf(['\n================================================\n',...
            'Detecting improbable data (auto artifact detection)',...
            '...\n================================================\n']);
        
        % During its initial run, pop_jointprob ignores the channel
        % argument. We thus create a temporary subset and identify bad
        % epochs in that.
        JP_EEG = pop_select(EEG, 'channel', UsedChans);
        JP_EEG = pop_jointprob(JP_EEG, 1, 1:JP_EEG.nbchan,...
            CFG.rej_prob_locthresh, CFG.rej_prob_globthresh,...
            1, 0);
    end
    if CFG.do_rej_prob
        % Subsequently, use the information we gathered and apply it to the
        % original dataset.
         tmp = trial2eegplot(JP_EEG.reject.rejjp,...
            JP_EEG.reject.rejjpE, JP_EEG.pnts, JP_EEG.reject.rejjpcol);
        out = size(tmp);
        plotRej.jp = zeros(out(1),EEG.nbchan+5); %1st 5 columns aren't chans
        plotRej.jp(:,[1:5,UsedChans+5]) = tmp;
    else
        plotRej.jp = trial2eegplot(EEG.reject.rejjp,...
            EEG.reject.rejjpE, EEG.pnts, EEG.reject.rejjpcol);
    end
    % ---------------------------------------------------------------------
    % 4. Reject abnormally distributed data
    %    This is based on kurtosis (peakiness). Data with very high or very
    %    low kurtosis are unlikely to be brain generated.
    % ---------------------------------------------------------------------
    if CFG.do_rej_kurt
        fprintf(['\n================================================\n',...
            'Detecting abnormally distributed data (auto artifact detection)',...
            '...\n================================================\n']);
        EEG = pop_rejkurt(EEG, 1, UsedChans, CFG.rej_kurt_locthresh,...
            CFG.rej_kurt_globthresh, 1, 0);
    end
    plotRej.kurt = trial2eegplot(EEG.reject.rejkurt, EEG.reject.rejkurtE,...
        EEG.pnts, EEG.reject.rejkurtcol);
    
    % combine info for plotting
    fn = fieldnames(plotRej)';
    foo = find(~structfun(@isempty, plotRej))';
    plotRejshow = [];
    for i = foo
        plotRejshow = [plotRejshow; plotRej.(fn{i})];
    end
    
    %combine info for auto-removing epochs
    finames = fieldnames(plotRej);
    deleteme = zeros(1,EEG.trials);
    for i = 1:length(finames)
        tmp = eegplot2trial(plotRej.(finames{i}),...
            EEG.pnts, EEG.trials);
        deleteme = deleteme | tmp;
    end
    if CFG.rej_auto
        EEG = pop_rejepoch(EEG, deleteme, 0);
    end
    
    
    %% ---------------------------------------------------------------------
    % Optional:
    % Manual data inspection; mark electrodes for trial-wise interpolation.
    % We have to interrupt programm execution with "keyboard" while the
    % rejection GUI is active. Continue by hitting the "Continue" button in
    % the Matlab editor menu bar.
    %  ---------------------------------------------------------------------
    
    if ~CFG.rej_auto
        %color for the bipolar EOG and Eyetracking channels
        %EEG
        col = cell(1,length(EEG.chanlocs));
        for ichan=1:length(CFG.data_chans)
            col{ichan} = [0 0 0];
        end
        
        %In case a robust reference is used
        for ichan = find(ismember({EEG.chanlocs.labels},{'RobustRef'}))
            col{ichan} = [0.2588 0.9569 0.5961]; %"lime"
        end
        
        %EOG
        for ichan=find(ismember({EEG.chanlocs.labels},{'VEOG', 'HEOG'}))
            col{ichan} = [1 0.0784314 0.576471]; %"deeppink"
        end
        
        %Eye
        for ichan=find(ismember({EEG.chanlocs.labels},...
                {'Eyegaze_X', 'Eyegaze_Y', 'Pupil_Dilation',...
                'Eyegaze-X', 'Eyegaze-Y', 'Pupil-Dilation'}))
            col{ichan} = [0 1 0];
        end
        
        global eegrej
        
        %show a popup with artifact legend
        if ~all(structfun(@isempty, plotRej))
            figure;
            k=0;
            fnames = fieldnames(plotRej);
            for i = 1:length(fnames)
                fn = fnames(i);
                if ~isempty(plotRej.(fn{:}))
                    k=k+1;
                    plot([1,2],[k,k],'Color',...
                        plotRej.(fn{:})(1,3:5),'LineWidth',3);
                    text(2.2,k,k,fn{:});
                    if k==1
                        hold on;
                    end
                end
            end
            axis([0.5,4,0.5,k+0.5]);
            axis off; hold off;
        end
        
        %plot data
        % set default to 1 for backward compatibility
        if ~isfield(CFG, 'display_events')
            CFG.display_events = 1;
        end
        if CFG.display_events
            commands = {'command', 'global eegrej, eegrej = TMPREJ'};
        else
            disp(['NOTE: You turned off events. To turn them on again,',...
                ' set CFG.display_events to true']);
            commands = {'command', 'global eegrej, eegrej = TMPREJ',...
                'events', []};
        end
        mypop_eegplot(EEG, 1, 1, 0,'submean','on', 'winlength', 15, 'winrej',...
            plotRejshow,'color',col, commands{:});
        
        disp('Interrupting function now. Waiting for you to press')
        disp('"Update marks", and hit "Continue" (or F5) in Matlab editor menu')
        keyboard
        
        if isempty(eegrej)
            waitfor(...
                msgbox(['eegrej is empty. This means you likely clicked "x" or'...
                ' used "close" to close the eegplot. Please hit "update marks"'...
                ' instead. Otherwise, no trials will be rejected.']));
        end
        
        % eegplot2trial cannot deal with multi-rejection
        if ~isempty(eegrej)
            rejTime = eegrej(:,1:2);
            [~,firstOccurences,~] = unique(rejTime,'rows');
            eegrej = eegrej(firstOccurences,:);
            
            [badtrls, badChnXtrl] = eegplot2trial(eegrej,EEG.pnts,length(EEG.epoch));
            trials_to_delete = find(badtrls);
%             foo = find(deleteme);
%             assert(isequal(trials_to_delete, foo), 'why does eeglab use global variables??') %debugger
            % ---------------------------------------------------------------------
            %  Execute interpolation and rejection
            % ---------------------------------------------------------------------
%             EEG = pop_selectiveinterp(EEG, badChnXtrl);
            % currently, the selective interpolation is nonsense. The
            % rejepoch statement below simply deletes the affected trials
            % anyways. Alternatively, one could remove the trials with
            % to-be-interpolated channels from the vector of to-be-deleted
            % trials. In that case, some trials that are generally bad but
            % have a channel marked for interpolation will not be rejected.
            [EEG, com] = pop_rejepoch(EEG, trials_to_delete, 1);
            EEG = eegh(com,EEG);
        end
        clear eegrej;
    end
    
    %% --------------------------------------------------------------------
    % Save data and edit SubjectsTable
    % ---------------------------------------------------------------------
    EEG = pop_editset(EEG, 'setname', [CFG.subject_name '_CleanBeforeICA.set']);
    EEG = pop_saveset(EEG, [CFG.subject_name '_CleanBeforeICA.set'] , CFG.dir_eeg);
    if CFG.keep_continuous
        % store behavioral coregistration in CONTEEG as well
        CONTEEG.EpochEvent = EEG.event;
        disp('CONTEEG:')
        CONTEEG = pop_editset(CONTEEG, 'setname', [CFG.subject_name '_CleanBeforeICACONT.set']);
        CONTEEG = pop_saveset(CONTEEG, [CFG.subject_name '_CleanBeforeICACONT.set'] , CFG.dir_eeg);
    end
    
    % get amount of rejected trials
    nRej = nUrTrials - size(EEG.data,3);
    EP.S.N_rejected_Trials(who_idx(isub)) = nRej;
    EP.S.has_prepICA(who_idx(isub)) = 1;
    writetable(EP.S, EP.st_file)
end
