%-----------------------------------
% Make sure dependencies are available
%-----------------------------------
% you should have recent eeglab and Elektro-Pipe in your matlab-path
% we launch eeglab once, to make sure it loads all the plugins
clear all;
eeglab;
close all;

% un-shadow the fileio in WM-utilities. This is really specific to the
% procedures in our lab. We need to split a 16 bit binary code into two
% 8-bit codes due to the way our trigger-devices are wired. standard
% file-io is likely added with the 'eeglab' command above. So we make sure
% the modded version is used. If you don't have this version, you can
% download it at github.com/wanjam/wm_utilities
tmp = which('16_Bit_triggers/pop_fileio.m');
addpath(genpath(tmp(1:regexp(tmp,'[\\|/]pop_fileio.m'))));

% make sure we're in the proper directory, so all paths are relative to the
% location of this file (and hence system-independent)
fname    = which('veasna_prep_master.m');
rootpath = fname(1:regexp(fname,'[\\|/]Analysis[\\|/]'));
cd(rootpath);
addpath(genpath(rootpath));

%-----------------------------------
% specify location of getcfg.m & SubjectsTable.xlsx
%-----------------------------------
EP.cfg_file = ''; %e.g., '/data/ExperimentName/Analysis/getcfg.m';
EP.st_file  = ''; %e.g., '/data/ExperimentName/Analysis/SubjectsTable.xlsx';

%-----------------------------------
% which subjects should be preprocessed?
%-----------------------------------
% EP.who = 1; % Single numerical index.
EP.who = [1:10]; % Vector of numerical indices.
% EP.who = 'AI01'; % Single string.
% EP.who = {'Name', {'AI01', 'AI02'}}; % One pair of column name and requested values.
% EP.who = {'Name', {'AI01', 'AI03'}; 'Include', 1; 'has_import', 0}; % Multiple columns and values. Only subjects fullfilling all criteria are included.

% S = readtable(EP.st_file);
% EP.who = S.Name(find(S.ICA==0 | S.prep4ICA==1));

%-----------------------------------
% Should subjects be processed in parallel (faster, but hard to debug)?
%-----------------------------------
EP.prep_parallel = 0; % 0 = serial, N = use N cores, Inf = use max cores

%% PREP-1: Import and automatic preprocessing.
try
    prep01_preproc(EP);
    %Send a notification via email when done or throwing error
    elektro_notify('YOUR@EMAIL.ADDRESS',...
	 'Import and preprocessing done!')
catch ME
    elektro_notify('YOUR@EMAIL.ADDRESS', ME);
end

%% PREP-2: Semi-automatic preparation for ICA.
prep02_cleanbeforeICA;

%% PREP-3: Run ICA.
try
    prep03_runICA(EP);
    %Send a notification via email when done or throwing error
    elektro_notify('YOUR@EMAIL.ADDRESS', 'All ICA computations done!')
catch ME
    elektro_notify('YOUR@EMAIL.ADDRESS', ME);
end

%% PREP-4: Reject ICA components.
prep04_rejectICs(EP);
