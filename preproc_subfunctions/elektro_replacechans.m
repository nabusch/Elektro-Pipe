function [EEG] = elektro_replacechans(EEG, EP, id_idx)
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

channels_need_replacement = true;
try % will fail for cells (i.e., when some IDs need replacement but not this one)
    if isempty(EP.S.replace_chans(id_idx)) || isnan(EP.S.replace_chans(id_idx))
        fprintf('No channels to replace.\n');
        channels_need_replacement = false;
    end
catch
    if isempty(cell2mat(EP.S.replace_chans(id_idx)))
        fprintf('No channels to replace.\n');
        channels_need_replacement = false;
    end
end
if channels_need_replacement
    replace_chans = str2num(cell2mat(EP.S.replace_chans(id_idx)));
    for ichan = 1:size(replace_chans, 1)
        bad_chan  = replace_chans(ichan, 1);
        good_chan = replace_chans(ichan, 2);
        
        EEG.data(bad_chan,:) = EEG.data(good_chan, :);
        com = sprintf('Replacing bad electrode %d with good electrode %d.\n', ...
            bad_chan, good_chan);
        EEG = eegh(com, EEG);
        disp(com);
    end
end
end