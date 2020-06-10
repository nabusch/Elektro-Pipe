function [EEG] = elektro_importref(EEG, CFG)
% we must reference here, as biosemi rawdata are reference free. Not
% referencing reduces SNR by 40dB!
%
% Moreover, as soon as we're using more than one channel as reference, we
% need to add a channel "initial reference" to avoid rank deficiency

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

elektro_status('Applying import reference');

if isempty(CFG.import_reference) | numel(CFG.import_reference) > 1
    % add zero-filled channel to avoid rank deficiency
    % see https://sccn.ucsd.edu/wiki/Makoto%27s_preprocessing_pipeline#Why_should_we_add_zero-filled_channel_before_average_referencing.3F_.2803.2F04.2F2020_Updated.29
    if isempty(CFG.import_reference)
        CFG.import_reference = CFG.data_chans;
        disp('Applying average reference based on CFG.data_chans during import...');
    end
    EEG.nbchan = EEG.nbchan + 1;
    EEG.data(end + 1,:) = zeros(1, EEG.pnts);
    EEG.chanlocs(1, EEG.nbchan).labels = 'initialReference';
    CFG.import_reference = [CFG.import_reference, EEG.nbchan];
    excl = find(~ismember(1:EEG.nbchan-1, CFG.data_chans)); %-1 to not delete new Ref chan
    [EEG, com] = pop_reref(EEG, CFG.import_reference,...
        'keepref', 'on', 'exclude', excl);
    EEG = pop_select(EEG, 'nochannel', {'initialReference'});
else
    excl = find(~ismember(1:EEG.nbchan, CFG.data_chans));
    [EEG, com] = pop_reref(EEG, CFG.import_reference,...
        'keepref', 'on', 'exclude', excl);
end
EEG = eegh(com, EEG);
end