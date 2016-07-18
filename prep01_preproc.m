function EEG = prep01_preproc(EP)

% Written by Niko Busch - WWU Muenster (niko.busch@gmail.com)
[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

S = readtable(EP.st_file);

who_idx = get_subjects(S, EP.who);


for isub = 1:length(who_idx)
    
    EEG = [];

    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['CFG = ' cfg_name '(' num2str(who_idx(isub)) ', S);'];
    eval(evalstring);
    
    
    % Write a status message to the command line.
    fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));    
    
    % Create output directory if necessary.
    if ~isdir(CFG.dir_eeg)
        mkdir(CFG.dir_eeg);
    end 

    
    % --------------------------------------------------------------
    % Import Biosemi raw data.
    % --------------------------------------------------------------
    bdfname = [CFG.dir_raw CFG.subject_name '.bdf'];
    if ~exist(bdfname)
        fprintf('%s Does not exists!\n', bdfname)
        return
    else
        fprintf('Importing %s\n', bdfname)
        EEG = pop_fileio(bdfname);
    end
    
    
    % --------------------------------------------------------------
    % Preprocessing (filtering etc.).
    % --------------------------------------------------------------
    EEG = func_prepareEEG(EEG, CFG, S, who_idx(isub));
    
    
    % --------------------------------------------------------------
    % Import behavioral data .
    % --------------------------------------------------------------
    EEG = func_importBehavior(EEG, CFG);   

    
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    [EEG, com] = pop_editset(EEG, 'setname', [CFG.subject_name ' import']);
    EEG = eegh(com, EEG);
    EEG = pop_saveset( EEG, [CFG.subject_name  '_import.set'] , CFG.dir_eeg);

    S.has_import(who_idx) = 1;
    writetable(S, EP.st_file)
    
end

fprintf('Done.\n')
