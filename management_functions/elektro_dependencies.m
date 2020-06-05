function [] = elektro_dependencies()
%ELEKTRO_DEPENDENCIES checks ElektroPipe's Dependencies
%  This function is intended as a straight-forward check at the beginning
%  of each run of Elektro-Pipe to avoid compatibility issues.
%
% author: Wanja Moessing, moessing@wwu.de, September 2019

%  Copyright (C) 2019- Wanja Moessing
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


% start with empty error message
msg = '';

%% check dependencies

% firfilt version needs to be >= 2.4
installed = getver('eegplugin_firfilt.m');
desired = '2.4.0';
if ~compare_semantics(installed, desired, '>=')
    msg = mkmsg('firfilt', desired, msg);
end

% eye_eeg version needs to be >= 0.85
installed = getver('eegplugin_eye_eeg.m');
desired = '0.85';
if ~compare_semantics(installed, desired, '>=')
    msg = mkmsg('eye_eeg', desired, msg);
end

% iclabel >= 1.25 (below might work but not tested)
installed = getver('eegplugin_iclabel.m');
desired = '1.2.5';
if ~compare_semantics(installed, desired, '>=')
    msg = mkmsg('iclabel', desired, msg);
end

% ViewProps >= 1.5.4 (below might work but not tested)
installed = getver('eegplugin_viewprops.m');
desired = '1.5.4';
if ~compare_semantics(installed, desired, '>=')
    msg = mkmsg('viewprops', desired, msg);
end

% erplab for plots in func_prepareEEG
installed = getver('erplab_default_values.m');
desired = '7.0';
if ~compare_semantics(installed, desired, '>=')
    msg = mkmsg('viewprops', desired, msg);
end

% PREP pipe for new cleanline and robust reference
installed = regexprep(getPrepVersion, 'PrepPipeline', '');
desired = '0.55.3';
if ~compare_semantics(installed, desired, '>=')
    msg = mkmsg('PREP', desired, msg);
end


% clean rawdata for channel cleanup
installed = getver('eegplugin_clean_rawdata.m');
desired = '2.1';
if ~compare_semantics(installed, desired, '>=')
    msg = mkmsg('PREP', desired, msg);
end

if ~isempty(msg)
    error(msg);
end

end

function msg = mkmsg(name, ver, msg)
msg = sprintf(['%sElektroPipe dependency not met: Please update %s to ',...
    'version %s or higher\n'], msg, name, ver);
end

function ver = getver(funname)
ver = cell2mat(regexp(regexp(fileread(funname),...
    "ver\w* = '\w*[\.\d]*'", 'match'), '[\d\.]*', 'match', 'once'));
end

function [major, minor, patchlevel] = parse_semantic(ver)
ver = cellfun(@str2num, strsplit(ver, '.'));
% allow for plugins that don't strictly follow semantic versioning
n = numel(ver);
if n < 3
    ver(n+1:3) = 0;
end
major = ver(1);
minor = ver(2);
patchlevel = ver(3);
end

function status = compare_semantics(installed, threshold, desired)
status = '<';
[I.maj, I.min, I.patch] = parse_semantic(installed);
[T.maj, T.min, T.patch] = parse_semantic(threshold);

if I.maj > T.maj
    status = '>';
elseif I.maj == T.maj
    if I.min > T.min
        status = '>';
    elseif I.min == T.min
        if I.patch > T.patch
            status = '>';
        elseif I.patch == T.patch
            status = '=';
        end
    end
end

if (strcmp(desired, '>=') && ismember(status, '>=')) ||...
        (strcmp(desired, '=') && strcmp(status, '=')) ||...
        (strcmp(desired, '<=') && ismember(status, '<='))
    status = true;
else
    status = false;
end
end