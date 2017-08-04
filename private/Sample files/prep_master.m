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

%% Import and automatic preprocessing.
prep01_preproc(EP);
%Send a notification via email when done
%system(['echo "Import and automatic preprocessing done!" | mail -s "Elektropipe notification" email@address.com']);

%% Semi-automatic preparation for ICA.
prep02_cleanbeforeICA;

%% Run ICA.
EEG = prep03_runICA(EP);
%system(['echo "All ICA computations done!" | mail -s "Elektropipe notification" email@address.com']);

%% Reject ICA components.
EEG = prep04_rejectICs(EP);
