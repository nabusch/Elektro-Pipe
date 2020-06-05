function [EEG] = elektro_prepfilter(EEG, cfg)
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

if cfg.do_lp_filter
    [m, ~] = pop_firwsord('blackman', EEG.srate, cfg.lp_filter_tbandwidth);
    [EEG, com] = pop_firws(EEG, 'fcutoff', cfg.lp_filter_limit, 'ftype',...
        'lowpass', 'wtype', 'blackman', 'forder', m);
    EEG = eegh(com, EEG);
end

if cfg.do_hp_filter
    switch(cfg.hp_filter_type)
        
        case('butterworth') % This is a function of the separate ERPlab toolbox.
            [EEG, com] = pop_ERPLAB_butter1( EEG, cfg.hp_filter_limit, 0, 5); % requires ERPLAB plugin
            EEG = eegh(com, EEG);
            
        case('kaiser')
            m = pop_firwsord('kaiser', EEG.srate, cfg.hp_filter_tbandwidth, cfg.hp_filter_pbripple);
            beta = pop_kaiserbeta(cfg.hp_filter_pbripple);
            
            [EEG, com] = pop_firws(EEG, 'fcutoff', cfg.hp_filter_limit, ...
                'ftype', 'highpass', 'wtype', 'kaiser', ...
                'warg', beta, 'forder', m);
            EEG = eegh(com, EEG);
        case('eegfiltnew')
            [EEG, com] = pop_eegfiltnew(EEG, cfg.hp_filter_limit, 0);
            %   >> [EEG, com, b] = pop_eegfiltnew(EEG, locutoff, hicutoff, filtorder,
%                                     revfilt, usefft, plotfreqz, minphase);
            EEG = eegh(com, EEG);
    end
end

if cfg.do_notch_filter
    [EEG, com] = pop_eegfiltnew(EEG, cfg.notch_filter_lower,...
        cfg.notch_filter_upper, [], 1);
    EEG = eegh(com, EEG);
end
end