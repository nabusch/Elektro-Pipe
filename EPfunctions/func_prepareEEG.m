function [EEG, CONTEEG] = func_prepareEEG(EEG, cfg, EP, id_idx)
%
% wm: THIS FUNCTION STILL NEEDS A PROPER DOCUMENTATION!

% (c) Niko Busch & Wanja Mössing (contact: niko.busch@gmail.com)
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


%% Convert data to double precision
%recommended for filtering and other procedures.
EEG.data = double(EEG.data);

% if user specified to keep continuous data, CONTEEG is created as second
% output argument. If cfg.keep_continuous is false, output empty dummy.
CONTEEG = struct();

% --------------------------------------------------------------
% Replace channels as indicated in the spreadsheet
% --------------------------------------------------------------
EEG = elektro_replacechans(EEG, EP, id_idx);

% --------------------------------------------------------------
% Delete unwanted channels and import channel locations.
% --------------------------------------------------------------
EEG = elektro_layoutprep(EEG, cfg);

% --------------------------------------------------------------
% Filter the data.
% --------------------------------------------------------------
EEG = elektro_prepfilter(EEG, cfg);

% --------------------------------------------------------------
% Downsample data.
% --------------------------------------------------------------
if ~isempty(cfg.new_sampling_rate)
    [EEG, com] = pop_resample(EEG, cfg.new_sampling_rate);
    EEG = eegh(com, EEG);
end

% --------------------------------------------------------------
% Apply reference
% --------------------------------------------------------------
EEG = elektro_preprocref(EEG, cfg, EP);

%---------------------------------------------------------------
% Remove all events from non-configured trigger devices
%---------------------------------------------------------------
if isfield(EEG.event,'device') && ~isempty(cfg.trigger_device)
    fprintf('\nRemoving all event markers not sent by %s...\n',cfg.trigger_device);
    [EEG, ~, com] = pop_selectevent( EEG, 'device', cfg.trigger_device, 'deleteevents','on');
    EEG = eegh(com, EEG);
end

% --------------------------------------------------------------
% Import Eyetracking data.
% --------------------------------------------------------------
EEG = elektro_importEye(EEG, cfg);

% --------------------------------------------------------------
% Interpolate bad channels
% --------------------------------------------------------------
EEG = elektro_channelinterpolater(EEG, cfg, EP, id_idx);

% --------------------------------------------------------------
% Epoch the data.
% --------------------------------------------------------------
[EEG, CONTEEG] = elektro_epoch(EEG, cfg, CONTEEG);

%---------------------------------------------------------------
% check latencies of specific triggers within epochs
%---------------------------------------------------------------
[EEG, CONTEEG] = elektro_checklatency(EEG, cfg, CONTEEG);

% --------------------------------------------------------------
% Remove 50Hz line noise using Tim Mullen's cleanline.
% --------------------------------------------------------------
[EEG, CONTEEG] = elektro_cleanline(EEG, cfg, CONTEEG);

% --------------------------------------------------------------
% Detrend the data.
% This is an external function provided by Andreas Widmann:
% https://github.com/widmann/erptools/blob/master/eeg_detrend.m
% (now also distributed along with EP)
% --------------------------------------------------------------
if cfg.do_detrend
    EEG = eeg_detrend(EEG);
    EEG = eegh('EEG = eeg_detrend(EEG);% https://github.com/widmann/erptools/blob/master/eeg_detrend.m', EEG);
end
end
