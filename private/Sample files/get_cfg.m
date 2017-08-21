function [CFG, S] = get_cfg(idx, S)

%% Read info for this subject and get file names and dirctories.
rootfilename    = which('get_cfg.m');
rootpath        = rootfilename(1:regexp(rootfilename,[filesep,'Analysis',filesep,'EEG',filesep,'get_cfg.m']));

CFG.dir_main = rootpath;

if nargin>0                
    CFG.subject_name  = char(S.Name(idx));
    CFG.dir_behavior  = [CFG.dir_main 'Logfiles/'];
    CFG.dir_raw       = [CFG.dir_main 'BDF/'];
    CFG.dir_raweye    = [CFG.dir_main 'EDF/'];
    CFG.dir_eeg       = [CFG.dir_main 'EEG/' CFG.subject_name filesep]; 
    CFG.dir_eye       = [CFG.dir_main 'EYE/' CFG.subject_name filesep]; 
    CFG.dir_tf        = [CFG.dir_main 'TF/' CFG.subject_name filesep]; 
    CFG.dir_filtbert  = [CFG.dir_main 'Filtbert/' CFG.subject_name filesep];    
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

%remove epochs, that contain the target-trigger but not all of the triggers
%specified here. Currently this can result in problems with the
%coregistration of behavioral data.
CFG.trig_omit_inv = [] ;

% Optional: If you are using the file-io in WM-utilities, you might want to
% use ONLY triggers from the PC or ONLY triggers from the ViewPixx. To
% delete epochs of one of the devices prior to epoching, specify the
% to-be-kept device here.
% This is *very specific to out lab*. So you can probably leave it
% empty (default).
CFG.trigger_device = []; % can be [],'lowbyte-PC' or 'highbyte-VPixx'

% Did you use online-eyetracking to mark bad trials in your logfile?
% specify the fieldname of the field in your logfile struct that contains
% this information. Check func_importbehavior for more information.
CFG.badgaze_fieldname = 'badgaze';

% Do you want to check the latencies of specific triggers within each
% epoch?
CFG.checklatency=[];
CFG.allowedlatency = 3;
% Do you want to delete trials that differ by more than CFG.allowedlatency ms
% from the median latency AFTER coregistration with behavoral data?
CFG.deletebadlatency = 0;
%% Parameters for data import and preprocessing.

% Indices of channels that contain data, including external electrodes, but not bipolar channels like VEOG, HEOG.
CFG.data_urchans = [1:64,69];%[1,3:15,17:50,52:63]; 

% Indices of channels that contain data after rejecting the channels not
% selected in CFG.data_urchans. 
CFG.data_chans   = 1:length(CFG.data_urchans);

% Use these channels for computing bipolar HEOG and VEOG channel.
CFG.heog_chans = [2 51];
CFG.veog_chans = [42 65];

% Channel location file. If you use your own custom file, you have to
% provide the full path and filename.
CFG.chanlocfile = 'Custom_M34_V3_Easycap_Layout_EEGlab.sfp';%standard-10-5-cap385.elp'; %This is EEGLAB's standard lookup table.

% Do you want to rereference the data at the import step (recommended)?
% Since Biosemi does not record with reference, this improves signal
% quality. This does not need ot be the postprocessing refrence you use for
% subsequent analyses.
CFG.do_preproc_reref    = 1;
CFG.preproc_reference   = 30; % (31=Pz@Biosemi,32=Pz@CustomM43Easycap)
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

% Do you want to use a notch filter? Note that in most cases Cleanline
% should be sufficient.
CFG.do_notch_filter = 0;
CFG.notch_filter_lower = 49;
CFG.notch_filter_upper = 51;

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

%% Eyelink related input
% Do you want to coregister eyelink eyetracking data?
CFG.coregister_Eyelink = 0; %0=don't coregister
% Do you want to use Eyetracking data instead of HEOG & VEOG for ICA?
CFG.eye_ica            = 1;

% Only if CFG.eye_ica is activated, you can opt to use an additional column
% in Your EP-Excel sheet that is 1 for subjects where eyetracking data
% should be used for ICA component selection and 0 for those where EOG
% should be used instead. This makes sense, when Eyetracking data are very
% noisy.
CFG.eye_ica_useEP      = 1;

% Coregistration is done by using the first instance of the first value and
% the last instance of the second value. Everything inbetween is downsampled
% and interpolated. In our lab triggers from the parallel port are s
CFG.eye_startEnd       = [];

% After data has been coregistered, eyetracking data will be included in
% the EEG struct. Do you want to keep the eyetracking-only files (ASCII &
% mat)?
CFG.eye_keepfiles      = [0 0];


%% Parameters for ICA.
CFG.ica_type = 'binica';
CFG.ica_extended = 1; % Run extended infomax ICA?
CFG.ica_chans = CFG.data_chans; % Typicaly, ICA is computed on all channels, unless one channel is not really EEG.
CFG.ica_ncomps = 65; %[numel(CFG.data_chans)-3]; % if ica_ncomps==0, determine data rank from the ...
% data (EEGLAB default). Otherwise, use a fixed number of components. Note: subject-specific
% settings will override this parameter.

%% Parameters for SASICA.
CFG.sasica_heogchan = num2str(CFG.data_chans+1);
CFG.sasica_veogchan = num2str(CFG.data_chans+2);
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
CFG.tf_verbose     = 'off'; % if not specified: overwritten by EP.verbose
