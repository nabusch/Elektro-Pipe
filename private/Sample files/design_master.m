%% "Master file" that runs the grand average for all ERPs from all subjects.
clear ALLCOM ALLEEG CURRENTSET CURRENTSTUDY EEG EP LASTCOM PLUGINLIST ans;
eeglab('nogui');
close all;

addpath(genpath('~\Elektro-Pipe\'));

% Add path to my experiment. This makes sure that when we use get_cfg and
% get_design, we load it from the top-most path. This is importnat because
% many experiments and also the Samples folder of the EP code folder
% contain files with this name.
EP.dir_experiment = ''; %e.g., '/data/ExperimentName/
EP.EEG_Analysis_Folder = ''; % the subfolder containing code for the current project e.g., 'Analysis/EEG/'
%% Define the EP structure (EP for Elektro Pipe). 
% REQUIRED INPUTS:

% Load the subjects table.
addpath(fullfile([EP.dir_experiment filesep EP.EEG_Analysis_Folder]));
EP.S = readtable('.xlsx'); %name of SubjectTable Excel-sheet.

% Summary name for this project. Determines name of output folder.
EP.project_name = ''; %e.g., Grand_ERP_encoding or ER-TFA ...

% Load the design file. The "D" structure contains information on the
% factors and factor levels of the design.
addpath(fullfile([EP.dir_experiment filesep EP.EEG_Analysis_Folder]));
EP.D = get_design;

% Define the configuration file as a string. It does not make sense to
% actually load the cfg file with getcfg here, because we later need the
% subject-specific cfg file that includes file paths for this each subject.
addpath(fullfile([EP.dir_experiment filesep EP.EEG_Analysis_Folder]));
EP.cfgfile = which('get_cfg');

% While the cfg file defines where the EEG data are located, there are
% probably multiple files in that folder. E.g. the different steps of the
% preprocessing or different bandpass filter settings. This variable
% defines the filename suffix we are interested in.
EP.filename_in = '_ICArej';

% Folder where the EEG data are located. We cannot use the dirs defined in
% the cfg file (e.g. by pointing to cfg.dir_eeg) because we do not know
% which directory we will want to use. It could be cfg.eeg or cfg.fft or
% cfg.eeg_hilbert etc. So we must define it here.
EP.dir_in = [EP.dir_experiment, filesep, 'EEG'];

% Folder where to store the results. Elektropipe will make separate
% subfolders in dir_out, one for each design.
EP.dir_out = [EP.dir_experiment, filesep, 'EEG-Results', filesep,...
    EP.project_name];

% What exactly do you want to do?
% - erp: grand average ERP.
% - tf:  Subject-wise wavelet analysis.
% - fft: Subject-wise fft analysis.
EP.process = ''; 

% ----------------------------------------------------------------------
% OPTIONAL INPUTS: Which subjects to use. You can use multiple selection
% criteria. Note: criteria must be separated by semicolon! Default: all = []
% subjects
EP.who = [];
% EP.who = 1:3;
% EP.who = {'pseudo', {'ADI029', 'ADI030', 'ADI052'}}; % use only subjects with a given value in field "pseudo" (any of these values).
%EP.who = {'Include', {1}};
% EP.who = {'Name', {'AI01', 'AI03'}; 'Include', 1; 'has_import', 0}; % Multiple columns and values. Only subjects fullfilling all criteria are included.

% Which design in D to use. Default: use all designs = [].
EP.design_idx = []; 

% Turn on/off command line messages as much as possible.
EP.verbose = 0;

% keep results in double precision or convert it to single (works only for
% run_tf for now).
EP.keepdouble = 0;

% Store single trial files?
% If true, this will create a subfolder in the output folder, containing
% one file per subject with the single-trial data. Average data are
% unaffected by this setting.
EP.singletrialTF = 0;
EP.singletrialFFT = 1; 

%% Run process for all designs and subejcts.
% Required input:
% EP: struct containing parameters for the computation. See above.
switch EP.process
    case 'erp'
        design_erp_grandaverage(EP);
    case 'tf'
        design_runtf(EP);
    case 'fft'
        tic;
        design_runFFT(EP);
        toc;
end
elektro_notify('moessing@wwu.de', [EP.process, ' done!']);
disp('done.')
