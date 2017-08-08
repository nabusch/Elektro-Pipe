clear;
close all;

%-----------------------------------
% add EEGlab and Elekto-Pipe to path
%-----------------------------------
addpath(genpath('~/Elektro-Pipe/'));
addpath(genpath('~/eeglab13_6_5b/'));

%un-shadow the fileio in WM-utilities. This is really specific to th
%eprocedures in our lab at a special moment in history, so probably nothing
%to worry about.
% tmp = which('16_Bit_triggers/pop_fileio.m');
% addpath(genpath(tmp(1:regexp(tmp,'pop_fileio.m')-1)));


%%make sure we're in the proper directory, so all paths are relative to the
%%location of this file (and hence system-independent)
rootfilename    = which('prep_master.m');
rootpath        = rootfilename(1:strfind(rootfilename,[filesep,'Analysis',filesep,'EEG']));
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

%% PREP-1: Import and automatic preprocessing.
try
    prep01_preproc(EP);
    %Send a notification via email when done or throwing error
    system(['echo "Import and automatic preprocessing done!" | mail -s "Elektropipe notification" email@address.com']);
catch ME
    system(['echo "',ME.message,'" | mail -s "Elektropipe notification" email@address.com']);
end
%% PREP-2: Semi-automatic preparation for ICA.
prep02_cleanbeforeICA;

%% PREP-3: Run ICA.
try
    prep03_runICA(EP);
    %Send a notification via email when done or throwing error
    system(['echo "All ICA computations done!" | mail -s "Elektropipe notification" email@address.com']);
catch ME
    system(['echo "',ME.message,'" | mail -s "Elektropipe notification" email@address.com']);
end
%% PREP-4: Reject ICA components.
prep04_rejectICs(EP);
