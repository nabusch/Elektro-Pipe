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
    EEG = pop_loadset('filename', [CFG.subject_name '_ICA.set'] , ...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
    %% Run SASICA
    
    % only use eyetracking data for component selection if indicated in
    % getcfg
    if CFG.eye_ica
        if CFG.eye_ica_useEP
            if EP.S.Tracker_ICA(isub)
                EEG         = create_blink_channel(EEG);
                fprintf(['You chose to use eyetracking data to select ICA-\n'...
                    'components. To do so, use ''Eyegaze_X'' and ''Eyegaze_Y''\n'...
                    'instead of HEOG and VEOG.\nSelect ''correlation with'...
                    'other channel(s)'' and insert ''Blinks''...\n']);
            else
                fprintf(2,['NOTE: According to the Excel table, this subject has\n'...
                    'noisy Eyetracking data. Please use ''HEOG'' and ''VEOG''\n'...
                    'instead of Eyetracking channels. Make sure to unselect\n'...
                    'the Blinkchannel if it''s entered, as it has not been\n'...
                    'created for the present subject!\n']);
            end
        else
            EEG         = create_blink_channel(EEG);
            fprintf(['You chose to use eyetracking data to select ICA-\n'...
                'components. To do so, use ''Eyegaze_X'' and ''Eyegaze_Y''\n'...
                'instead of HEOG and VEOG.\nSelect ''correlation with'...
                'other channel(s)'' and insert ''Blinks''...\n']);
        end
    end
    [EEG, com] = SASICA(EEG);
    %[EEG,com] = SASICA(EEG,'MARA_enable',0,'FASTER_enable',0,'FASTER_blinkchans','Blinks','ADJUST_enable',0,'chancorr_enable',1,'chancorr_channames',71,'chancorr_corthresh','auto 4','EOGcorr_enable',1,'EOGcorr_Heogchannames',66,'EOGcorr_corthreshH','auto 4','EOGcorr_Veogchannames',67,'EOGcorr_corthreshV','auto 4','resvar_enable',0,'resvar_thresh',15,'SNR_enable',0,'SNR_snrcut',1,'SNR_snrBL',[-Inf 0] ,'SNR_snrPOI',[0 Inf] ,'trialfoc_enable',1,'trialfoc_focaltrialout','auto','focalcomp_enable',1,'focalcomp_focalICAout','auto','autocorr_enable',1,'autocorr_autocorrint',20,'autocorr_dropautocorr','auto','opts_noplot',0,'opts_nocompute',0,'opts_FontSize',14);
    %%
    keyboard;
    EEG = evalin('base','EEG'); %SASICA stores the results in base workspace via assignin. So we have to use this workaround...
    EEG = eegh(com,EEG);

    %%
    [EEG, com] = pop_subcomp(EEG, find(EEG.reject.gcompreject),1);
    if isempty(com)
        return
    end
    EEG = eegh(com,EEG);
    
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    EEG = pop_editset(EEG,'setname',[CFG.subject_name '_ICArejected.set']);
    EEG = pop_saveset( EEG, [CFG.subject_name '_ICArej.set'] , CFG.dir_eeg);
    
    %add info to table
    EP.S.has_ICAclean(who_idx(isub)) = 1;
    writetable(EP.S, EP.st_file);
    
    %close all old windows
    close all;
end

fprintf('Done.\n')   

% %%
% eeg_SASICA(EEG)
% %%
%  [EEG, com] = SASICA(EEG, ...        
%         'EOGcorr_enable',1,...
%         'EOGcorr_Heogchannames',70,...
%         'EOGcorr_corthreshH','auto 4',...
%         'EOGcorr_Veogchannames',71,...
%         'EOGcorr_corthreshV','auto 4',...
%         'focalcomp_enable',1,...
%         'focalcomp_focalICAout','auto',...
%         'autocorr_enable',1,...
%         'autocorr_autocorrint',20,...
%         'autocorr_dropautocorr','auto',...
%         'opts_noplot',0,...
%         'opts_nocompute',0,...
%         'opts_FontSize',14);