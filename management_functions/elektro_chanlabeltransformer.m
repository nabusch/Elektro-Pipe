function [chanstr, channum, chanlog] = elektro_chanlabeltransformer(channels, chanlocs)
% ELEKTRO_CHANLABELTRANSFORMER takes a vector of string channel labels or
% numeric channel indices and returns both.
%
% INPUT:
%       channels: EITHER 1xN cell array with string labels
%                 OR     1xN numerical vector with indeces
%                 OR     1xN numerical vector with logical indeces
%                 OR     single string with a regex pattern
%       chanlocs: EEG.chanlocs
%
% OUTPUT:
%       chanstr : cell of channels as strings
%       channum : vector of channels as indeces
%       chanlog : vector of logical indeces
%
%   Author: Wanja Moessing, moessing@wwu.de, 17/01/2019
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

%% parse the kind of input
if isa(channels, 'cell')
    assert(all(cellfun(@ischar, channels)), 'Please don''t mix labels with indices!');
    disp('chanlabeltransformer: String vector of labels detected.');
    init_type = 'labels';
elseif isnumeric(channels)
    if all((channels == 1 | channels == 0)) &&...
            length(channels) == length(chanlocs)
        disp('chanlabeltransformer: Logical vector of indices detected.');
        init_type = 'logical';
        channels = logical(channels);
    else
        disp('chanlabeltransformer: Numeric vector of indices detected.');
        init_type = 'indices';
    end
elseif isa(channels, 'char')
    disp('chanlabeltransformer: Regex detected.');
    init_type = 'pattern';
elseif isa(channels, 'logical')
    disp('chanlabeltransformer: Logical vector of indices detected.');
    init_type = 'logical';
end

%% Decode labels
if strcmp(init_type, 'labels')
    chanlog = ismember({chanlocs.labels}, channels);
    channum = find(chanlog);
    chanstr = channels;
end

%% Decode indeces
if strcmp(init_type, 'indices')
    chanstr = {chanlocs(channels).labels};
    chanlog = ismember({chanlocs.labels}, chanstr);
    channum = channels;
end

%% Decode regex
if strcmp(init_type, 'pattern')
    chanlog = ~cellfun(@isempty, regexp({chanlocs.labels}, channels));
    chanstr = {chanlocs(chanlog).labels};
    channum = find(chanlog);
end

%% Decode logical
if strcmp(init_type, 'logical')
    assert(length(channels) == length(chanlocs),...
        ['Number of channels in logical index do not match the number',...
        ' of channels in the chanlocs struct']);
    chanstr = {chanlocs(channels).labels};
    channum = find(channels);
    chanlog = channels;
end

end