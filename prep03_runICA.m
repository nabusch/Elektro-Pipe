function EEG = s03_eeg_runica(EP)

[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

S = readtable(EP.st_file);

who_idx = get_subjects(S, EP.who);


for isub = 1:length(who_idx)
    
    EEG = [];
    
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------
    
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['CFG = ' cfg_name '(' num2str(who_idx(isub)) ', S);'];
    eval(evalstring);
    
    % Write a status message to the command line.
    fprintf('\nNow processing subject %s, (number %d of %d).\n\n', ...
        CFG.subject_name, isub, length(who_idx));
    
    % Load data set.
    EEG = pop_loadset('filename', [CFG.subject_name '_CleanBeforeICA.set'] , ...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
    
    
    % -------------------------------------------------------------- 
    % Check how many components to extract and then run ICA. We need a
    % separate call to pop_runica in every test section because runica does
    % not accept 'pca', 0, even though the help message claims that this
    % defaults to not doing PCA.
    % If exists, use the subject-specific number of ICA components.
    % Otherwise, let EEGLAB determine the number of components
    % (CFG.ica_ncomps==0) or use a fixed number of components
    % (CFG.ica_ncomps>0).
    % --------------------------------------------------------------
    
    ncomps_sub = S.ica_ncomps(who_idx(isub));
    if ~isempty(ncomps_sub) & ~isnan(ncomps_sub)& ncomps_sub~=0
        fprintf('Subject-specific setting:\n');
        fprintf('Extracting only %d ICA components from %d channels.\n', ...
            ncomps_sub, length(CFG.ica_chans));
        
        [EEG, com] = pop_runica(EEG, 'icatype', CFG.ica_type, ...
            'extended', CFG.ica_extended, ...
            'chanind', CFG.ica_chans, ...
            'pca', ncomps_sub);
        
        
    elseif CFG.ica_ncomps ~= 0
        fprintf('Extracting mandatory number of %d ICA components from %d channels.\n', ...
            CFG.ica_ncomps, length(CFG.ica_chans));
        
        [EEG, com] = pop_runica(EEG, 'icatype', CFG.ica_type, ...
            'extended', CFG.ica_extended, ...
            'chanind', CFG.ica_chans, ...
            'pca', CFG.ica_ncomps);
        
        
    else
        fprintf('Let EEGLAB calculate the number of components to extract.\n')
        
        [EEG, com] = pop_runica(EEG, 'icatype', CFG.ica_type, ...
            'extended', CFG.ica_extended, ...
            'chanind', CFG.ica_chans);
    end
    
    EEG = eegh(com, EEG);
    
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    EEG = pop_editset(EEG, 'setname', [CFG.subject_name '_ICA.set']);
    EEG = pop_saveset( EEG, [CFG.subject_name '_ICA.set'] , CFG.dir_eeg);
        
    S.has_ICA(who_idx(isub)) = 1;
    writetable(S, EP.st_file)

end

fprintf('Done.\n')
