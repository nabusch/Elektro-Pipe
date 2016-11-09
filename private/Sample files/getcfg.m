function [CFG, S] = getcfg(idx, S)

%% Read info for this subject and get file names and dirctories.
CFG.dir_main  = ''; %e.g., '/data/ExperimentName/

if nargin>0                
    
    CFG.subject_name = char(S.Name(idx));
            
    CFG.dir_behavior  = [CFG.dir_main 'Logfiles/'];
    CFG.dir_raw       = [CFG.dir_main 'BDF/'];
    CFG.dir_eeg       = [CFG.dir_main 'EEG/' CFG.subject_name '/']; 
    CFG.dir_tf        = [CFG.dir_main 'TF/' CFG.subject_name '/']; 
    CFG.dir_filtbert  = [CFG.dir_main 'Filtbert/' CFG.subject_name '/'];    
end

%% Data organization and content.

% Triggers that mark stimulus onset. These events will be used for
% epoching.
CFG.trig_target = []; %e.g., [21:29 221:229]; 
CFG.epoch_tmin  = []; %e.g., -2.000;
CFG.epoch_tmax  = []; %e.g., 0.500;

% Time limits of epochs.
CFG.bsl_t_min = CFG.epoch_tmin;
CFG.bsl_t_max = 0; 

% If you already removed faulty trials (e.g., when a subject looked away) from your logfile,
% then the amount of trials in the logfile does not match the amount of trials in the EEGdata.
% If you sent special triggers that mark faulty trials in the EEGdata, enter them here to remove
% all trials containing these triggers from your EEGdata. The result should be that EEGdata and
% Logfile match again.
CFG.trig_omit = [];

% you may also want to delete just a few specific trials; e.g., the training
% trials at the beginning
CFG.trial_omit  = [];

% Optional: If you are using the file-io in WM-utilities, you might want to
% use ONLY triggers from the PC or ONLY triggers from the ViewPixx. To
% delete epochs of one of the devices prior to epoching, specify the
% to-be-used device here.
% This is *very specific to out lab*. So you can probably leave it
% empty (default).
CFG.trigger_device = []; % can be [],'lowbyte-VPixx' or 'highbyte-PC'

% Did you use online-eyetracking to mark bad trials in your logfile?
% specify the fieldname of the field in your logfile struct that contains
% this information. Check func_importbehavior for more information.
CFG.badgaze_fieldname = 'badgaze';
%% Parameters for data import and preprocessing.

% Indices of channels that contain data, including external electrodes, but not bipolar channels like VEOG, HEOG.
CFG.data_chans = 1:69; 

% Use these channels for computing bipolar HEOG and VEOG channel.
CFG.heog_chans = [67 68];
CFG.veog_chans = [1  69];

% Channel location file. If you use your own custom file, you have to
% provide the full path and filename.
CFG.chanlocfile = 'standard-10-5-cap385.elp'; %This is EEGLAB's standard lookup table.

% Do you want to rereference the data at the import step (recommended)?
% Since Biosemi does not record with reference, this improves signal
% quality. This does not need ot be the postprocessing refrence you use for
% subsequent analyses.
CFG.do_preproc_reref    = 1;
CFG.preproc_reference   = 31; % (31=Pz)
CFG.postproc_reference  = []; % empty = average reference

% Do you want to have a new sampling rate?
CFG.do_resampling     = 1;
CFG.new_sampling_rate = 512;

% Do you want to high-pass filter the data?
CFG.do_hp_filter = 1;
CFG.hp_filter_type = 'kaiser'; % or 'butterworth' - not recommended
CFG.hp_filter_limit = 0.5; 
CFG.hp_filter_tbandwidth = 0.2;
CFG.hp_filter_pbripple = 0.01;

% Do you want to low-pass filter the data?
CFG.do_lp_filter = 1;
CFG.lp_filter_limit = 100; 
CFG.lp_filter_tbandwidth = 5;

% Do you want to use cleanline to remove 50Hz noise?
CFG.do_cleanline = 1;

% Do you want to use linear detrending (requires Andreas Widmann's
% function).?
CFG.do_detrend = 0;

% Do you want to reject trials based on amplitude criterion? 
CFG.do_rej_thresh   = 1;
CFG.rej_thresh      = 500;
CFG.rej_thresh_tmin = CFG.epoch_tmin;
CFG.rej_thresh_tmax = CFG.epoch_tmax;

%% Parameters for ICA.
CFG.ica_type = 'runica';
CFG.ica_extended = 1; % Run extended infomax ICA?
CFG.ica_chans = CFG.data_chans; % Typicaly, ICA is computed on all channels, unless one channel is not really EEG.
CFG.ica_ncomps = 65; %[numel(CFG.data_chans)-3]; % if ica_ncomps==0, determine data rank from the ...
% data (EEGLAB default). Otherwise, use a fixed number of components. Note: subject-specific
% settings will override this parameter.

%% Parameters for SASICA.
CFG.sasica_heogchan = '70';
CFG.sasica_veogchan = '71';
CFG.sasica_autocorr = 20;
CFG.sasica_focaltopo = 'auto';

%% Stuff below this line is for experiment-specific analyses.

%% Hilbert-Filter anaylsis
CFG.hilb_flimits       = [5 12];
CFG.hilb_transbwidth   = 2;
CFG.hilb_quant_tlimits = [-0.800 0];
CFG.hilb_quant_chans   = [1:64];
CFG.hilb_quant_nbins   = 2;

%% TF analysis
CFG.tf_chans       = CFG.data_chans;
CFG.tf_freqlimits  = [2 40];
CFG.tf_nfreqs      = 20;
% CFG.tf_freqsout    = linspace(CFG.tf_freqlimits(1), CFG.tf_freqlimits(2), CFG.tf_nfreqs);
CFG.tf_cycles      = [1 6];
CFG.tf_causal      = 'off';
CFG.tf_freqscale   = 'log';
CFG.tf_ntimesout    = 400;
CFG.tf_verbose     = 'off';