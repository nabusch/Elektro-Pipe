function [CFG] = elektro_prepconfigure()
% guided GUI to create a config file
%
% This function is supposed to make it easier for users to create a
% configuration for use with the elektro-pipe
% Simply call ELEKTRO_PREPCONFIGURE() and answer the questions.

CFG = struct();

%% general setup
CFG.dir_main = qtext('main_dir', '/Analysis/',...
    ['Please insert the main directory of your preprocessing analysis.',...
    ' Usually, that''s the folder you created with ElektroSetup().',...
    ' This folder should contain all your data in the folders ''BDF'', '...
    '''Logfiles'', and (if applicable)''EDF''.']);

%% prep01
CFG.trial_struct_name = qtext('Behavioral fieldname', 'Info.T',...
    ['The Elektro-Pipe is designed to coregister behavioral with EEG data.',...
    ' In our lab, we usually record a logfile for the behavioral data, ',...
    'which contains a structure with one row per trial and all information',...
    ' coded in the columns. EP will load all variables in the logfile and',...
    'search for this structure. Please indicate the structure''s name here.']);

CFG.keep_continuous = qbool(...
    ['Do you want to preprocess continuous '...
    'data? No means you''ll work with epochs only. Yes means your data will'...
    'still be epoched, but a continuous copy is dragged along. More '...
    'specifically, prep02 (detection of artefactual epochs) will be '...
    'applied to epoched data only; prep03 (ICA training) is based on epoched'...
    ' data and weights are then applied to the continuous data as well (as recommended'...
    ' by OPTICAT). Prep04 (IC removal) can selectively be applied to both,'...
    ' epoched and continuous data.'], 'keep_continuous');

[CFG.trig_target, CFG.epoch_tmin, CFG.epoch_tmax] = ...
    qtext('Epoch specs', {'30', '-1', '4.5'},...
    {'Please specify how to create epochs:\naround which trigger(s)?',...
    'how many seconds before those triggers?', '...and after?'});


[CFG.trig_omit, CFG.trig_omit_inv, CFG.trig_omit_inv_mode, CFG.trial_omit] = ...
    qtext('trig_omit', {'[]', '[]', 'AND', '[]'},...
    {['If you already removed faulty trials (e.g., when a subject looked away)'...
    'from your logfile, then the amount of trials in the logfile does not '...
    'match the amount of trials in the EEGdata. If you sent special triggers '...
    'that mark faulty trials in the EEGdata, enter them here to remove all '...
    'epochs containing these triggers from your EEGdata. The result should be '...
    'that EEGdata and Logfile match again.'],...
    ['remove epochs, that contain the target-trigger but not all of the triggers '...
    'specified here. Currently this can result in problems with the '...
    'coregistration of behavioral data. So think about what you''re doing!'],...
    ['''AND'' or ''OR''. Should trials that do not include all of these '...
    'triggers (AND) or trials that do not include any of these triggers be removed?'],...
    ['you may also want to delete just a few specific trials; e.g., the training '...
    'trials at the beginning. Be cautios, this omits trials solely in EEG and may '...
    'result in different trial orders in logfiles and EEG. Only use this parameter '...
    'to delete trials that are in the EEG but not in the logfiles.']});


CFG.trigger_device = qtext('16 bit trigger removal', 'lowbyte-PC',...
    ['Optional: If you are using the modified file-io to import BDF files, you might want to '...
    'use ONLY triggers from the PC or ONLY triggers from the ViewPixx. To '...
    'delete epochs of one of the devices prior to epoching, specify the '...
    'to-be-kept device here. This is *very specific to out lab*. '...
    'can be [], ''lowbyte-PC'' or ''highbyte-VPixx''']);


CFG.badgaze_fieldname = qtext('badgaze', '',...
    ['Did you use online-eyetracking to mark bad trials in your logfile? '...
    'Specify the fieldname of the field in your logfile struct that contains '...
    'this information. This can help to ignore trials that were aborted and'...
    ' then later repeated due to bad gaze behavior.']);


[CFG.checklatency, CFG.allowedlatency, CFG.deletebadlatency] = ...
    qtext('checklatency', {'[]', '5', '0'},...
    {'Do you want to check the latencies of specific triggers within each epoch?',...
    'How many ms latency jitter are allowed?',...
    ['Do you want to delete trials that differ by more than that '...
    'from the median latency AFTER coregistration with behavoral data?']});

CFG.trig_trial_onset = qtext('trig trial onset', '[]',...
    ['For GLM modelling with the unfold toolbox, the trigger and/or'...
    'latency-based rejections specified above will not make sense (continuous'...
    'data!). You can, however, specify a trigger that defines the trial onset'...
    '(usually that''s earlier than your target onset). The program will use all'...
    'sampling points between a trig_target and the preceding + following'...
    'trig_trial_onset (which should equal the complete trial). It will then'...
    'create a matrix of rejected trials'' latencies in'...
    '(CONT)EEG.uf_rej_latencies. This does currently not take care of'...
    'artifacts detected other than with trigger or latency. You *can* use'...
    'this later in unfold with, e.g., uf_continuousArtifactExclude.m']);


[CFG.data_urchans, CFG.data_chans, CFG.heog_chans, CFG.veog_chans, CFG.chanlocfile] =...
    qtext('Data channels', {'[1:64, 69]', '1:length(CFG.data_urchans)',...
    '[2 51]', '[42 65]', 'Custom_M34_V3_Easycap_Layout_EEGlab.sfp'},...
    {['Indices of channels that contain data, including external electrodes, '...
    'but not bipolar channels like VEOG, HEOG.'],...
    ['Indices of channels that contain data after rejecting the channels not '...
    'selected in CFG.data_urchans.'],...
    ['Use these channels for computing bipolar *H*EOG channel. (Indexes '...
    'refer to channels *after* rejecting unused channels as above. So deleting'...
    'channels 65:68 but keeping 69 makes 69 --> 65)'], '...and *V*EOG',...
    ['Channel location file. If you use your own custom file, you have to '...
    'provide the full path and filename.']});

if ischar(CFG.data_chans)
    CFG.data_chans = eval(CFG.data_chans);
end

[CFG.import_reference, CFG.do_preproc_reref, CFG.preproc_reference, CFG.postproc_reference] =...
    qtext('Referencing', {'[]', 'true', '[]', 'keep'},...
    {['Import reference: Biosemi raw data are reference free. Add any',...
    'reference directly after import, (e.g., a mastoid or other channel).',...
    'Otherwise the data will lose 40 dB of SNR! You can simply re-reference',...
    'later. Leave empty to use average of data_chans (recommended).'],...
    ['You can additionally rereference data towards the end of prep01. Here, you can'...
    'select whatever reference you like, including ''robust''.'...
    'This also does not need to be the postprocessing reference you use for '...
    'subsequent analyses.'], ['Preprocessing reference (applied in prep01; ',...
    '(31=Pz@Biosemi,32=Pz@CustomM43Easycap, []=average, ''robust'' for '...
    'robust average. The latter equires the PREP extension & a fix in line ',...
    '102 of performReference.m (interpoled -> interpolated; already filed as issue on github)'],...
    ['Files produced with the prep_* functions always store data with the '...
    'import/preproc ref. The functions called by the design_master rereference to the '...
    'postproc_reference. Can be ''keep'' to simply keep the preproc reference. '...
    'Currently only implemented in design_run_erp. Irrelevant for preprocessing.']});

[CFG.do_resampling, CFG.new_sampling_rate] = qtext('', {'false', '[]'},...
    {['Do you want to downsample during preprocessing? Due to a bug in eeglab, '...
    'downsampling prior to eyetracker-based IC selection via the EYE-ICA'...
    ' toolbox provides wrong results. So don''t resample here if you''re planning'...
    ' to do that.'], 'new sampling-rate'});

[foo, but] = settingsdlg('title', '(de-)activate filters',...
    'description', ['Please select the kinds of filters you want to ',...
    'apply during preprocessing. You will be asked configure the ',...
    'selected filters in the next screens. Also, you can optionally ',...
    'choose to apply an extreme high-pass filter to '...
    'calculate ICA weights and apply them to your less-extreme high-pass '...
    'filtered data. This ICA/OPTICAT high-pass filter can be configured '...
    'later in the ICA settings.'],...
    {'high-pass'; 'do_hp_filter'}, {'on', 'off'},...
    {'low-pass'; 'do_lp_filter'}, {'on', 'off'},...
    {'notch'; 'do_notch_filter'}, {'on', 'off'},...
    {'cleanline'; 'do_cleanline'}, {'off', 'on'},...
    {'linear detrending (A. Widmann)'; 'do_detrend'}, {'off', 'on'});
CFG = addfields(CFG, foo, but);

% config 4 high-pass
if CFG.do_hp_filter
    [foo, but] = settingsdlg('title', 'configure high-pass filter',...
        'description', ['please configure the high pass filter settings.'],...
        {'filter type'; 'hp_filter_type'}, {'eegfiltnew', 'butterworth', 'kaiser'},...
        {'filter limit (Hz)'; 'hp_filter_limit'}, '0.1',...
        {'transition bandwidth (only used for kaiser)'; 'hp_filter_tbandwidth'}, '0.2',...
        {'pass-band ripple (only used for kaiser)'; 'hp_filter_pbripple'}, '0.02');
    CFG = addfields(CFG, foo, but);
end

% config 4 low-pass
if CFG.do_lp_filter
    [foo, but] = settingsdlg('title', 'configure low-pass filter',...
        'description', ['please configure the low pass filter settings.',...
        ' This is currently always a blackman finite impulse response filter.'],...
        {'filter limit (Hz)'; 'lp_filter_limit'}, 45,...
        {'transition bandwidth'; 'lp_filter_tbandwidth'}, 5);
    CFG = addfields(CFG, foo, but);
end

% config 4 low-pass
if CFG.do_notch_filter
    [foo, but] = settingsdlg('title', 'configure notch filter',...
        'description', ['Please configure the notch filter settings.',...
        ' This is currently always a Hamming finite impulse response filter',...
        ' with a heuristic transition bandwidth (i.e. pop_eegfiltnew).'],...
        {'filter limit (Hz)'; 'notch_filter_lower'}, 49,...
        {'transition bandwidth'; 'notch_filter_upper'}, 51);
    CFG = addfields(CFG, foo, but);
end

%% Bad channel detection parameters
[foo, but] = settingsdlg('title', 'What to do with bad chanels?',...
    'description', ['This section covers bad channels. In the simplest ',...
    'case, you just want to interpolate the channels indicated in your ',...
    'Excel spreadsheet in the column ''interp_chans''. You can also opt to ',...
    'use the algorithms in the clean_rawdata plugin to detect flat and/or ',...
    'noisy channels. Note that this flat/noisy detection is redundant if you ',...
    'decide to run the complete clean_rawdata algorithm (next section). ',...
    'In fact, activating these filters here and activating clean_rawdata ',...
    'will throw an error. Moreover, all possible interpolations you can ',...
    'configure here will use spherical interpolation and happen before ',...
    'ICA. To account for the reduced data rank, ICA will automatically ',...
    'reduce the number of desired components by the number of interpolated ',...
    'channels.'],...
    {'interpolate anything?'; 'do_interp'}, {'yes', 'no'},...
    {'which types (spread = spreadsheet)'; 'interp_these'},...
    '''noisy'', ''spread'', ''flat''',...
    {'show plot (beta)'; 'interp_plot'}, {'yes', 'no'},...
    'separator', 'If not interpolating, do you want to',...
    'separator', 'ignore the channels in the column ',...
    'separator', '''interp_chans'' during automatic ',...
    'separator', 'artifact detection?',...
    {'ignore', 'ignore_interp_chans'}, {'yes', 'no'});
CFG = addfields(CFG, foo, but);
CFG.interp_these = strrep(strsplit(CFG.interp_these, ', '), '''','');


%% Artifact detection parameters

%% Artifact detection parameters
clean_rawdata_msg = ...
    ['EEGlab now ships with the fully automagic clean rawdata plugin as '...
    'the default artifact removal method. You can opt to use this method. As '...
    'it cleans the *raw*data, this obviously needs to happen in prep01, as '...
    'opposed to all other cleaning methods. Note that, by default, this '...
    'includes a 0.5Hz high-pass filter (kaiser FIR, can be changed in args, '...
    'see clean_drifts() & clean_artifacts()). '...
    'Note that they call it "raw"data, but several tutorials recommend first '...
    'cleaning line noise (via cleanline algo) and filtering. That''s the way '...
    'it''s implemented in Elektro-Pipe now: Cleanline -> filter -> clean_rawdata. '...
    'Clean_rawdata internally performs a reconstruction of the artifact '...
    'subspace ("ASR"; https://doi.org/10.1109/tbme.2015.2481482) based on PCA '....
    'ASR + ICA = supposed to be a good match. Generally, I found Makoto''s '...
    'Preprocessing pipeline linking to most relevant information on ASR. In '...
    'short, this happens:   '...
    '1. High-pass filter to remove drifts '...
    '2. Remove channels that are flat for more than 5s '...
    '3. Remove channels that are noisy (i.e., low correlation with adjacent channels) '...
    '4. Find the cleanest part of data (see algo in publication), use this as reference. '...
    '5. Using a moving window, compute PCA and compare window''s PCs to reference signal '...
    '6. Remove PCs that are more than N SD''s away from reference and reconstruct '...
    ' them (8 default, 20 "lax" criterion) '...
    '7. slide again, to detect windows that could not be repaired. '...
    '8. remove these windows (CAREFUL: this might crash behavioral/eyetrack '...
    'coregistration (if relevant events are deleted)! Therefore defaults to 1 ~ "off"). ',...
    'NOTE: you might want to exclude channels like IO1 from the interpolation step, ',...
    'as bad channel detection is based on correlation (IO1 likely does not have',...
    ' a strong correlation with ''surrorunding'' channels).'];


[foo, but] = settingsdlg('title', 'clean_rawdata',...
    'description', clean_rawdata_msg,...
    {'run clean_rawdata?', 'rej_cleanrawdata'}, {'no', 'yes'},...
    {'varargin to clean_artifacts() (no curly braces, just text)', 'rej_cleanrawdata_args'},...
    ['''WindowCriterion'', ''off'', ''LineNoiseCriterion'', ''off''',...
    '''ChannelCriterion'', ''0.75'', ''MaxMem'', 64000'],...
    {'interpolate removed channels?', 'rej_cleanrawdata_interp'}, {'no', 'yes'},...
    {'Channels that should not be interpolated', 'rej_cleanrawdata_dont_interp'}, 'IO1');
CFG = addfields(CFG, foo, but);
CFG.rej_cleanrawdata_args = eval(['{', CFG.rej_cleanrawdata_args, '}']);
if all(cellfun(@isempty, CFG.rej_cleanrawdata_args))
    CFG.rej_cleanrawdata_args = {};
end

[foo, but] = settingsdlg('title', 'automatic artifact detection',...
    'description',...
    ['You can combine any set of artifact detection methods. Look at the '...
    'eeglab documentation to find out what each of the algos does.'],...
    {'amplitude threshold (pop_eegthresh)', 'do_rej_thresh'}, {'off', 'on'},...
    {'reject abnormal trends (pop_rejtrend)', 'do_rej_trend'}, {'off', 'on'},...
    {'reject improbable data (pop_jointprob)', 'do_rej_prob'}, {'off', 'on'},...
    {'reject based on kurtosis (pop_rejkurt)', 'do_rej_kurt'}, {'off', 'on'});
CFG = addfields(CFG, foo, but);

if any([CFG.do_rej_thresh, CFG.do_rej_trend, CFG.do_rej_prob, CFG.do_rej_kurt])
    [foo, but] = settingsdlg('title', 'automatic artifact detection',...
        'description',...
        ['You decided to use at least one automated artifact detection algorithm. '...
        'Do you want to...'],...
        {'auto-delete trials (no = manual inspection)', 'rej_auto'}, {'off', 'on'},...
        {'display events in the plot (slower)', 'display_events'}, {'off', 'on'});
    CFG = addfields(CFG, foo, but);
end

if CFG.do_rej_thresh
    try
        tmin = CFG.epoch_tmin;
    catch 
        tmin = 0; 
    end
    
    try
        tmax = CFG.epoch_tmax;
    catch 
        tmax = 0; 
    end
    [foo, but] = settingsdlg('title', 'pop_rejthresh',...
        'description',...
        ['Please configure threshold criterion. The unit depends on your '...
        'data but should usually be microvolts. Default start + endtime'...
        ' equals the whole epoch.'],...
        {'amplitude threshold', 'rej_thresh'}, 450,...
        {'starttime', 'rej_thresh_tmin'}, tmin,...
        {'endtime', 'rej_thresh_tmax'}, tmax);
    CFG = addfields(CFG, foo, but);
end

% Do you want to reject trials based on slope?
if CFG.do_rej_trend
    try
        winsize = CFG.new_sampling_rate * abs(CFG.epoch_tmin - CFG.epoch_tmax);
    catch
        winsize = 0;
    end
    [foo, but] = settingsdlg('title', 'pop_rejtrend',...
        'description',...
        ['Please configure slope criterion. The default windowsize is '...
        'the number of sampling points in one epoch (after downsampling).'],...
        {'windows size', 'rej_trend_winsize'}, winsize,...
        {'maximum slope threshold', 'rej_trend_maxSlope'}, 30,...
        {'minR (leave at 0 for slope criterion only)', 'rej_trend_minR'}, 0);
    CFG = addfields(CFG, foo, but);
end

% Do you want to reject trials based on joint probability?
if CFG.do_rej_prob
    [foo, but] = settingsdlg('title', 'do_rej_prob',...
        'description',...
        ['Please configure joint probability.'],...
        {'local threshold', 'rej_prob_locthresh'}, 8,...
        {'global threshold', 'rej_prob_globthresh'}, 4);
    CFG = addfields(CFG, foo, but);
end


if CFG.do_rej_kurt
    [foo, but] = settingsdlg('title', 'do_rej_kurt',...
        'description',...
        'Please configure kurtosis thesholds.',...
        {'local threshold', 'rej_kurt_locthresh'}, 6,...
        {'global threshold', 'rej_kurt_globthresh'}, 3);
    CFG = addfields(CFG, foo, but);
end


%% Eyelink related input
CFG.coregister_Eyelink = qbool(...
    'Do you want to coregister eyelink eyetracking data?',...
    'Eyelink coregistration');

if CFG.coregister_Eyelink
    [foo, but] = settingsdlg('title', 'Eyelink config',...
        'description',...
        ['Coregistration is done by using the first instance of the first value and '...
        'the last instance of the second value. Everything inbetween is downsampled '...
        'and interpolated. Files are transformed from .edf to .ascii and then to .mat. '...
        'Since that always takes a while, you can select to keep these intermediary files.'],...
        {'start + end trigger', 'eye_startEnd'}, '[10, 60]',...
        {'keep intermediary files [ascii, mat]', 'eye_keepfiles'}, '[1, 1]');
    CFG = addfields(CFG, foo, but);
    CFG.eye_keepfiles = eval(CFG.eye_keepfiles);
    CFG.eye_startEnd = eval(CFG.eye_startEnd);
end

%% Parameters for ICA.
[foo, but] = settingsdlg('title', 'ICA config',...
    'description',...
    ['Configure ICA training. Default is the extended infomax binica'...
    ' ICA with three components less than the numer of data channels. '...
    'Check out github.com/wanjam/binica to find out how to compile binica '...
    'using Intel''s math kernel library (or download a compiled version '...
    'for our servers).'],...
    {'type', 'ica_type'}, {'binica', 'runica'},...
    {'extended Infomax?', 'ica_extended'}, {'yes', 'no'},...
    {'channels used for ICA training', 'ica_chans'}, 'CFG.data_chans',...
    {'how many components to extract (0 for automatic)', 'ica_ncomps'}, numel(CFG.data_chans) - 3,...
    {'backproject weights to continuous data?', 'ica_continuous'}, {'yes', 'no'},...
    'separator', 'OPTICAT can be used to create an optimized ICA training set',...
    {'use OPTICAT?', 'use_OPTICAT'}, {'yes', 'no'});
CFG = addfields(CFG, foo, but);
CFG.ica_chans = eval(CFG.ica_chans);

if CFG.use_OPTICAT
    [foo, but] = settingsdlg('title', 'OPTICAT',...
        'description',...
        ['Do you want to do an extra run of high-pass filtering before ICA (i.e., after segmentation)? ',...
        'see Olaf Dimigen''s OPTICAT. ',...
        'The data as filtered below are only used to train the ICA. The ',...
        'activation is then reprojected to the original data filtered as indicated ',...
        'above in the section ''filters''. '],...
        {'use extra-run of high-pass filtering', 'do_ICA_hp_filter'}, {'yes', 'no'},...
        {'which filter type?', 'hp_ICA_filter_type'}, {'eegfiltnew', 'butterworth', 'kaiser'},...
        {'filter limit', 'hp_ICA_filter_limit'}, 2.5,...
        {'transition bandwidth (only used for kaiser)', 'hp_ICA_filter_tbandwidth'}, 0.2,...
        {'pass-band ripple (only used for kaiser)', 'hp_ICA_filter_pbripple'}, 0.01,...
        'separator', 'Olaf Dimigen recommends to overweight spike ',...
        'separator', 'potentials using his OPTICAT approach. ',...
        'separator', 'Do you want to do this prior to computung ICA?',...
        {'overweight spike potentials?', 'ica_overweight_sp'}, {'yes', 'no'},...
        {'time window to overweight (-20...', 'opticat_saccade_before'}, -0.02,...
        {'...to 10 ms)', 'opticat_saccade_after'}, 0.01,...
        {'overweighting proportion', 'opticat_ow_proportion'}, 0.5,...
        {'subtr. mean of overw.? (recommended)', 'opticat_rm_epochmean'}, {'yes', 'no'});
    CFG = addfields(CFG, foo, but);
end



%% ICA rejection/detection parameters
[foo, but] = settingsdlg('title', 'ICA rejection/detection parameters',...
    'description',...
    ['How do you want to select ICs that should be rejected?',...
    ' Note that you can run prep04 either for epoched *or* for ',...
    'continuous data. If you want both, you can simply run the ',...
    'script once and then change CFG.ica_rm_continuous.'],...
    {'reject epoched or continuous?', 'ica_rm_continuous'}, {'cont', 'epoch'},...
    {'manually inspect ICs before rejection?', 'ica_plot_ICs'}, {'yes', 'no'},...
    {'Ask for confirmation to remove ICs?', 'ica_ask_for_confirmation'}, {'no', 'yes'},...
    {'Use eyetracker based IC selection?', 'do_eyetrack_ica'}, {'yes', 'no'},...
    {'Use the IClabel classifier', 'do_iclabel_ica'}, {'yes', 'no'},...
    {'Select ICs based on correlation with EOG?', 'do_corr_ica'}, {'no', 'yes'},...
    {'Use SASICA to select ICs', 'do_SASICA'}, {'no', 'yes'});
CFG = addfields(CFG, foo, but);

if CFG.do_eyetrack_ica
    [foo, but] = settingsdlg('title', 'EYE-ICA',...
        'description',...
        ['Please configure eyetracker based IC selection. ',...
        'Parameters correspond to the arguments passed to pop_eyetrackerica() ',...
        '(threshratio, sactol, topomode). The defaults are the recommended ',...
        'settings. Note: Due to a bug in eeglab, resampling is ',...
        'incompatible with this method of IC selection. You can resample later, however.'],...
        {'variance ratio threshold (var(sac)/var(fix))', 'eyetracker_ica_varthresh'}, 1.3,...
        {'temporal tolerance around saccade on/offset', 'eyetracker_ica_sactol'}, '[5, 10]',...
        {'Plot rejection (4 = no, 1 = bad, 2 = good, 3 = all)', 'eyetracker_ica_feedback'}, 4);
    CFG = addfields(CFG, foo, but);
end

if CFG.do_iclabel_ica
    [foo, but] = settingsdlg('title', 'IClabel classifier',...
        'description',...
        ['Please configure IClabel based IC selection. ',...
        'What types of ICs do you want to remove? Options are: ',...
        '''Brain'', ''Muscle'', ''Eye'', ''Heart'', ''Line Noise'', ',...
        '''Channel Noise'', and ''Other''.  The minimum probability to ',...
        'believe an IC''s assigned label is true can either be a vector with',...
        ' one accuracy per category or a single value for all categories.'],...
        {'types', 'iclabel_rm_ICtypes'}, {'Eye', 'Muscle'}',...
        {'threshold', 'iclabel_min_acc'}, .9);
    CFG = addfields(CFG, foo, but);
end

if CFG.do_corr_ica
    [foo, but] = settingsdlg('title', 'correlation IC',...
        'description',...
        ['Please configure correlation based IC selection. '],...
        {'threshold for IC rejection (absolute r)', 'ic_corr_bad'}, 0.65);
    CFG = addfields(CFG, foo, but);
end

questdlg(['Done! To configure anything else (e.g., things that happen ',...
    'after preprocessing), check your get_cfg file.'], 'Info', 'OK', 'OK');

save('CUSTOM_get_cfg.mat', 'CFG'); % safety backup

%% now get the cfg file and set values.
sourcedir = which('ElektroSetup');
sourcedir = sourcedir(1:regexp(sourcedir, '\\ElektroSetup.m'));
res = dir([sourcedir, '**/get_cfg.m']);
sourcefile = fullfile(res.folder, res.name);
targetfile = qtext('Targetfile', 'CUSTOM_get_cfg.m',...
    'Please inset the name of the targetfile');

% copy and write to target file
fid = fopen(sourcefile);
wholecfg = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
CFG = rmfield(CFG, 'use_OPTICAT'); % only used in this functions
fnames = fieldnames(CFG);
for ifield = 1:length(fnames)
    expr = ['CFG.', fnames{ifield}];
    idx = cellfun(@(x) regexp(x, ['^',expr, '\s*='], 'names'), wholecfg, 'uni', 0);
    this_line = find(~cellfun(@isempty, idx{1}));
    urtxt = wholecfg{1}{this_line};
    wholecfg{1}(this_line) = {[expr, ' = ', treat(CFG.(fnames{ifield})), ';% ', urtxt]}; 
end

fid = fopen(targetfile,'w');
fprintf(fid,'%s\n', wholecfg{1}{:});
fclose(fid);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Assertion checks for incompatible configurations
assert(~(CFG.do_eyetrack_ica & CFG.do_resampling));
assert(~(CFG.rej_cleanrawdata & ...
    (CFG.do_interp & ~all(strcmp(CFG.interp_these, 'spread')))));
end

function [varargout] = qtext(title, def, question)
if ~iscell(def)
    def = {def};
end
[varargout] = inputdlg(question, sprintf('Elektro_cfg: %s', title), 1, def);

for icell = 1:numel(varargout)
    if ~isnan(str2double(varargout{icell}))
        varargout{icell} = str2double(varargout{icell});
    end
    try
        if isvector(eval(varargout{icell}))
            varargout{icell} = eval(varargout{icell});
        end
    end
    if strcmp(varargout{icell}, '[]')
        varargout{icell} = [];
    end
    if strcmp(varargout{icell}, '{}')
        varargout{icell} = {};
    end
end

end

function [answer] = qbool(title, question)
answer = questdlg(sprintf('Elektro_cfg: %s', title), question);
if strcmpi(answer, 'yes')
    answer = true;
    return
elseif strcmpi(answer, 'no')
    answer = false;
    return
end
end

function [CFG] = addfields(CFG, resp, but)
if strcmpi(but, 'Cancel')
    error('you pressed cancel');
end
fnames = fieldnames(resp);
for i = 1:length(fnames)
    ifield = fnames{i};
    CFG.(ifield) = resp.(ifield);
    if ischar(CFG.(ifield))
        if ismember(CFG.(ifield), {'on', 'off'})
            CFG.(ifield) = strcmp(CFG.(ifield), 'on');
        elseif ismember(CFG.(ifield), {'true', 'false'})
            CFG.(ifield) = strcmp(CFG.(ifield), 'true');
        elseif ismember(CFG.(ifield), {'yes', 'no'})
            CFG.(ifield) = strcmp(CFG.(ifield), 'yes');
        end
    end
end
end

function [that] = treat(this)

if isnumeric(this)
    that = regexprep(my_num2mstr(this),' +',' ');
    if isempty(that)
        that = '[]';
    end
elseif iscell(this)
    that = ['{' strjoin(cellfun(@cellcheck, this, 'uni', 0), ', ') '}'];
elseif islogical(this)
    if this
        that = 'true';
    elseif ~this
        that = 'false';
    end
else
    that = ['''' this ''''];
end
end

function [y] = cellcheck(x)
if isnumeric(x)
    y = regexprep(my_num2mstr(x),' +',' ');
else
    y = ['''' x ''''];
end
end

function s = my_num2mstr(n)
%NUM2MSTR Convert number to string in maximum precision.
%   S = NUM2MSTR(N) converts real numbers of input 
%   matrix N to string output vector S, in 
%   maximum precision.
%
%   See also NUM2STR.

%   M. Misiti, Y. Misiti, G. Oppenheim, J.M. Poggi 01-May-96.
%   Last Revision: 10-Jun-2013.
%   Copyright 1995-2013 The MathWorks, Inc.
% $Revision: 1.11.4.2 $

if ischar(n) , s = n; return; end
[r,c] = size(n);
if isnumeric(n)
    if max(r,c)==1
        s = sprintf('%s',num2str(n));
        
    elseif r>1
        s = [];
        for k=1:r
            s = [s sprintf('%s',num2str(n(k,:))) ';'];
        end
        s = ['[' s ']'];
        
    elseif c>1
        s = sprintf('%s',num2str(n));
        s = ['[' s ']'];
        
    else
        s = '';
    end
else
    if max(r,c)==1
        s = handle2str(n);
        
    elseif r>1
        s = [];
        for k=1:r
            s = [s handle2str(n(k,:)) ';'];
        end
        s = ['[' s ']'];
        
    elseif c>1
        s = handle2str(n);
        s = ['[' s ']'];
        
    else
        s = '';
    end
end
end