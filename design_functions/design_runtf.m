function TF = design_runtf(EP)
% TF = DESIGN_RUNTF(EP)
%
% Compute a time frequency analysis for all conditions specified in EP.
% The function computes for every subject a struct "TF"
% containing a freqs x times x channels struct for power and phase locking
% for every condition of the design. So, results will be averaged across
% trials, we do not save single trials.
%
% This function uses the parallel computing toolbox, using as many cores as
% are physically present on your computer.
%
% Input:
% struct 'EP', as outlined in design_master. Uses the following fields:
% EP.who: Optional. can define which subjects to use. Default is all subjects.
% EP.design_idx: which designs specified in get_design. Default is all designs.
% EP.cfgfile: get_cfg.m that should be used
% EP.S: Table with processing information
% EP.D: result of get_design.m/design struct
% EP.filename_in: common suffix of files to be used as input
% EP.project_name: Name for the current adventure. e.g., 'ER-TFA'
% EP.verbose: massive debugging output or not.
% EP.dir_out: master-folder in which subfolders per design will be saved.
%
% Written by Niko Busch (niko.busch@wwu.de)
% and adjusted for parallel computing and use in Elektro-Pipe by
% Wanja Moessing (moessing@wwu.de). University of Muenster - Dec 6, 2016

%% Decode which subjects to process.
if ~isfield(EP, 'who')
    EP.who = [];
end
subjects_idx = get_subjects(EP);

%% Decode which designs to process.
if ~isfield(EP, 'design_idx') || isempty(EP.design_idx)
    EP.design_idx = 1:length(EP.D); %default = all designs
end
%% First load a subjects data and then compute all designs for it
for isub = 1:length(subjects_idx)
    
    fprintf(['\n-----------------------------------------\n',...
        'design_runtf: Now processing subject %i of %i\n',...
        '-----------------------------------------\n'],...
        isub,length(subjects_idx));
    
    tic; %store runtime in TF later
    %--------------------------------------------------------------
    % Load this subject's EEG data.
    %--------------------------------------------------------------
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    [pathstr,cfgname,ext] = fileparts(EP.cfgfile);
    addpath(pathstr)
    eval(['my_CFG = ' cfgname '(' num2str(subjects_idx(isub)) ', EP.S);']);
    CFG = my_CFG; %this is necessary to make CFG 'unambiguous in this context'
    
    subject_names{isub} = [CFG.subject_name EP.filename_in '.set'];
    
    EEG = pop_loadset('filename', [CFG.subject_name EP.filename_in '.set'] , ...
        'filepath', CFG.dir_eeg);

    %don't reference Eye-channels & *EOG to EEG-reference
    Eyechans = find(strcmp('EYE',{EEG.chanlocs.type}));
    BipolarChans = find(ismember({EEG.chanlocs.labels},{'VEOG','HEOG'}));
    EEG = pop_reref( EEG, CFG.postproc_reference, 'keepref','on','exclude',[BipolarChans, Eyechans]);
    
    %% loop over designs
    for idesign = 1:length(EP.design_idx)
        thisdesign = EP.design_idx(idesign);
        fprintf(['\n-----------------------------------------\n',...
            'design_runtf: Now running design %i of %i (i.e., D(%i)) for subject %i of %i\n',...
            '-----------------------------------------\n'],...
            idesign,length(EP.design_idx),thisdesign,isub,length(subjects_idx));
        DINFO = get_design_matrix(EP.D(thisdesign));
        DINFO.design_idx = thisdesign;
        DINFO.design_name = [EP.project_name '_D' num2str(thisdesign)];
        %--------------------------------------------------------------
        % Compose the file names of all conditions in this design.
        %--------------------------------------------------------------
        [condition_names] = get_condition_names(EP.D(thisdesign), DINFO);
        
        
        %--------------------------------------------------------------
        % Extract relevant trials for each condition.
        %--------------------------------------------------------------
        [condinfo] = get_design_trials(EEG, EP, DINFO);
        
        
        %--------------------------------------------------------------
        % Run TF analysis once across all trials.
        %--------------------------------------------------------------
        nchans = length(CFG.tf_chans);
        nconds = length(DINFO.design_matrix);
        
        %--------------------------------------------------------------
        % to do this in a parallel loop and still be consistent with the way later
        % functions expect the data, we need to create a temporary struct 'C' and
        % reconstruct 'TF' after the parfor loop.
        %--------------------------------------------------------------
        %check if a parallel-pool is enabled. If not, create a pool on
        %local with the maximum available cores. This might not run on
        %older versions of Matlab.
        try
            N_physical_cores = feature('numCores');
            p = gcp('nocreate');
            if isempty(p)
                if EP.verbose
                    fprintf('\nStarting a parallel-pool on ''local'' using %i cores\n',N_physical_cores);
                end
                parpool('local',N_physical_cores);
            end
        catch ME
            fprintf(2,'Starting a parallel-pool failed. This could be due to an old version of Matlab.\nThe error message was:\n');
            rethrow(ME);
        end
        %-----------------------------------------------------------------
        % CFG.tf_verbose should be preferred over EP.verbose. In case no
        % CFG.tf_verbose is set, set it automatically
        %-----------------------------------------------------------------
        useEPverbose = true;
        if isfield(CFG,'tf_verbose')
            if any(strcmpi(CFG.tf_verbose,{'on','off'}))
                useEPverbose = false;
            end
        end
        
        if useEPverbose
            switch EP.verbose
                case 1
                    CFG.tf_verbose = 'on';
                case 0
                    CFG.tf_verbose = 'off';
            end
        end
        
        %-----------------------------------------------------------
        % the actual TF-parfor. Processes N_Physical_cores channels
        % simultaneously
        %-----------------------------------------------------------
        parfor ichan = 1:nchans
            if strcmp(CFG.tf_verbose,'on')
                fprintf('\nComputing TF for channel %d ', ichan)
            end
            thischan = CFG.tf_chans(ichan);
            [tf, tffreqs, tftimes, wavelet, freqresol, timeresol] = runtf(EEG, CFG, thischan);
            
            %--------------------------------------------------------------
            % Run across conditions and extract tf data from appropriate
            % trials. We have to do this within the channel-loop so that we
            % can immediately overwrite the tf variable lest it gets to
            % huge.
            %--------------------------------------------------------------
            for icondition = 1:nconds
                
                trialidx = condinfo(icondition).trials;
                thistf   = tf(:,:,trialidx);
                C(ichan).TF(icondition).pow(:,:,ichan) = mean(abs(thistf).^2,3);
                C(ichan).TF(icondition).itc(:,:,ichan) = abs(mean(exp(angle(thistf) * sqrt(-1)),3));
                C(ichan).TF(icondition).times          = tftimes;
                C(ichan).TF(icondition).freqs          = tffreqs;
                C(ichan).TF(icondition).cycles         = CFG.tf_cycles;
                C(ichan).TF(icondition).freqsol        = freqresol;
                C(ichan).TF(icondition).timeresol      = timeresol;
                C(ichan).TF(icondition).wavelet        = wavelet;
                C(ichan).TF(icondition).old_srate      = EEG.srate;
                C(ichan).TF(icondition).new_srate      = 1/mean(diff(tftimes));
                C(ichan).TF(icondition).chanlocs       = EEG.chanlocs;
                C(ichan).TF(icondition).condition      = condition_names{icondition};
            end
        end
        fprintf('\n')
        
        %--------------------------------------------------------------
        %put TF back together (this could potentially be done in a more
        %compact way)
        %--------------------------------------------------------------
        for ichan=1:length(C)
            for icondition = 1:nconds
                TF(icondition).pow(:,:,ichan) = C(ichan).TF(icondition).pow(:,:,ichan);
                TF(icondition).itc(:,:,ichan) = C(ichan).TF(icondition).itc(:,:,ichan);
                TF(icondition).times          = C(ichan).TF(icondition).times;
                TF(icondition).freqs          = C(ichan).TF(icondition).freqs;
                TF(icondition).cycles         = C(ichan).TF(icondition).cycles;
                TF(icondition).freqsol        = C(ichan).TF(icondition).freqsol;
                TF(icondition).timeresol      = C(ichan).TF(icondition).timeresol;
                TF(icondition).wavelet        = C(ichan).TF(icondition).wavelet;
                TF(icondition).old_srate      = C(ichan).TF(icondition).old_srate;
                TF(icondition).new_srate      = C(ichan).TF(icondition).new_srate;
                TF(icondition).chanlocs       = C(ichan).TF(icondition).chanlocs;
                TF(icondition).condition      = C(ichan).TF(icondition).condition;
            end
        end
        clear C;
        
        %--------------------------------------------------------------
        % Save data
        %--------------------------------------------------------------
        runtime = toc;
        for i = 1:length(TF)
            TF(i).runtime = runtime;
        end
        
        savepath = [EP.dir_out filesep DINFO.design_name];
        if ~exist(savepath, 'dir')
            mkdir(savepath)
        end
        
        savefile = fullfile(savepath, [EP.project_name, '_',CFG.subject_name,'_D', num2str(DINFO.design_idx), '.mat']);
        
        save(savefile, 'TF');
        clear TF; 
    end
end
