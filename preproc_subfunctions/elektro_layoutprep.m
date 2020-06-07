function [EEG] = elektro_layoutprep(EEG, cfg)
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

elektro_status('importing layout and constructing EOG channels');

[EEG, com] = pop_select(EEG, 'channel', cfg.data_urchans);
EEG = eegh(com, EEG);

if ~isempty(cfg.heog_chans)
    fprintf('Computing HEOG from channels %s and %s\n', ...
        EEG.chanlocs(cfg.heog_chans(1)).labels, ...
        EEG.chanlocs(cfg.heog_chans(2)).labels);
    
    iHEOG = EEG.nbchan + 1;
    EEG.nbchan = iHEOG;
    EEG.chanlocs(iHEOG) = EEG.chanlocs(end);
    EEG.chanlocs(iHEOG).labels = 'HEOG';
    EEG.data(iHEOG,:) = EEG.data(cfg.heog_chans(1),:,:) -...
        EEG.data(cfg.heog_chans(2),:,:);
end

if ~isempty(cfg.veog_chans)
    fprintf('Computing VEOG from channels %s and %s\n', ...
        EEG.chanlocs(cfg.veog_chans(1)).labels, ...
        EEG.chanlocs(cfg.veog_chans(2)).labels)
    
    iVEOG = EEG.nbchan + 1;
    EEG.nbchan = iVEOG;
    EEG.chanlocs(iVEOG) = EEG.chanlocs(end);
    EEG.chanlocs(iVEOG).labels = 'VEOG';
    EEG.data(iVEOG,:) = EEG.data(cfg.veog_chans(1),:,:) -...
        EEG.data(cfg.veog_chans(2),:,:);
end

[EEG, ~, ~, com] = pop_chanedit(EEG, 'lookup', cfg.chanlocfile);
EEG = eegh(com, EEG);
end