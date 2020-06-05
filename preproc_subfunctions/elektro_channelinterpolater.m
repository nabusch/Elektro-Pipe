function [EEG] = elektro_channelinterpolater(EEG, cfg, EP, id_idx)
% wm: THIS FUNCTION STILL NEEDS A PROPER DOCUMENTATION!
%
% note: the functions used for detection are part of clean_rawdata. As
% such, they're supposed to work on rawdata. In fact, running them on
% re-referenced data provides very different results.
%
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



%% set defaults
if ~isfield(cfg, 'interp_these')
    cfg.interp_these = {'spread'}; % mimicks old behavior --> backwards compatibility
end

if ~isfield(cfg, 'interp_plot')
    cfg.interp_plot = true;
end

%% first check if we already know about some noisy channels from the recording protocol
spread = check_spread(EEG, EP, id_idx, cfg);

%% Abort if interpolation turned off
if ~cfg.do_interp
    return
end

%% now check for flat and/or noisy channels
if any(ismember(cfg.interp_these, {'flat', 'noisy'}))
    disp('temporarily removing the non-scalp channels for bad channel detection');
    scalpEEG = pop_select(EEG, 'channel', cfg.data_chans);
end

flat = check_flat(scalpEEG, cfg);
[noise, ~] = check_noise(scalpEEG, cfg);

%% if configured, plot the data and highlight the detected bad channels
if cfg.interp_plot
    colors = cell(1, length(scalpEEG.chanlocs));
    colors(1, :) = {[0 0 0]};
    colors(1, noise) = {[1 0 0]};
    colors(1, flat) = {[0 1 0]};
    colors(1, spread) = {[0 0 1]};
    colors(1, spread & noise) = {[1 0 1]};
    colors(1, spread & flat) = {[0 1 1]};
    legend_as_title = ['red = noise, green = flat, blue = spread, ',...
        'pink = spread & noise, turquoise = spread & flat'];
    scalpEEG = pop_reref(scalpEEG, []);
    pop_eegplot(scalpEEG, 1, 1, 0, '', 'color', colors, 'winlength', 30,...
        'title', legend_as_title);
    uiwait(findobj('name', legend_as_title));
    list = {scalpEEG.chanlocs.labels};
    [selection, okayed] = listdlg('ListString', list,...
        'InitialValue', find(spread | noise | flat),...
        'Name', 'Select channels to interpolate', 'OKString',...
        'Interpolate', 'PromptString',...
        {'Please (un-)select the', 'to-be-interpolated', 'channels'});
%     close(findobj('name', legend_as_title));
    if ~okayed
        error('user cancelled');
    else
        foo = deal(false(size(spread)));
        foo(selection) = true;
        [spread, noise, flat] = deal(foo);
    end
end

%run actual interpolation
bad_chans = {scalpEEG.chanlocs(spread | flat | noise).labels};

if isempty(bad_chans)
    fprintf('No channels to interpolate.\n');
else
    disp(['You want to interplate channels prior to ICA.\n',...
        'If you proceed with Elektro-Pipe, ICA will be adjusted for \n',...
        'the reduced data rank.']);
    com = strjoin(bad_chans, ''', ''');
    fprintf('Interpolating channel(s): ''%s''\n', com);
    EEG = eeg_interp(EEG, find(ismember({EEG.chanlocs.labels}, bad_chans)));
    EEG.etc.elektro.interpolated_chans = bad_chans;
    com = sprintf('EEG = eeg_interp(EEG), {''%s''}', com);
    EEG = eegh(com, EEG);
end
end

%% subfunctions
function [spread, EEG] = check_spread(EEG, EP, id_idx, cfg)
spread = false(length(EEG.chanlocs), 1);
if ismember('interp_chans', EP.S.Properties.VariableNames) &&...
        ismember('spread', cfg.interp_these)
    spread_idx = EP.S.interp_chans(id_idx);
    spread_idx = spreadlabelparser(spread_idx, EEG);
    spread(spread_idx) = true;
end
spread = spread(cfg.data_chans);
EEG.etc.elektro.spreadsheet_interp_chans = {EEG.chanlocs(spread_idx).labels};
end

function [flat] = check_flat(EEG, cfg)
flat = false(length(EEG.chanlocs), 1);
if ismember('flat', cfg.interp_these)
    fprintf('detecting flat channels (potentially removing them from the temporary dataset)...');
    out = clean_flatlines(EEG);
    if isfield(out.etc, 'clean_channel_mask')
        flat = ~out.etc.clean_channel_mask;
    else
        disp('none')
    end
end
end

function [noise, EEG] = check_noise(EEG, cfg)
noise = false(length(EEG.chanlocs), 1);
if ismember('noisy', cfg.interp_these)
    fprintf('detecting noisy channels (potentially removing them from the temporary dataset)...\n');
    disp('high-pass filter for noisy channel detection (only temporary)');
    EEG = clean_drifts(EEG);
    noise = clean_channels(EEG);
    if isfield(noise.etc, 'clean_channel_mask')
        noise = ~noise.etc.clean_channel_mask;
    else
        disp('none');
    end
end
end

function [interp_chans] = spreadlabelparser(interp_chans, EEG)
%interp_chans is cell, as soon as one of the subjects has a channel to
%be interpolated...
if iscell(interp_chans)
    %check if cell is empty
    if cellfun(@isempty, interp_chans)
        interp_chans = [];
        return
    else
        % For multiple channels, split string by , or ;
        if ismember(',',interp_chans{:})
            interp_chans = strsplit(interp_chans{:},',');
        elseif ismember(';',interp_chans{:})
            interp_chans = strsplit(interp_chans{:},';');
        else
            disp(['Did not find comma or semicolon in interp_chan, assuming'...
                ' there''s just one channel to interpolate']);
        end
        % check if channels have been entered as labels (e.g., Pz) or as index
        isnumber = isstrprop(interp_chans,'digit');
        clear islabel
        for i = 1:size(isnumber,1)
            islabel(i) = ~all(isnumber{i});
        end
        %assure that excel table is consistent
        if ~(all(islabel) || all(~islabel))
            error(['Please use consistent labeling of channels to '...
                'interpolate. It appears some are index and some are '...
                'label (e.g., "A17,64" instead of "A17,B32" or "17,64")']);
        elseif all(islabel)
            % if it's labels, find the indeces.
            out = find(ismember({EEG.chanlocs.labels}, interp_chans));
        elseif all(~islabel)
            out = str2double(interp_chans);
        end
        interp_chans = out;
    end
else
    interp_chans = [];
end
end