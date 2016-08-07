function EEG = func_prepareEEG(EEG, cfg, S, who_idx)

% Convert data to double precision, recommended for filtering and other
% precedures.
EEG.data = double(EEG.data);


% --------------------------------------------------------------
% If replace_chans are defined for this subject, replace bad 
% channels now.
% --------------------------------------------------------------

if isempty(S.replace_chans(who_idx)) | isnan(S.replace_chans(who_idx))
    fprintf('No channels to replace.\n')
else
    replace_chans = str2double(cell2mat(S.replace_chans(who_idx)));
    
    for ichan = 1:size(replace_chans,1)
        bad_chan  = replace_chans(ichan, 1);
        good_chan = replace_chans(ichan, 2);
        
        EEG.data(bad_chan,:) = EEG.data(good_chan, :) ;
        com = sprintf('Replacing bad electrode %d with good electrode %d.\n', ...
            bad_chan, good_chan);
        EEG = eegh(com, EEG);
        disp(com);
    end
end


% --------------------------------------------------------------
% Delete unwanted channels and import channel locations.
% --------------------------------------------------------------
[EEG, com] = pop_select(EEG, 'channel', cfg.data_chans); 
EEG = eegh(com, EEG);

%     The following step should be unnecessary if the data were recorded
%     with a proper *.cfg file for the ActiView recording program. This cfg
%     file should specifiy the channel label for every channel including
%     external electrodes. 
%     Note: command history is broken for this function - not written to
%     eegh.
%     EEG = pop_chanedit(EEG, 'changefield',{67 'labels' 'AFp9'}, 'changefield',{65 'type' 'EOG'});

% EEG.chanlocs(67).labels = 'AFp9';
% EEG.chanlocs(68).labels = 'AFp10';
% EEG.chanlocs(69).labels = 'IO1';

if ~isempty(cfg.heog_chans)
    fprintf('Computing HEOG from channels %s and %s\n', ...
        EEG.chanlocs(cfg.heog_chans(1)).labels, ...
        EEG.chanlocs(cfg.heog_chans(2)).labels)
    
    iHEOG = EEG.nbchan + 1;    
    EEG.nbchan = iHEOG;
    EEG.chanlocs(iHEOG) = EEG.chanlocs(end);
    EEG.chanlocs(iHEOG).labels = 'HEOG';    
    EEG.data(iHEOG,:) = EEG.data(cfg.heog_chans(1),:,:) - EEG.data(cfg.heog_chans(2),:,:);
end

if ~isempty(cfg.veog_chans)
    fprintf('Computing VEOG from channels %s and %s\n', ...
        EEG.chanlocs(cfg.veog_chans(1)).labels, ...
        EEG.chanlocs(cfg.veog_chans(2)).labels)
    
    iVEOG = EEG.nbchan + 1;    
    EEG.nbchan = iVEOG;
    EEG.chanlocs(iVEOG) = EEG.chanlocs(end);
    EEG.chanlocs(iVEOG).labels = 'VEOG';    
    EEG.data(iVEOG,:) = EEG.data(cfg.veog_chans(1),:,:) - EEG.data(cfg.veog_chans(2),:,:);
end

[EEG] = pop_chanedit(EEG, 'lookup', cfg.chanlocfile);


% --------------------------------------------------------------
% Downsample data. Removing and adding back the path is necessary for
% avoiding an error of the resample function. Not sure why. Solution is
% explained here: https://sccn.ucsd.edu/bugzilla/show_bug.cgi?id=1184
% --------------------------------------------------------------
if cfg.do_resampling
    [pathstr, ~, ~] = fileparts(which('resample.m'));
    rmpath([pathstr '/'])
    addpath([pathstr '/'])
    [EEG, com] = pop_resample( EEG, cfg.new_sampling_rate); 
    EEG = eegh(com, EEG);
end


% --------------------------------------------------------------
% Filter the data.
% --------------------------------------------------------------
if cfg.do_lp_filter
    [m, ~] = pop_firwsord('blackman', EEG.srate, cfg.lp_filter_tbandwidth);
    [EEG, com] = pop_firws(EEG, 'fcutoff', cfg.lp_filter_limit, 'ftype', 'lowpass', 'wtype', 'blackman', 'forder', m);
    EEG = eegh(com, EEG);
end

if cfg.do_hp_filter
    switch(cfg.hp_filter_type)
        
        case('butterworth') % This is a function of the separate ERPlab toolbox.
            [EEG, com] = pop_ERPLAB_butter1( EEG, cfg.hp_filter_limit, 0, 5); % requires ERPLAB plugin
            EEG = eegh(com, EEG);
            
        case('kaiser')
            m = pop_firwsord('kaiser', EEG.srate, cfg.hp_filter_tbandwidth, cfg.hp_filter_pbripple);
            beta = pop_kaiserbeta(cfg.hp_filter_pbripple);
            
            [EEG, com] = pop_firws(EEG, 'fcutoff', cfg.hp_filter_limit, ...
                'ftype', 'highpass', 'wtype', 'kaiser', ...
                'warg', beta, 'forder', m);
            EEG = eegh(com, EEG);
    end
end


% --------------------------------------------------------------
% If wanted: re-reference to new reference, but exclude the new bipolar
% channels.
% --------------------------------------------------------------
if cfg.do_preproc_reref
    [EEG, com] = pop_reref( EEG, cfg.preproc_reference, ...
        'keepref','on', ...
        'exclude', cfg.data_chans(end)+1:EEG.nbchan);
    EEG = eegh(com, EEG);
else
    disp('No rereferencing after import.')
end


% --------------------------------------------------------------
% Epoch the data.
% --------------------------------------------------------------

% Optional: remove all events except the target events from the EEG
% structure.
%[EEG] = pop_selectevent( EEG, 'type', [cfg.trig_target,cfg.trig_omit] , ...
%    'deleteevents','on','deleteepochs','on','invertepochs','off');

[EEG, ~, com] = pop_epoch( EEG, cellstr(num2str(cfg.trig_target')), [cfg.epoch_tmin cfg.epoch_tmax], ...
    'newname', 'BDF file epochs', 'epochinfo', 'yes');
EEG = eegh(com, EEG);

% Optional: remove all epochs containing triggers specified in CFG.trig_omit
if ~isempty(cfg.trig_omit)
    rejidx = zeros(1,length(EEG.epoch));
    for i=1:length(EEG.epoch)
        if sum(ismember(cfg.trig_omit,[EEG.epoch(i).eventtype{:}]))>=1 || ismember(i,[cfg.trial_omit])
            rejidx(i) =  1;
        end
    end
    EEG = pop_rejepoch(EEG, rejidx, 0);
    EEG = eegh(com, EEG);
end
% --------------------------------------------------------------
% Remove 50Hz line noise using Tim Mullen's cleanline.
% --------------------------------------------------------------
if cfg.do_cleanline
    
    % FFT before cleanline
    [amps,  EEG.cleanline.freqs] = my_fft(EEG.data, 2, EEG.srate, EEG.pnts);
    EEG.cleanline.pow = mean(amps.^2, 3);
    
    winlength = EEG.pnts / EEG.srate;
    [EEG, com] = pop_cleanline(EEG, ...
        'bandwidth', 2, 'chanlist', 1:EEG.nbchan, ...
        'computepower', 0, 'linefreqs', [50 100], ...
        'normSpectrum', 0, 'p', 0.01, ...
        'pad',2, 'plotfigures', 0, ...
        'scanforlines', 1, 'sigtype', 'Channels', ...
        'tau', 100, 'verb', 1, ...
        'winsize', winlength, 'winstep',winlength);
    EEG = eegh(com, EEG);
    
    % FFT after cleanline
    [ampsc, EEG.cleanline.freqsc] = my_fft(EEG.data, 2, EEG.srate, EEG.pnts);
    EEG.cleanline.powc = mean(ampsc.^2, 3);
    
end
        

% --------------------------------------------------------------
% Detrend the data.
% This is an external function provided by Andreas Widmann:
% https://github.com/widmann/erptools/blob/master/eeg_detrend.m
% --------------------------------------------------------------
if cfg.do_detrend
    EEG = eeg_detrend(EEG);
    EEG = eegh('EEG = eeg_detrend(EEG);% https://github.com/widmann/erptools/blob/master/eeg_detrend.m', EEG);
end



% Convert back to single precision.
EEG.data = single(EEG.data);
