function [EEG] = elektro_cleanrawdata(EEG, CFG)
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
    EEG = clean_artifacts(EEG, CFG.rej_cleanrawdata_args{:});
    com = sprintf('EEG = clean_artifacts(EEG, %s)',...
        cell2com(CFG.rej_cleanrawdata_args));
    EEG = eegh(com, EEG); 
    EEG.etc.elektro.cleanrawdata.interp_chans = ...
        {dirtyEEG.chanlocs(~EEG.etc.clean_channel_mask).labels};
    
    % if desired, interpolate the removed channels
    if CFG.rej_cleanrawdata_interp
        EEG = pop_interp(EEG, dirtyEEG.chanlocs, 'spherical');
    end
end
end

function [com] = cell2com(X)
com = cellfun(@(x) fastif(isnumeric(x) & length(x) > 1,...
    ['[' num2str(x) ']'], fastif(isnumeric(x), num2str(x),['''' x ''''])),...
    X, 'Uni', 0);
com = strjoin(com, ', ');
end