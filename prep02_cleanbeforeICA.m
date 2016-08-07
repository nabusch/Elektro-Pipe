% This script is used for manual artifact rejection. You can combine this
% with initial automatic rejection. If oyu plan to run ICA for artifact
% correction, you can use this with a very high threshold for detecting
% technical artifacts (e.g. subject movements) with crazy large amplitudfes
% that surpass typical blink artifacts.
%
% Unfortunately, we have to run this process as a script, because the
% rejection functions do not work from within a function due to the strange
% and intransparent inner workings of eeglab.
%
% Note that the script requires that you have a running instance of eeglab.
% Open eeglab using
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab('nogui');


[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
[sub_dir, sub_name, ~] = fileparts(EP.cfg_file);

addpath(sub_dir);
addpath(cfg_dir);

S = readtable(EP.st_file);

who_idx = get_subjects(S, EP.who);


%%
for isub = 1:length(who_idx)
    
    % Load CFG file. I know, eval is evil, but this way we allow the user
    % to give the CFG function any arbitrary name, as defined in the EP
    % struct.
    evalstring = ['CFG = ' cfg_name '(' num2str(who_idx(isub)) ', S);'];
    eval(evalstring);
    
    
    % Write a status message to the command line.
    fprintf('\nNow working on subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));
    
    % ---------------------------------------------------------------------
    % Load data set.
    % ---------------------------------------------------------------------
    EEG = pop_loadset('filename', [CFG.subject_name '_import.set'] , ...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
    
    
    % ---------------------------------------------------------------------
    % If cfg file specifies channels for interpolation for this subject,
    % interpolate them now.
    interp_chans = str2num(S.interp_chans{who_idx(isub)});
    if isempty(interp_chans) | isnan(interp_chans)
        fprintf('No channels to interpolate.\n')
    else
        str=sprintf('%d ', interp_chans);
        fprintf('Interpolating channel(S): %s\n', str);
        EEG = eeg_interp(EEG, interp_chans);
    end
    
    
    % ---------------------------------------------------------------------
    % Mark trials for rejection with simple amplitude criterion.
    % Inspired by
    % http://sccn.ucsd.edu/pipermail/eeglablist/2014/008339.html
    % ---------------------------------------------------------------------
    EEG = pop_eegthresh(EEG, 1, CFG.data_chans, ...
        -CFG.rej_thresh, CFG.rej_thresh, ...
        CFG.rej_thresh_tmin, CFG.rej_thresh_tmax, 1, 0);
    plotRejThr=trial2eegplot(EEG.reject.rejthresh, EEG.reject.rejthreshE, EEG.pnts, EEG.reject.rejthreshcol);
    
    
    % ---------------------------------------------------------------------
    %  Manual data inspection; mark electrodes for trial-wise interpolation.
    % We have to interrupt programm execution with "keyboard" while the
    % rejection GUI is active. Continue by hitting the "Continue" button in
    % the Matlab editor menu bar.
    %  ---------------------------------------------------------------------
    mypop_eegplot(EEG, 1, 1, 0,'submean','on', 'winlength', 15, 'winrej', plotRejThr);
    
    % The following code is deprecated since I fugured out that I can pass these options
    % directly to mypop_eegplot.
    %     ud = get(gcf,'UserData');
    %     ud.winlength = 15; %show 15 trials
    %     ud.winrej = plotRejThr;
    %     set(gcf,'UserData',ud);
    %     eegplot('draws',0);
    
    disp('Interrupting function now. Waiting for you to press')
    disp('"Update marks", and hit "Continue" in Matlab editor menu')
    keyboard
    
    
    % ---------------------------------------------------------------------
    %  Execute interpolation and rejection and save data.
    %  ---------------------------------------------------------------------
    [EEG, com] = pop_selectiveinterp(EEG);
    EEG = eegh(com,EEG);
    [EEG, com] = pop_rejepoch(EEG, find(EEG.reject.rejmanual), 1);
    EEG = eegh(com,EEG);
    
    EEG = pop_editset(EEG, 'setname', [CFG.subject_name '_CleanBeforeICA.set']);
    EEG = pop_saveset( EEG, [CFG.subject_name '_tCleanBeforeICA.set'] , CFG.dir_eeg);
    
    S.has_prepICA(who_idx(isub)) = 1;
    writetable(S, EP.st_file)
    
end