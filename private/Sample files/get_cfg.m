function [CFG, S] = get_cfg(idx, S)
% This function contains (almost) all parameters necessary to change EEG
% data preprocessing in any desired direction. Make sure to check *each 
% single option* in this function.

%% ------------------------------------------------------------------------
% Read info for this subject and get file names and dirctories.
% -------------------------------------------------------------------------
rootfilename    = which('get_cfg.m');
rootpath        = rootfilename(1:regexp(rootfilename,...
    [filesep, 'Analysis', filesep, 'EEG', filesep, 'get_cfg.m']));

CFG.dir_main = rootpath;

if nargin>0                
    CFG.subject_name  = char(S.Name(idx));
    CFG.dir_behavior  = [CFG.dir_main 'Logfiles' filesep];
    CFG.dir_raw       = [CFG.dir_main 'BDF' filesep];
    CFG.dir_raweye    = [CFG.dir_main 'EDF' filesep];
    CFG.dir_eeg       = [CFG.dir_main 'EEG' filesep CFG.subject_name filesep]; 
    CFG.dir_eye       = [CFG.dir_main 'EYE' filesep CFG.subject_name filesep]; 
    CFG.dir_tf        = [CFG.dir_main 'TF' filesep CFG.subject_name filesep]; 
    CFG.dir_filtbert  = [CFG.dir_main 'Filtbert' filesep CFG.subject_name filesep];    
end

%% ------------------------------------------------------------------------
% Data organization and content.
% -------------------------------------------------------------------------
% For GLM modelling with the unfold toolbox, you need continuous data.
CFG.keep_continuous = false;

% Triggers that mark stimulus onset. These events will be used for
% epoching. In case of unfold-pipe, these are just pseudo-epochs, that will
% only be used for coregistration with behavioral data and subsequently be
% deleted.
CFG.trig_target = []; %e.g., [21:29, 200:205]
CFG.epoch_tmin  = []; %e.g., -2.000
CFG.epoch_tmax  = []; %e.g., 0.500

% If you already removed faulty trials (e.g., when a subject looked away) 
% from your logfile, then the amount of trials in the logfile does not 
% match the amount of trials in the EEGdata. If you sent special triggers 
% that mark faulty trials in the EEGdata, enter them here to remove all 
% epochs containing these triggers from your EEGdata. The result should be 
% that EEGdata and Logfile match again.
% NOTE: See below for unfold/GLM/continuous (CFG.trig_trial_onset)
CFG.trig_omit = [];

% you may also want to delete just a few specific trials; e.g., the training
% trials at the beginning. Be cautios, this omits trials solely in EEG and may
% result in different trial orders in logfiles and EEG. Only use this parameter
% to delete trials that are in the EEG but not in the logfiles.
CFG.trial_omit  = [];

% remove epochs, that contain the target-trigger but not all of the triggers
% specified here. Currently this can result in problems with the
% coregistration of behavioral data. So think about what you're doing!
CFG.trig_omit_inv_mode = 'AND'; % 'AND' or 'OR'. Should trials that do not include all of these triggers (AND) or trials that do not include any of these triggers be removed?
CFG.trig_omit_inv = [] ;

% Optional: If you are using the file-io in WM-utilities, you might want to
% use ONLY triggers from the PC or ONLY triggers from the ViewPixx. To
% delete epochs of one of the devices prior to epoching, specify the
% to-be-kept device here.
% This is *very specific to out lab*.
CFG.trigger_device = 'lowbyte-PC'; % can be [],'lowbyte-PC' or 'highbyte-VPixx'

% Did you use online-eyetracking to mark bad trials in your logfile?
% specify the fieldname of the field in your logfile struct that contains
% this information. Check func_importbehavior for more information.
CFG.badgaze_fieldname = '';

% Do you want to check the latencies of specific triggers within each
% epoch?
CFG.checklatency=[];
CFG.allowedlatency = 3;

% Do you want to delete trials that differ by more than CFG.allowedlatency ms
% from the median latency AFTER coregistration with behavoral data?
CFG.deletebadlatency = 0;

% For GLM modelling with the unfold toolbox, the trigger and/or
% latency-based rejections specified above will not make sense (continuous
% data!). You can, however, specify a trigger that defines the trial onset 
% (usually that's earlier than your target onset). The program will use all
% sampling points between a trig_target and the preceding + following 
% trig_trial_onset (which should equal the complete trial). It will then 
% create a matrix of rejected trials' latencies in 
% (CONT)EEG.uf_rej_latencies. This does currently not take care of 
% artifacts detected other than with trigger or latency. You *can* use 
% this later in unfold with, e.g., uf_continuousArtifactExclude.m
CFG.trig_trial_onset = [];

%% ------------------------------------------------------------------------
% Parameters for data import and preprocessing.
% -------------------------------------------------------------------------

% Indices of channels that contain data, including external electrodes, 
% but not bipolar channels like VEOG, HEOG.
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
% quality. This does not need to be the postprocessing refrence you use for
% subsequent analyses.
CFG.do_preproc_reref    = 1;
CFG.preproc_reference   = []; % (31=Pz@Biosemi,32=Pz@CustomM43Easycap);  'robust' for robust average. Requires PREP extension & fix in line 102 of performReference.m (interpoled -> interpolated; already filed as issue on github)
% usually, the preproc reference is kept
CFG.postproc_reference  = []; % empty = average reference

% Do you want to have a new sampling rate?
CFG.do_resampling     = 1;
CFG.new_sampling_rate = 512;

% Do you want to high-pass filter the data?
% You can optionally choose to apply an extreme high-pass filter to
% calculate ICA weights and apply them to your less-extreme high-pass
% filtered data. For the ICA-related high-pass filter, see below.
CFG.do_hp_filter = 1;
CFG.hp_filter_type = 'eegfiltnew'; % or 'butterworth', 'eegfiltnew' or kaiser - not recommended
CFG.hp_filter_limit = 0.1; 
CFG.hp_filter_tbandwidth = 0.2;% only used for kaiser
CFG.hp_filter_pbripple = 0.01;% only used for kaiser

% Do you want to low-pass filter the data?
CFG.do_lp_filter = 1;
CFG.lp_filter_limit = 100; 
CFG.lp_filter_tbandwidth = 5;

% Do you want to notch-filter the data? (Cleanline should be sufficient in most cases)
CFG.do_notch_filter = 0;
CFG.notch_filter_lower = 49;
CFG.notch_filter_upper = 51;

% Do you want to use cleanline to remove 50Hz noise?
CFG.do_cleanline = 1;

% Do you want to use linear detrending (requires Andreas Widmann's
% function).?
CFG.do_detrend = 0;

%% Artifact detection parameters
% set all the CFG.do_rej_* to 0 to deactivate automatic artifact
% detection/rejection.

% In case you use automatic artifact detection, do you want to
% automatically delete detected trials or inspect them after deletion?
CFG.rej_auto = 0;

% Do you want to reject trials based on amplitude criterion? (automatic and
% manual)
CFG.do_rej_thresh   = 1;
CFG.rej_thresh      = 450;
CFG.rej_thresh_tmin = CFG.epoch_tmin;
CFG.rej_thresh_tmax = CFG.epoch_tmax;

% Do you want to reject trials based on slope?
CFG.do_rej_trend       = 0;
CFG.rej_trend_winsize  = CFG.new_sampling_rate * abs(CFG.epoch_tmin - CFG.epoch_tmax);
CFG.rej_trend_maxSlope = 30;
CFG.rej_trend_minR     = 0; %0 = just slope criterion

% Do you want to reject trials based on joint probability?
CFG.do_rej_prob         = 1;
CFG.rej_prob_locthresh  = 7;
CFG.rej_prob_globthresh = 4; 

% Do you want to reject trials based on kurtosis?
CFG.do_rej_kurt         = 0;
CFG.rej_kurt_locthresh  = 6;
CFG.rej_kurt_globthresh = 3; 

% The SubjectsTable.xlsx contains a column "interp_chans". Do you want to
% interpolate these channels in prep02 (i.e., prior to ICA)?
CFG.do_interp = 0;

% ...If not interpolating, do you want to ignore those channels in
% automatic artifact detection methods? 1 = use only the other channels.
CFG.ignore_interp_chans = 1;

%% Eyelink related input
% Do you want to coregister eyelink eyetracking data?
CFG.coregister_Eyelink = 1; %0=don't coregister
% Do you want to use Eyetracking data instead of HEOG & VEOG for ICA?
% WARNING: currently this only suggests to use one of the EYE-channels in
% SASICA. I suggest using EYE-ICA instead (see below)
CFG.eye_ica            = 0;

% Select occular ICs based on ET-data? requires EYE-ICA in a recent
% (github, not plugin-manager) version, and EEGLab>v.14.1
CFG.eyetracker_ica           = 1;
CFG.eyetracker_ica_varthresh = 1.1; % variance ratio threshold
CFG.eyetracker_ica_sactol    = [5 10]; % Extra temporal tolerance around saccade onset and offset
CFG.eyetracker_ica_feedback  = 1; % do you want to see plots of (1) all selected bad components (2) all good (3) bad & good or (4) no plots?

% Only if CFG.eye_ica is activated, you can opt to use an additional column
% in Your EP-Excel sheet that is 1 for subjects where eyetracking data
% should be used for ICA component selection and 0 for those where EOG
% should be used instead. This makes sense, when Eyetracking data are very
% noisy.
CFG.eye_ica_useEP      = 0;

% Coregistration is done by using the first instance of the first value and
% the last instance of the second value. Everything inbetween is downsampled
% and interpolated.
CFG.eye_startEnd       = []; e.g., [10,20]

% After data has been coregistered, eyetracking data will be included in
% the EEG struct. Do you want to keep the eyetracking-only files (ASCII &
% mat)?
CFG.eye_keepfiles      = [0 0];


%% Parameters for ICA.
CFG.ica_type = 'binica';
CFG.ica_extended = 1; % Run extended infomax ICA?
CFG.ica_chans = CFG.data_chans; % Typicaly, ICA is computed on all channels, unless one channel is not really EEG.
CFG.ica_ncomps = numel(CFG.data_chans)-3; % if ica_ncomps==0, determine data rank from the ...
% data (EEGLAB default). Otherwise, use a fixed number of components. Note: subject-specific
% settings will override this parameter.

% Do you want to do an extra run of high-pass filtering before ICA (i.e., after segmentation)?
% see Olaf Dimigen's OPTICAT.
% The data as filtered below are only used to compute the ICA. The
% activation is then reprojected to the original data filtered as indicated
% above in the section 'filters'.
CFG.do_ICA_hp_filter = 1;
CFG.hp_ICA_filter_type = 'eegfiltnew'; % 'butterworth' or 'eegfiltnew' or kaiser - not recommended
CFG.hp_ICA_filter_limit = 2.5; 
CFG.hp_ICA_filter_tbandwidth = 0.2;% only used for kaiser
CFG.hp_ICA_filter_pbripple = 0.01;% only used for kaiser

% Olaf Dimigen recommends to overweight spike potentials using his OPTICAT
% approach. Do you want to do this prior to computung ICA?
CFG.ica_overweight_sp = 1;
CFG.opticat_saccade_before = -0.02; % time window to overweight (-20 to 10 ms)
CFG.opticat_saccade_after = 0.01;
CFG.opticat_ow_proportion = 0.5; % overweighting proportion
CFG.opticat_rm_epochmean = true; % subtract mean from overweighted epochs? (recommended)

% if CFG.keep_continuous is true, should ICA weights be backprojected to
% the continuous data?
CFG.ica_continuous = 0;

% if CFG.keep_continuous and CFG.ica_continuous are true, do you want to
% remove components from epoched data only ('epoch') or continuous data only 
% ('cont', default)? 
CFG.ica_rm_continuous = 'epoch'; % if you want to do both, simply change this line and run prep04 again.


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
% Note: In case you want to store the single trial data as well, you can specify a subset of time, frequency, and/or channels below
CFG.tf_chans       = CFG.data_chans;
CFG.tf_freqlimits  = [2 40];
CFG.tf_nfreqs      = 20;
CFG.tf_freqsout    = CFG.tf_freqlimits; %use this to specify specific frequencies and overwrite the combination of nfreqs, scale and limits
CFG.tf_cycles      = [1 6];
CFG.tf_causal      = 'off';
CFG.tf_freqscale   = 'log';
CFG.tf_ntimesout   = 400;
CFG.tf_verbose     = 'off'; % if not specified: overwritten by EP.verbose

%% TF single-trial analysis (leave empty if you do not want a subset of the specs above)
CFG.single.tf_chans       = []; %cell with characters or vector with indeces
CFG.single.tf_freqlimits  = []; %in Hz
CFG.single.tf_timelimits  = []; %in seconds

%% FFT analysis
CFG.fft_chans   = CFG.data_chans;
CFG.fft_npoints = 'auto'; %npoints as in niko busch's 'my_fft' can be 'auto', meaning N = raw datapoints
CFG.fft_time    = [2000, 2500]; %in ms
CFG.fft_timedim = 'auto'; %usually auto is fine. will warn you if that doesn't work.
CFG.fft_chandim = 'auto'; %usually auto is fine. will warn you if that doesn't work.
CFG.fft_srate   = 'auto'; %usually auto is fine. will warn you if that doesn't work.
CFG.fft_returncomplex = 0;
CFG.fft_dobsl   = 1; %run basline subtraction? if 1, needs bsltime in seconds.
CFG.fft_bsltime = [1000, 1500]; %in ms
CFG.fft_bslnpoints = 'auto';
CFG.fft_verbose = 'on'; % if not specified: overwritten by EP.verbose

%% FFT single-trial analysis
CFG.single.fft_chans = [];%[13:32, 56:64]; %cell with characters or vector with indeces
CFG.single.fft_time  = [];%[1, 3];
end
