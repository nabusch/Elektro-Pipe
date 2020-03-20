function EEG = prep04_rejectICs(EP)

[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

EP.S = readtable(EP.st_file);

who_idx = get_subjects(EP);

%%
autoclick = 'no'; % don't automatically click 'compute' in sasica
for isub = 1:length(who_idx)
    
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['CFG = ' cfg_name '(' num2str(who_idx(isub)) ', EP.S);'];
    eval(evalstring);
    
    %% some defaults for backward compatibility
    if ~isfield(CFG, 'do_SASICA')
        CFG.do_SASICA = true;
    end
    
    if ~isfield(CFG, 'ica_reject_fully_automatic')
        CFG.ica_reject_fully_automatic = false;
    end
    
    % Write a status message to the command line.
    fprintf('\nNow working on subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));
    
    % Load data set.
    % If config says so,weights have been copied to continuous data.
    % If ica_rm_continuous in config is 'cont', we want to remove
    % components from continuous data and work with those.
    if CFG.keep_continuous && strcmp(CFG.ica_rm_continuous, 'cont')
        EEG = pop_loadset('filename', [CFG.subject_name '_ICACONT.set'],...
            'filepath', CFG.dir_eeg, 'loadmode', 'all');
    else
        EEG = pop_loadset('filename', [CFG.subject_name '_ICA.set'],...
            'filepath', CFG.dir_eeg, 'loadmode', 'all');
    end
    
    
    %% Run SASICA
    
    % only use eyetracking data for component selection if indicated in
    % getcfg
    if CFG.eye_ica && ~CFG.eyetracker_ica
        error(['cfg.eye_ica is deprecated. Use CFG.eyetracker_ica ',...
            'instead.']);
        %         if CFG.eye_ica_useEP
        %             if EP.S.Tracker_ICA(isub)
        %                 EEG         = create_blink_channel(EEG);
        %                 fprintf(['You chose to use eyetracking data to select ICA-\n'...
        %                     'components. To do so, use ''Eyegaze_X'' and ''Eyegaze_Y''\n'...
        %                     'instead of HEOG and VEOG.\nSelect ''correlation with'...
        %                     'other channel(s)'' and insert ''Blinks''...\n']);
        %             else
        %                 fprintf(2,['NOTE: According to the Excel table, this subject has\n'...
        %                     'noisy Eyetracking data. Please use ''HEOG'' and ''VEOG''\n'...
        %                     'instead of Eyetracking channels. Make sure to unselect\n'...
        %                     'the Blinkchannel if it''s entered, as it has not been\n'...
        %                     'created for the present subject!\n']);
        %             end
        %         else
        %             EEG         = create_blink_channel(EEG);
        %             fprintf(['You chose to use eyetracking data to select ICA-\n'...
        %                 'components. To do so, use ''Eyegaze_X'' and ''Eyegaze_Y''\n'...
        %                 'instead of HEOG and VEOG.\nSelect ''correlation with'...
        %                 'other channel(s)'' and insert ''Blinks''...\n']);
        %         end
    end
    
    %% Auto-flag ocular ICs based on sac/fix variance ratio
    if CFG.eyetracker_ica
        % try to guess what fixations and saccades are called in our
        % dataset
        types = unique({EEG.event.type});
        fixdx = cellfun(@(x) endsWith(x, 'fixation') ||...
            startsWith(x, 'fixation'), types);
        sacdx = cellfun(@(x) endsWith(x, 'saccade') ||...
            startsWith(x, 'saccade'), types);
        if sum(fixdx) ~= 1 || sum(sacdx) ~= 1
            error(['Could not determine unique fixation and or saccade',...
                ' identifier event. Consider renaming in EEG.event.type']);
        end
        
        % make all latencies integers to avoid index warning in
        % geticavariance.m
        if all(arrayfun(@isscalar, [EEG.event.latency]))
           tmp = cellfun(@int64, {EEG.event.latency}, 'UniformOutput', 0);
           [EEG.event.latency] = tmp{:};
        end
        
        
        [EEG, vartable] = pop_eyetrackerica(EEG, types{sacdx},...
            types{fixdx}, [5 0], CFG.eyetracker_ica_varthresh, 2,...
            CFG.eyetracker_ica_feedback ~= 4, CFG.eyetracker_ica_feedback);
        
        if CFG.eyetracker_ica_feedback ~= 4
            fprintf(2, 'Hit continue or F5 to proceed!\n');
            keyboard; % wait for user to check eyetrackerica output
        end
        %% deactivated the auto-subtraction. components will be marked in SASICA
%         %% Subtract the components identified via eyetrackerica
%         [EEG, com] = pop_subcomp(EEG, find(EEG.reject.gcompreject),1);
%         EEG = eegh(com,EEG);

    end
    
    %% run SASICA on the remaining components to identify and mark EMG/EKG etc
    if CFG.do_SASICA
        if CFG.ica_reject_fully_automatic
            error(['don''t know how to use SASICA and fully automatic ic'...
                ' rejection. Please check your config and either change'...
                ' ''do_SASICA'' or ''ica_reject_fully_automatic''']);
        end
        [EEG, com] = SASICA(EEG);
        % try to get the handle of the 'compute' button and click it
        % automatically
        S = findall(0, 'name', 'Select ICA components');
        OK = S.Children(strcmp(get(S.Children, 'tag'), 'push_ok'));
        if strcmp(autoclick, 'yes')
            OK.Callback(S,1);
        end
        fprintf(2, 'Hit continue or F5 to proceed!\n')
        keyboard; % wait for user to fiddle around with SASICA
        
        % ask user if 'compute' button should be clicked automatically
        if strcmp(autoclick, 'no')
            autoclick = questdlg(['Would you like to apply the same SASICA ',...
                'configuration to all subsequent files?'],...
                'Click compute automatically?',...
                'yes', 'no', 'don''t ask again', 'yes');
        end
        
        EEG = evalin('base','EEG'); % SASICA stores the results in base workspace via assignin. So we have to use this workaround...
        EEG = eegh(com, EEG);
        
        %% Subtract the components identified via SASICA
        [EEG, com] = pop_subcomp(EEG, find(EEG.reject.gcompreject), 1);
        EEG = eegh(com, EEG);
    end
    
    %% alternatively, reject artifacts completely automatic
    if CFG.ica_reject_fully_automatic
        % Find bad ICs (those that correlate strongly with VEOG/HEOG) and
        % remove them from the original data.
        icact = EEG.icaact;
        chans = [find(strcmp({EEG.chanlocs.labels}, 'VEOG')),...
            find(strcmp({EEG.chanlocs.labels}, 'HEOG'))];
        
        
        for ichan = 1:length(chans)
            
            eeg = EEG.data(chans(ichan),:,:);
            eeg = reshape(eeg, [1, EEG.pnts * EEG.trials]);
            
            for icomp = 1:size(icact,1)
                
                ic = icact(icomp,:);
                ic = reshape(ic,  [1, EEG.pnts * EEG.trials]);
                
                corr_tmp = corrcoef(ic, eeg);
                corr_eeg_ic(icomp, ichan) = corr_tmp(1, 2);
                
            end
            
            bad_ic{ichan} = find(abs(corr_eeg_ic(:,ichan)) >= CFG.ic_corr_bad)';
            bad_ic_cor{ichan} = corr_eeg_ic(bad_ic{ichan},ichan);
        end
        
        fprintf('Found %d bad ICs.\n', length(unique([bad_ic{:}])))
        for ichan = 1:length(chans)
            for ibad = 1:length(bad_ic{ichan})
                fprintf('EEG chan %d: IC %d. r = %2.2f.\n', ...
                    chans(ichan), bad_ic{ichan}(ibad), bad_ic_cor{ichan}(ibad))
            end
        end
        EEG = pop_subcomp(EEG, unique([bad_ic{:}]), 0);
    end
    

    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    if CFG.keep_continuous && strcmp(CFG.ica_rm_continuous, 'cont')
        EEG = pop_editset(EEG, 'setname', [CFG.subject_name,...
            '_ICACONTrejected.set']);
        EEG = pop_saveset(EEG, [CFG.subject_name '_ICACONTrej.set'],...
            CFG.dir_eeg);
    else
        EEG = pop_editset(EEG,'setname',[CFG.subject_name,...
            '_ICArejected.set']);
        EEG = pop_saveset(EEG, [CFG.subject_name '_ICArej.set'],...
            CFG.dir_eeg);
    end
    
    %add info to table
    EP.S.has_ICAclean(who_idx(isub)) = 1;
    writetable(EP.S, EP.st_file);
    
    %close SASICA window
    if CFG.do_SASICA
        close(S);
    end
end

fprintf('Done.\n')
