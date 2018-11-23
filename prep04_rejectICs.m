function EEG = prep04_rejectICs(EP)

[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

EP.S = readtable(EP.st_file);

who_idx = get_subjects(EP);


%%
for isub = 1:length(who_idx)
    
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------
    
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['CFG = ' cfg_name '(' num2str(who_idx(isub)) ', EP.S);'];
    eval(evalstring);
    
    % Write a status message to the command line.
    fprintf('\nNow working on subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));
    
    % Load data set.
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
        
        [EEG, vartable] = pop_eyetrackerica(EEG, types{sacdx},...
            types{fixdx}, [5 0], CFG.eyetracker_ica_varthresh, 2,...
            CFG.eyetracker_ica_feedback ~= 4, CFG.eyetracker_ica_feedback);
        
        if CFG.eyetracker_ica_feedback ~= 4
            fprintf(2, 'Hit continue or F5 to proceed!\n');
            keyboard; % wait for user to check eyetrackerica output
        end
        %% Subtract the components identified via eyetrackerica
        [EEG, com] = pop_subcomp(EEG, find(EEG.reject.gcompreject),1);
        EEG = eegh(com,EEG);
    end
    
    %% run SASICA on the remaining components to identify and mark EMG/EKG etc
    [EEG, com] = SASICA(EEG);
    fprintf(2, 'Hit continue or F5 to proceed!\n')
    keyboard; % wait for user to fiddle around with SASICA
    EEG = evalin('base','EEG'); % SASICA stores the results in base workspace via assignin. So we have to use this workaround...
    EEG = eegh(com,EEG);
    
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    EEG = pop_editset(EEG,'setname',[CFG.subject_name '_ICArejected.set']);
    EEG = pop_saveset(EEG, [CFG.subject_name '_ICArej.set'] , CFG.dir_eeg);
    if strcmp(CFG.ica_rm_continuous, 'cont')
        EEG = pop_editset(EEG, 'setname', [CFG.subject_name '_ICACONTrejected.set']);
        EEG = pop_saveset(EEG, [CFG.subject_name '_ICACONTrej.set'], CFG.dir_eeg);
    end
    
    %add info to table
    EP.S.has_ICAclean(who_idx(isub)) = 1;
    writetable(EP.S, EP.st_file);
    
    %close all old windows
    close all;
end

fprintf('Done.\n')
