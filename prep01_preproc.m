function [] = prep01_preproc(EP)
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

%% Check dependencies
elektro_dependencies();

%% get environment variables
[cfg_dir, cfg_name, ~] = fileparts(EP.cfg_file);
addpath(cfg_dir);
EP.S = readtable(EP.st_file);
who_idx = get_subjects(EP);

%% load CFG files. This needs to happen outside parfor because of eval.
cfg_fun = str2func(cfg_name);
ALLCFG = arrayfun(@(x) cfg_fun(x, EP.S), who_idx, 'uni', 0);

%% loop over subjects and run various preparation steps
for isub = 1:length(who_idx)
    
    % get this subjects config
    CFG = ALLCFG{isub};
    
    % Write a status message to the command line.
    fprintf('\nNow importing subject %s, (number %d of %d to process).\n\n', ...
        CFG.subject_name, isub, length(who_idx));
    
    % Create output directory if necessary.
    [~, ~] = mkdir(CFG.dir_eeg);
    
    % --------------------------------------------------------------
    % Import Biosemi raw data.
    % --------------------------------------------------------------
    elektro_status('Importing rawdata');
    bdfname = [CFG.dir_raw CFG.subject_name '.bdf'];
    if ~exist(bdfname,'file')
        error('%s Does not exist!\n', bdfname)
    else
        fprintf('Importing %s\n', bdfname)
        EEG = pop_fileio(bdfname);
    end
    
    
    % --------------------------------------------------------------
    % Preprocessing (filtering etc.).
    % --------------------------------------------------------------
    [EEG, EP, CONTEEG] = func_prepareEEG(EEG, CFG, EP, who_idx(isub));
    
    
    % --------------------------------------------------------------
    % Import behavioral data .
    % --------------------------------------------------------------
    [EEG, CONTEEG] = func_importBehavior(EEG, CFG, CONTEEG);
    
    % --------------------------------------------------------------
    % Create quality plots
    % --------------------------------------------------------------
    print_quality_plots(CFG)
    
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    elektro_status('saving result');
    % Convert back to single precision.
    if CFG.keep_continuous
        CONTEEG.data = single(CONTEEG.data);
        [CONTEEG, com] = pop_editset(CONTEEG, 'setname', [CFG.subject_name ' importCONT']);
        CONTEEG = eegh(com, CONTEEG);
        pop_saveset( CONTEEG, [CFG.subject_name  '_importCONT.set'] , CFG.dir_eeg);
    end
    EEG.data = single(EEG.data);
    [EEG, com] = pop_editset(EEG, 'setname', [CFG.subject_name ' import']);
    EEG = eegh(com, EEG);
    pop_saveset(EEG, [CFG.subject_name  '_import.set'] , CFG.dir_eeg);
    
    % --------------------------------------------------------------
    % write info to spreadsheet
    % --------------------------------------------------------------
    EP.S.has_import(who_idx(isub)) = 1;
    writetable(EP.S, EP.st_file);
end

fprintf('Done.\n')
end

%% subfunction
function [] = print_quality_plots(CFG)
elektro_status('printing quality plots to postscript');
if exist([CFG.dir_eeg CFG.subject_name '_QualityPlots' '.ps'],'file')
    fprintf('Found an old version of ''%s''. Will overwrite it now.\n',...
        [CFG.subject_name '_QualityPlots' '.ps']);
    delete([CFG.dir_eeg CFG.subject_name '_QualityPlots' '.ps']);
end

h = get(0,'children');
for i=1:length(h)
    h(i).PaperOrientation = 'landscape';
    h(i).PaperType = 'A3';
    print(h(i), [CFG.dir_eeg CFG.subject_name '_QualityPlots'], '-dpsc','-append','-fillpage');
end
close all;
end