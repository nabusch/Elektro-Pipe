
[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

S = readtable(EP.st_file);

who_idx = get_subjects(S, EP.who);


%%
for isub = 1:length(who_idx)
    
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------

    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['CFG = ' cfg_name '(' num2str(who_idx(isub)) ', S);'];
    eval(evalstring);
    
    
    % Write a status message to the command line.
    fprintf('\nNow working on subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));   
    
    % Load data set.
    EEG = pop_loadset('filename', [CFG.subject_name '_ICA.set'] , ...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
    %% Run SASICA
    [EEG, com] = SASICA(EEG);
    EEG = eegh(com,EEG);
    %%
    keyboard
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