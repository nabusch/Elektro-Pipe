function prep03_runICA(EP)

[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

EP.S = readtable(EP.st_file);

who_idx = get_subjects(EP);

for isub=1:length(who_idx)
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['ALLCFG{',num2str(isub),'} = ' cfg_name '(' num2str(who_idx(isub)) ', EP.S);'];
    eval(evalstring);
end
    
%par
for isub = 1:length(who_idx)
    
    EEG = [];
    CFG = ALLCFG{isub};
    % --------------------------------------------------------------
    % Prepare data.
    % --------------------------------------------------------------
    
    % Write a status message to the command line.
    fprintf('\nNow processing subject %s, (number %i of %i).\n\n', ...
        CFG.subject_name, isub, length(who_idx));
    
    % Load data set.
    EEG = pop_loadset('filename', [CFG.subject_name '_CleanBeforeICA.set'] , ...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
    
    % assure that data is in double precision (this enhances ICA power)
    if ~isa(EEG.data,'double')
        fprintf('\nFound single precision data. Will convert to double precision for ICA...\n');
        EEG.data = double(EEG.data);
    end

    % If wanted, use extra high-pass filter to enhance ICA results
    % see, e.g., here: https://sccn.ucsd.edu/wiki/Makoto%27s_preprocessing_pipeline#High-pass_filter_the_data_at_1-Hz_.28for_ICA.2C_ASR.2C_and_CleanLine.29.2803.2F29.2F2017_updated.29
    if CFG.do_ICA_hp_filter
        % make a backup of the original data. We'll only save the ICA
        % weights produced with the hp-filtered data.
        nonhpEEG = EEG;
        switch(CFG.hp_ICA_filter_type)
            
            case('butterworth') % This is a function of the separate ERPlab toolbox.
                [EEG, com] = pop_ERPLAB_butter1(...
                    EEG, CFG.hp_ICA_filter_limit, 0, 5); % requires ERPLAB plugin
                EEG = eegh(com, EEG);
                
            case('kaiser')
                m = pop_firwsord('kaiser', EEG.srate,...
                    CFG.hp_ICA_filter_tbandwidth, CFG.hp_ICA_filter_pbripple);
                beta = pop_kaiserbeta(CFG.hp_ICA_filter_pbripple);
                
                [EEG, com] = pop_firws(EEG, 'fcutoff', CFG.hp_ICA_filter_limit, ...
                    'ftype', 'highpass', 'wtype', 'kaiser', ...
                    'warg', beta, 'forder', m);
                EEG = eegh(com, EEG);
            case('eegfiltnew')
                [EEG, com] = pop_eegfiltnew(...
                    EEG, CFG.hp_ICA_filter_limit, [], [], 0, [], 0);
                EEG = eegh(com, EEG);
        end
    end
    
    % overweight brief saccade intervals containing spike potentials (see Dimigen's OPTICAT)
    if CFG.ica_overweight_sp
        EEG = pop_overweightevents(EEG, 'saccade',...
            CFG.opticat_saccade_window, CFG.opticat_ow_proportion,...
            CFG.opticat_rm_epochmean);
    end
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
    
    %create a subfolder for the temporary binica files, in case binica is used
    if strcmp(CFG.ica_type,'binica')
        mkdir([CFG.dir_eeg 'binica']);
        cd([CFG.dir_eeg 'binica']);
    end
    
    ncomps_sub = EP.S.ica_ncomps(who_idx(isub));
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
    
    %copy weight & sphere to original data
    if CFG.do_ICA_hp_filter
        nonhpEEG.icaweights = EEG.icaweights;
        nonhpEEG.icasphere = EEG.icasphere;
        nonhpEEG.icachansind = EEG.icachansind;
        EEG = nonhpEEG;
        EEG = eeg_checkset(EEG); %let EEGLAB re-compute EEG.icaact & EEG.icawinv
    end
    
    EEG = eegh(com, EEG);
    
    %in case binica has been used, cd back to the main folder and delete
    %binica folder
    if strcmp(CFG.ica_type,'binica')
        cd(CFG.dir_main);
        rmdir([CFG.dir_eeg 'binica'],'s');
    end
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    EEG = pop_editset(EEG, 'setname', [CFG.subject_name '_ICA.set']);
    EEG = pop_saveset( EEG, [CFG.subject_name '_ICA.set'] , CFG.dir_eeg);
    
    % If config says so, copy weights to continuous dataset
    if CFG.ica_continuous
        disp('Copying weights to continuous data...')
        % load continuous data
        CONTEEG = pop_loadset('filename',...
            [CFG.subject_name '_CleanBeforeICACONT.set'] , ...
            'filepath', CFG.dir_eeg, 'loadmode', 'all');
        
        % copy weights
        CONTEEG.icaweights = EEG.icaweights;
        CONTEEG.icasphere = EEG.icasphere;
        CONTEEG.icachansind = EEG.icachansind;
        CONTEEG = eeg_checkset(CONTEEG); %let EEGLAB re-compute EEG.icaact & EEG.icawinv
        
        % and save this as well
        CONTEEG = pop_editset(CONTEEG, 'setname',...
            [CFG.subject_name '_ICACONT.set']);
        CONTEEG = pop_saveset(CONTEEG,...
            [CFG.subject_name '_ICACONT.set'] , CFG.dir_eeg);
    end
end

EP.S.has_ICA(who_idx) = 1;
writetable(EP.S, EP.st_file)

fprintf('Done.\n')

end