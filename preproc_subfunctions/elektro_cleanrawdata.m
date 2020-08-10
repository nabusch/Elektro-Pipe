function [EEG, EP] = elektro_cleanrawdata(EEG, CFG, EP, id_idx)
%
% wm: THIS FUNCTION STILL NEEDS A PROPER DOCUMENTATION!

% (c) Niko Busch & Wanja Mössing
% (contact: niko.busch@gmail.com, w.a.moessing@gmail.com)
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

elektro_status('Running clean_rawdata artifact removal');

if CFG.rej_cleanrawdata
    dirtyEEG = EEG;
    
    %% first run removal of bad channels
    subargs = CFG.rej_cleanrawdata_args;
    varargaschar = cellfun(@(x) fastif(isnumeric(x), num2str(x), x), subargs, 'uni', 0);
    if ismember({'BurstCriterion'}, varargaschar)
        subargs(find(strcmp(varargaschar, {'BurstCriterion'})) + 1) = {'off'};
    else
        subargs{end + 1} = 'BurstCriterion';
        subargs{end + 1} = 'off';
    end
    if ismember({'WindowCriterion'}, varargaschar)
        subargs(find(strcmp(varargaschar, {'WindowCriterion'})) + 1) = {'off'};
    else
        subargs{end + 1} = 'WindowCriterion';
        subargs{end + 1} = 'off';
    end
    
    %run algo without ASR -- just channel detection
    FOO = clean_artifacts(dirtyEEG, subargs{:});
    
    %keep history
    com = sprintf('FOO = clean_artifacts(EEG, %s)',...
        cell2com(subargs));
    dirtyEEG = eegh(com, dirtyEEG);
    
    % now exclude the channels that should not be removed from the mask
    % (e.g., IO1)
    if ~isfield(FOO.etc, 'clean_channel_mask')
        FOO.etc.clean_channel_mask = ones(1, length(dirtyEEG.chanlocs));
    end
    interp_chans = {dirtyEEG.chanlocs(~FOO.etc.clean_channel_mask).labels};
    idx = ismember(interp_chans, CFG.rej_cleanrawdata_dont_interp);
    interp_chans = interp_chans(~idx);
        
    % remove these channels
    [preASR, com] = pop_select(dirtyEEG, 'nochannel', interp_chans);
    preASR = eegh(com, preASR);
    
    
    %% run ASR without the dirty channels
    subargs = CFG.rej_cleanrawdata_args;
    varargaschar = cellfun(@(x) fastif(isnumeric(x), num2str(x), x), subargs, 'uni', 0);
    if ismember({'ChannelCriterion'}, varargaschar)
        subargs(find(strcmp(varargaschar, {'ChannelCriterion'})) + 1) = {'off'};
    else
        subargs{end + 1} = 'ChannelCriterion';
        subargs{end + 1} = 'off';
    end
    if ismember({'FlatlineCriterion'}, varargaschar)
        subargs(find(strcmp(varargaschar, {'FlatlineCriterion'})) + 1) = {'off'};
    else
        subargs{end + 1} = 'FlatlineCriterion';
        subargs{end + 1} = 'off';
    end
    % run algo
    diaryfile = keep_diary(CFG);
    EEG = clean_artifacts(preASR, subargs{:});
    EP = read_diary(EP, diaryfile, id_idx);
    
    % keep history
    com = sprintf('EEG = clean_artifacts(EEG, %s)',...
        cell2com(subargs));
    EEG = eegh(com, EEG);
    
    try %this won't work if no channels have been detected
        EEG.etc.elektro.cleanrawdata.interp_chans = ...
            {dirtyEEG.chanlocs(~EEG.etc.clean_channel_mask).labels};
        EP.S.cleanrawdata_chans_removed(id_idx) =...
            length(EEG.etc.elektro.cleanrawdata.interp_chans);
        fprintf('Removed these chans: %s\n',...
            strjoin(EEG.etc.elektro.cleanrawdata.interp_chans, ', '));
    end
    % if desired, interpolate the removed channels
    if CFG.rej_cleanrawdata_interp
        % the com output of pop_interp is broken...
        bad_chans = {dirtyEEG.chanlocs.labels};
        good_chans = {EEG.chanlocs.labels};
        bad_chans = bad_chans(~ismember(bad_chans, good_chans));
        EEG = pop_interp(EEG, dirtyEEG.chanlocs, 'spherical');
        com = strjoin(bad_chans, ''', ''');
        com = sprintf('EEG = eeg_interp(EEG), {''%s''}', com);
        EEG = eegh(com, EEG);
    end
    
end
end

function [com] = cell2com(X)
com = cellfun(@(x) fastif(isnumeric(x) & length(x) > 1,...
    ['[' num2str(x) ']'], fastif(isnumeric(x), num2str(x),['''' x ''''])),...
    X, 'Uni', 0);
com = strjoin(com, ', ');
end

function [EP] = read_diary(EP, diaryfile, id_idx)
diary('off');
fid = fopen(diaryfile);
wholediary = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
expr = 'Keeping (?<percent>\d+.\d+)%.\((?<sec>\d+).seconds\) of the data.';
allinfo = cellfun(@(x) regexp(x, expr, 'names'), wholediary, 'uni', 0);
info = allinfo{1}{find(~cellfun(@isempty, allinfo{1}), 1)};
EP.S.cleanrawdata_percent_kept_as_refdata(id_idx) = str2double(info.percent);
EP.S.cleanrawdata_seconds_kept_as_refdata(id_idx) = str2double(info.sec);

% try to find a second statement. That'd usually be the amount of data kept
% after ASR cleaning (i.e. 100 - removed).
if length(find(~cellfun(@isempty, allinfo{1}))) > 1
    info = allinfo{1}{find(~cellfun(@isempty, allinfo{1}), 2)};
    EP.S.cleanrawdata_percent_kept_after_asr(id_idx) = str2double(info.percent);
    EP.S.cleanrawdata_seconds_kept_after_asr(id_idx) = str2double(info.sec);
end
end

function [diaryfile] = keep_diary(CFG)
% keep a temporary diary, so we can store the information cleanrawdata
% prints to the command line
diaryfile = fullfile(CFG.dir_eeg, 'prep01_cleanrawdatalog.txt');
[~,~] = mkdir(CFG.dir_eeg);
warning('off', 'MATLAB:DELETE:FileNotFound');
delete(diaryfile);
warning('on', 'MATLAB:DELETE:FileNotFound');
diary(diaryfile);
diary('on');
end
