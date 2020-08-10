function [EEG] = prep04_rejectICs(EP)
%PREP04_REJECTICS detects artifactual ICs and rejects them
%
%   This function is a complete rewrite of the old prep04. As of March 20,
%   2020, I highly recommend using this function, as it integrates four
%   approaches of detecting ICs in a streamlined manner:
%   1. simple correlation ICs with EOG channels
%   2. covariance of ICs with simultaneous eyetrack
%   3. the IClabel classifier
%   4. SASICA
%
%   This function should be called in prep_master, which should prepare the
%   input structure 'EP'
%
%   The following parameters in your Elektro-Pipe get_cfg.m can influence
%   the behavior of this function:
%   CFG.ica_rm_continuous = remove ICs from continuous or epoched set?
%                           ('cont' for continuous, else epoched)
%   CFG.do_corr_ica       = detect EOG components by correlating IC
%                           components with EOG channels? boolean
%   CFG.do_eyetrack_ica   = run eye-eeg's detection of EOG ICs via
%                           covariance of eyetrack and ICs? boolean
%   CFG.do_SASICA         = use SASICA for IC detection and plotting?
%                           incompatible with all other mechanisms. bool
%   CFG.do_IClabel        = detect artifacts using the the IClabel
%                           classifier? bool
%   CFG.ica_plot_ICs      = Plot ICs after selection for a manual
%                           inspection?
%
%   See the default config file for more detailed adjustment of each of the
%   mechanisms.
%
% (c) Wanja Mössing, github.com/wanjam, 03/2020
%  Copyright (C) 2020 Wanja Moessing
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program. If not, see <http://www.gnu.org/licenses/>.

%% 01: setup environment
[P.cfg_dir, P.cfg_name, ~] = fileparts(EP.cfg_file);
addpath(P.cfg_dir);
EP.S = readtable(EP.st_file);
who_idx = get_subjects(EP);

%% 02: process input arguments, set defaults
P.autoclick = 'no'; % don't automatically click 'compute' in sasica

%% loop over files, select and reject components in the configured ways
for isub = 1:length(who_idx)
    
    %% 02B: process File-specific input arguments, set defaults
    [CFG, P] = process_input_set_defaults(P, isub, who_idx, EP);
    
    %% 03: load current dataset
    EEG = load_data(CFG);
    
    %% 04: detect ICs based on correlation with EOG
    EEG = detect_EOG_corr_ICs(EEG, CFG);
    
    %% 05: detect ICs based on covariance with eyetrack
    EEG = detect_eyetrack_ICs(EEG, CFG);
    
    %% 06: detect ICs based on IClabel classification
    [EEG, reason] = detect_iclabel_ICs(EEG, CFG);
    
    %% 07: detect ICs using SASICA
    % WM: SASICA internally overwrites EEG.reject.gcompreject and assigns
    % EEG in base. It then internally starts pop_selectcomp to plot the
    % components. Integrating SASICA with the other mechanisms would thus
    % require a lot of "hacky" code and I don't really see the point.
    [EEG] = detect_SASICA_ICs(EEG, CFG, P);
    
    %% 08: Manual inspection
    % i know - moving stuff to other spaces is ugly, but seems to be the 
    % only way of using pop_selectcomp without rewriting it...
    if CFG.ica_plot_ICs
        assignin('base', 'EEG', EEG);
        EEG = mypop_selectcomps(EEG);
        EEG.reject.gcompreject = evalin('base', 'EEG.reject.gcompreject');
    end
    
    %% 09: reconstruct signal without ICs and store output
    EEG = pop_subcomp(EEG, [], CFG.ica_ask_for_confirmation);
    
    if CFG.keep_continuous && strcmp(CFG.ica_rm_continuous, 'cont')
        EEG = pop_editset(EEG, 'setname', [CFG.subject_name,...
            '_ICACONTrejected.set']);
        EEG = pop_saveset(EEG, [CFG.subject_name '_ICACONTrej.set'],...
            CFG.dir_eeg);
    else
        EEG = pop_editset(EEG,'setname',[CFG.subject_name,...
            '_ICArejected.set']);
        EEG = pop_saveset(EEG, [CFG.subject_name '_ICArej.set'],...
            CFG.dir_eeg);
    end
    
    %% 10: update subjects table
    %add info to table
    EP.S = readtable(EP.st_file);
    EP.S.has_ICAclean(who_idx(isub)) = 1;
    writetable(EP.S, EP.st_file);
    
    %close SASICA window
    if CFG.do_SASICA
        close(S);
    end
end
end

%% subfunctions
function [CFG, P] = process_input_set_defaults(P, isub, who_idx, EP)
cfg_fun = str2func(P.cfg_name);
CFG = cfg_fun(who_idx(isub), EP.S);

% Write a status message to the command line.
fprintf('\nNow working on file %s, (Nr %d of %d to process).\n\n',...
    CFG.subject_name, isub, length(who_idx));

% ----------------------------------------------
% handle backward compatibility
% ----------------------------------------------
% throw errors for deprecated values to avoid giving users the
% impression something is happening, when in fact it isn't.
if isfield(CFG, 'ica_reject_fully_automatic')
    error(['Your config has a field ''ica_reject_fully_automatic''.'...
        ' This value is deprecated. Run ''help prep04_rejectICs'''...
        'for more information.']);
end

if isfield(CFG, 'eye_ica')
    error(['Your config has a field ''eye_ica''.'...
        ' This value is deprecated. Run ''help prep04_rejectICs'''...
        'for more information.']);
end

% asking for confirmation used to be the default
if ~isfield(CFG, 'ica_ask_for_confirmation')
    CFG.ica_ask_for_confirmation = true;
end

% throw mild warnings for values that changed names to be consistent
if isfield(CFG, 'eyetracker_ica')
    if isfield(CFG, 'do_eyetrack_ica')
        if CFG.eyetracker_ica ~= CFG.do_eyetrack_ica
            error(['Your config contains a value ''eyetracker_ica'''...
                ' and a value ''do_eyetrack_ica''. Actually, they '...
                'mean the same: The name changed to ''do_eyetrack_'...
                'ica'' in order to have a consistent naming. The '...
                'old name still works, but in your case the two '...
                'values differ from each other, so I have no idea '...
                'what to do!']);
        end
    end
    warning(['Your config contains a value ''eyetracker_ica'''...
        '. This name changed to ''do_eyetrack_ica'''...
        ' in order to have a consistent naming. The '...
        'old name still works, though.'])
    CFG.do_eyetrack_ica = CFG.eyetracker_ica;
end

if isfield(CFG, 'eye_ica')
    error(['cfg.eye_ica is deprecated. Use CFG.eyetracker_ica ',...
        'instead.']);
end

% using only SASICA used to be default
for ifield = {'do_eyetrack_ica', 'do_corr_ica', 'do_iclabel_ica'}
    if ~isfield(CFG, ifield{:})
        CFG.(ifield{:}) = false;
    end
end
if ~isfield(CFG, 'do_SASICA')
    CFG.do_SASICA = true;
end
end

function [EEG] = load_data(CFG)
% Load data set.
% If config says so,weights have been copied to continuous data.
% If ica_rm_continuous in config is 'cont', we want to remove
% components from continuous data and work with those.
if CFG.keep_continuous && strcmp(CFG.ica_rm_continuous, 'cont')
    EEG = pop_loadset('filename', [CFG.subject_name '_ICACONT.set'],...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
else
    EEG = pop_loadset('filename', [CFG.subject_name '_ICA.set'],...
        'filepath', CFG.dir_eeg, 'loadmode', 'all');
end
end

function [EEG] = remember_old_ICs(EEG, new_ICs)
% combine IC detection of multiple mechanisms
ncomps = size(EEG.icaact, 1);
if isfield(EEG, 'reject')
    if isfield(EEG.reject, 'gcompreject')
        old_ICs = EEG.reject.gcompreject;
    else
        old_ICs = false(1, ncomps);
    end
else
    old_ICs = false(1, ncomps);
end

% check if new_ICs are numeric or logical indexes
if length(new_ICs) ~= ncomps || ~all(ismember(new_ICs, [0, 1]))
    old_ICs(new_ICs) = true;
else
    old_ICs = old_ICs | new_ICs;
end

EEG.reject.gcompreject = old_ICs;
end

function [EEG] = detect_EOG_corr_ICs(EEG, CFG)
% Find bad ICs (those that correlate strongly with VEOG/HEOG).
if CFG.do_corr_ica
    % get components and identify EOG channels
    icact = EEG.icaact;
    chans = [find(strcmp({EEG.chanlocs.labels}, 'VEOG')),...
        find(strcmp({EEG.chanlocs.labels}, 'HEOG'))];
    
    % loop over EOG channels and compute correlation between ICs and EOG
    for ichan = 1:length(chans)
        eeg = EEG.data(chans(ichan), :, :);
        eeg = reshape(eeg, [1, EEG.pnts * EEG.trials]);
        
        for icomp = 1:size(icact,1)
            ic = icact(icomp,:);
            ic = reshape(ic,  [1, EEG.pnts * EEG.trials]);
            corr_tmp = corrcoef(ic, eeg);
            corr_eeg_ic(icomp, ichan) = corr_tmp(1, 2);
        end
        
        % detect correlations above the indicated threshold
        bad_ic{ichan} = find(abs(corr_eeg_ic(:,ichan)) >= CFG.ic_corr_bad)';
        bad_ic_cor{ichan} = corr_eeg_ic(bad_ic{ichan},ichan);
    end
    
    fprintf('Detected %i bad ICs based on correlation with EOG:\n',...
        length(unique([bad_ic{:}])))
    for ichan = 1:length(chans)
        for ibad = 1:length(bad_ic{ichan})
            fprintf('EEG chan %d: IC %d. r = %2.2f.\n', ...
                chans(ichan), bad_ic{ichan}(ibad), bad_ic_cor{ichan}(ibad))
        end
    end
    
    % store which ICs are artefactual
    EEG = remember_old_ICs(EEG, unique([bad_ic{:}]));
end
end

function [EEG] = detect_eyetrack_ICs(EEG, CFG)
if CFG.do_eyetrack_ica
    % detect labels of fixations and saccades
    types = unique({EEG.event.type});
    fixdx = cellfun(@(x) endsWith(x, 'fixation') ||...
        startsWith(x, 'fixation'), types);
    sacdx = cellfun(@(x) endsWith(x, 'saccade') ||...
        startsWith(x, 'saccade'), types);
    if sum(fixdx) ~= 1 || sum(sacdx) ~= 1
        error(['Could not determine unique fixation and or saccade',...
            ' identifier event. Consider renaming in EEG.event.type']);
    end
    
    % make all latencies integers to avoid index warning in
    % geticavariance.m
%     if all(arrayfun(@isscalar, [EEG.event.latency]))
%         tmp = cellfun(@int64, {EEG.event.latency}, 'UniformOutput', 0);
%         [EEG.event.latency] = tmp{:};
%     end
    
    % make sure field gcompreject exists so eyetrackerica integrates old
    % and new IC detections
    EEG = remember_old_ICs(EEG, false(1, size(EEG.icaact, 1)));
    
    [EEG, ~] = pop_eyetrackerica(EEG, types{sacdx},...
        types{fixdx}, CFG.eyetracker_ica_sactol, CFG.eyetracker_ica_varthresh, 2,...
        CFG.eyetracker_ica_feedback ~= 4, CFG.eyetracker_ica_feedback);
    
    if CFG.eyetracker_ica_feedback ~= 4
        fprintf(2, 'Hit continue or F5 to proceed!\n');
        keyboard; % wait for user to check eyetrackerica output
    end
end
end

function [EEG, reason] = detect_iclabel_ICs(EEG, CFG)
if CFG.do_iclabel_ica
    % run classification
    EEG = iclabel(EEG);
    
    % check if each category has a unique threshold
    if length(CFG.iclabel_min_acc) == 1
        thr = repelem(CFG.iclabel_min_acc, length(CFG.iclabel_rm_ICtypes));
    end
    
    % loop over the to-be-rejected categories and flag ICs
    rej = false(1, size(EEG.icaact, 1));
    reason = cell(1, size(EEG.icaact, 1));
    acc = EEG.etc.ic_classification.ICLabel.classifications;
    lbl = EEG.etc.ic_classification.ICLabel.classes;
    for icat = CFG.iclabel_rm_ICtypes
        class = strcmp(lbl, icat);
        thrclass = strcmp(CFG.iclabel_rm_ICtypes, icat);
        comp = acc(:, class) >= thr(thrclass);
        if any(comp)
            rej(comp) = true;
            reason(comp) = icat;
        end
    end
    fprintf('removing %i components (categories: %s)\n',...
        sum(rej), strjoin(reason(~cellfun(@isempty, reason)), ', '));
    EEG = remember_old_ICs(EEG, rej);
end
end

function [EEG, P] = detect_SASICA_ICs(EEG, CFG, P)
% don't run SASICA if one of the other options is active
if CFG.do_SASICA
    assert((CFG.do_SASICA & ~CFG.do_corr_ica & ~CFG.do_iclabel_ica &...
        ~CFG.do_eyetrack_ica), ['Currently, Elektro-Pipe can''t combine'...
        ' SASICA with other IC detection methods.']);
    [EEG, com] = SASICA(EEG);
    % try to get the handle of the 'compute' button and click it
    % automatically
    S = findall(0, 'name', 'Select ICA components');
    OK = S.Children(strcmp(get(S.Children, 'tag'), 'push_ok'));
    if strcmp(P.autoclick, 'yes')
        OK.Callback(S,1);
    end
    fprintf(2, 'Hit continue or F5 to proceed!\n')
    keyboard; % wait for user to fiddle around with SASICA
    
    % ask user if 'compute' button should be clicked automatically
    if strcmp(P.autoclick, 'no')
        P.autoclick = questdlg(['Would you like to apply the same SASICA ',...
            'configuration to all subsequent files?'],...
            'Click compute automatically?',...
            'yes', 'no', 'don''t ask again', 'yes');
    end
    
    EEG = evalin('base', 'EEG'); % SASICA stores the results in base workspace via assignin. So we have to use this workaround...
end
end