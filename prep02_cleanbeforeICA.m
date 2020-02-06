% This script is used for automatic artifact rejection.
%
% Unfortunately, we have to run this process as a script, because the
% rejection functions do not work from within a function due to the strange
% and intransparent inner workings of eeglab.
%
% Note that the script requires that you have a running instance of eeglab.
% Open eeglab using
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab('nogui');
% Wanja Moessing, WWU M�nster, moessing@wwu.de

%% get configuration
[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

EP.S = readtable(EP.st_file);

who_idx = get_subjects(EP);


%% loop over subjects and reject artifacts
for isub = 1:length(who_idx)
    
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['CFG = ' cfg_name '(' num2str(who_idx(isub)) ', EP.S);'];
    eval(evalstring);

    % Write a status message to the command line.
    fprintf('\nNow working on subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));

    % ---------------------------------------------------------------------
    % Load data set.
    % ---------------------------------------------------------------------
    EEG = pop_loadset('filename', [CFG.subject_name '_import.set'] , ...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
    
    if CFG.keep_continuous
        CONTEEG = pop_loadset('filename', [CFG.subject_name '_importCONT.set'] , ...
            'filepath', CFG.dir_eeg, 'loadmode', 'all');
    end
    
    % get amount of initial trials to store the amount of deleted ones in
    % the end
    nUrTrials = size(EEG.data,3);
    
    %% ---------------------------------------------------------------------
    % If EP file specifies channels for interpolation for this subject,
    % interpolate them now.
    % ---------------------------------------------------------------------
    if ismember('interp_chans',EP.S.Properties.VariableNames)
        interp_chans = EP.S.interp_chans(who_idx(isub));
        % Warn about consequences for ICA
        if iscell(interp_chans) %it's not cell if not a single subject has to-be-interpolated channels
            if ~cellfun(@isempty, interp_chans) && CFG.do_interp
                warning(['Your "SubjectsTable" spreadsheet tells me\n',...
                    'to interpolate one or more channels.\n',...
                    'This could obscure ICA in the next step.\n',...
                    'Do you really want to proceed with the ',...
                    '(spherical) interpolation?\nIf not, change',...
                    'CFG.do_interp to 0.']);
                pause(5);
            end
        end
    else
        interp_chans = [];
    end
    
    %interp_chans is cell, as soon as one of the subjects has a channel to
    %be interpolated...
    if iscell(interp_chans)
        %check if cell is empty
        if cellfun(@isempty,interp_chans)
            interp_chans = NaN;
        else
            % For multiple channels, split string by , or ;
            if ismember(',',interp_chans{:})
                interp_chans = strsplit(interp_chans{:},',');
            elseif ismember(';',interp_chans{:})
                interp_chans = strsplit(interp_chans{:},';');
            else
                disp(['Did not find comma or semicolon in interp_chan, assuming'...
                    ' there''s just one channel to interpolate']);
            end
            % check if channels have been entered as labels (e.g., Pz) or as index
            isnumber = isstrprop(interp_chans,'digit');
            clear islabel
            for i = 1:size(isnumber,1)
                islabel(i) = ~all(isnumber{i});
            end
            %assure that excel table is consistent
            if ~(all(islabel) || all(~islabel))
                error(['Please use consistent labeling of channels to '...
                    'interpolate. It appears some are index and some are '...
                    'label (e.g., "A17,64" instead of "A17,B32" or "17,64")']);
            elseif all(islabel)
                % if it's labels, find the indeces.
                clear out
                for i = 1:length(interp_chans)
                    out(i) = find(strcmp(interp_chans{i},{EEG.chanlocs.labels}));
                end
            elseif all(~islabel)
                clear out
                for i = 1:length(interp_chans)
                    out(i) = str2num(interp_chans{i});
                end
            end
            interp_chans = out;
        end
    end
    
    %run actual interpolation
    if isempty(interp_chans) | isnan(interp_chans)
        fprintf('No channels to interpolate.\n')
    elseif CFG.do_interp
        str = sprintf('%d ', interp_chans);
        fprintf('Interpolating channel(S): %s\n', str);
        EEG = eeg_interp(EEG, interp_chans);
        if CFG.keep_continuous
            CONTEEG = eeg_interp(CONTEEG, interp_chans);
        end
    end
    
    %% --------------------------------------------------------------------
    % Run multiple algorithms to get a good selection of artifacts
    % ---------------------------------------------------------------------
    
    % In case some channels should not be used for detection, extract the
    % proper indeces
    UsedChans = CFG.data_chans;
    if CFG.ignore_interp_chans
        UsedChans = setdiff(UsedChans,interp_chans);
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
    if CFG.rej_auto
        finames = fieldnames(plotRej);
        deleteme = zeros(1,EEG.trials);
        for i = 1:length(finames)
            tmp = eegplot2trial(plotRej.(finames{i}),...
                EEG.pnts, EEG.trials);
            deleteme = deleteme | tmp;
        end
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
        
        % eegplot2trial cannot deal with multi-rejection
        rejTime = eegrej(:,1:2);
        [~,firstOccurences,~] = unique(rejTime,'rows');
        eegrej = eegrej(firstOccurences,:);
        
        [badtrls, badChnXtrl] = eegplot2trial(eegrej,EEG.pnts,length(EEG.epoch));
        trials_to_delete = find(badtrls);
        clear eegrej;
        % ---------------------------------------------------------------------
        %  Execute interpolation and rejection
        % ---------------------------------------------------------------------
        EEG = pop_selectiveinterp(EEG,badChnXtrl);
        [EEG, com] = pop_rejepoch(EEG, trials_to_delete, 1);
        EEG = eegh(com,EEG);
    end
    
    %% --------------------------------------------------------------------
    % Save data and edit SubjectsTable
    % ---------------------------------------------------------------------
    EEG = pop_editset(EEG, 'setname', [CFG.subject_name '_CleanBeforeICA.set']);
    EEG = pop_saveset(EEG, [CFG.subject_name '_CleanBeforeICA.set'] , CFG.dir_eeg);
    if CFG.keep_continuous
        % store behavioral coregistration in CONTEEG as well
        CONTEEG.EpochEvent = EEG.event;
        CONTEEG = pop_editset(CONTEEG, 'setname', [CFG.subject_name '_CleanBeforeICACONT.set']);
        CONTEEG = pop_saveset(CONTEEG, [CFG.subject_name '_CleanBeforeICACONT.set'] , CFG.dir_eeg);
    end
    
    % get amount of rejected trials
    nRej = nUrTrials - size(EEG.data,3);
    EP.S.N_rejected_Trials(who_idx(isub)) = nRej;
    EP.S.has_prepICA(who_idx(isub)) = 1;
    writetable(EP.S, EP.st_file)
end
