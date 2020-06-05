function [EEG, CONTEEG] = elektro_cleanline(EEG, cfg, CONTEEG)
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

if cfg.do_cleanline
    disp('Running cleanline algorithm for segmented data (PREP version)...');
    % FFT before cleanline
    % select 2 random channels for visualization
    randchs = randsample(cfg.data_chans, 2);
    set(0,'DefaultFigureVisible','off');
    pop_fourieeg(EEG, randchs, [], 'EndFrequency', 100);
    winlength = EEG.pnts / EEG.srate;
    lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
        'lineNoiseChannels', cfg.data_chans,...
        'Fs', EEG.srate, ...
        'lineFrequencies', [50, 100],...
        'p', 0.01, ...
        'fScanBandWidth', 2, ...
        'taperBandWidth', 2, ...
        'taperWindowSize', winlength, ...
        'taperWindowStep', winlength, ...
        'tau', 100, ...
        'pad', 2, ...
        'fPassBand', [0 EEG.srate/2], ...
        'maximumIterations', 10);
    [EEG, ~] = cleanLineNoise(EEG, lineNoiseIn);
    com = struct2com(lineNoiseIn);
    com = sprintf('EEG = cleanLineNoise(EEG, %s)', com);
    EEG = eegh(com, EEG);
    
    % FFT after cleanline
    pop_fourieeg(EEG, randchs, [], 'EndFrequency', 100);
    disp('cleanline done.')
    
    if cfg.keep_continuous
        disp('Running cleanline algorithm for continuous data (PREP version)...');
        % FFT before cleanline
        pop_fourieeg(CONTEEG, randchs, [], 'EndFrequency', 100);
        
        %find winlength that takes into account all data points and is
        %between 3 and 4 seconds (cleanline recommendation). If that's not
        %possible, increase the range stepwise.
        K = 1:ceil(CONTEEG.pnts / 2);
        D = K(rem(CONTEEG.pnts, K) == 0);
        W = [];
        startrng = [3000, 4000];
        step = 10;
        i = 0;
        while ~any(W)
            i = i + 1;
            W = (CONTEEG.pnts./D >= startrng(1) - step * i) &...
                (CONTEEG.pnts./D <= startrng(2) + step * i);
        end
        
        %it's possible that we catch multiple possible values. In that case
        %simply use the first.
        W = find(W, 1);
        winlength = (CONTEEG.pnts / D(W)) / 1000;
        lineNoiseIn.taperWindowSize = winlength;
        lineNoiseIn.taperWindowStep = winlength;
        [CONTEEG, ~] = cleanLineNoise(CONTEEG, lineNoiseIn);
        com = struct2com(lineNoiseIn);
        com = sprintf('CONTEEG = cleanLineNoise(CONTEEG, %s)', com);
        CONTEEG = eegh(com, CONTEEG);
        
        % FFT after cleanline
        pop_fourieeg(CONTEEG, randchs, [], 'EndFrequency', 100);
        disp('cleanline done.')
    end
end
set(0, 'DefaultFigureVisible', 'on');
end

function [com] = struct2com(X)
com = structfun(@(x) fastif(length(x) > 1, ['[' num2str(x) ']'],...
    num2str(x)), X, 'Uni', 0);
com = [fieldnames(X), struct2cell(com)];
com = strjoin(arrayfun(@(x) ['''' com{x, 1} ''', ' com{x, 2}],...
    1:size(com, 1), 'Uni', 0), ', ');
end