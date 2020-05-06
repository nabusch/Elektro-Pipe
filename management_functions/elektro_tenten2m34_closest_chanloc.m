function [elec, dist] = elektro_tenten2m34_closest_chanloc(wanted)
% ELEKTROTENTEN2M34_CLOSEST_CHANLOC finds the closest matching channel
%
% INPUT:
%       wanted: Name or index of desired 10-20 channel
%
% OUTPUT:
%       elec : name of closest M34 channel
%       dist : euclidean distance of the two channels (normalized)
%
%   Author: Wanja Moessing, moessing@wwu.de, Mar 2020
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

% initiate eeglab to read the locations of both layouts
eeglab('nogui');
%evalc to supress the extensive amount of message "readlocs" prints
[~, m34] = evalc('readlocs(''Custom_M34_V3_Easycap_Layout_EEGlab.sfp'')');
[~, tt] = evalc('readlocs(''standard-10-5-cap385.elp'')');

% wrangle tentwenty and M34 layouts into the same format (i.e., normalize
% 10-20
ttXYZ = [[tt.X]', [tt.Y]', [tt.Z]'] ./ 85; %cust is normalized
custXYZ = [[m34.X]', [m34.Y]', [m34.Z]'];

% find the index of the 10-20 label
if isnumeric(wanted)
    idx = wanted;
else
    idx = ismember({tt.labels}, wanted);
end
% compute euclidean distance between this channel and all channels on
% custom cap
distances = pdist2(ttXYZ(idx, :), custXYZ, 'euclidean');

% select the channel with the minimum distance
[dist, wantedidx] = min(distances);

% and get the label of this channel
elec = m34(wantedidx).labels;
end