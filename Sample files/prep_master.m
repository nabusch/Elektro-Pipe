clear all;
close all;

addpath(genpath('~/Code/Elektro-Pipe/'));
addpath(genpath('/data/home/nbusch/Matlab/Toolboxes/eeglab13_6_5b/'));


EP.cfg_file = '/data2/Niko/AlphaIcon/Analysis/getcfg.m';
EP.st_file  = '/data2/Niko/AlphaIcon/Analysis/SubjectsTable.xlsx';

% EP.who = 1; % Single numerical index.
EP.who = [1]; % Vector of numerical indices.
% EP.who = 'AI01'; % Single string.
% EP.who = {'Name', {'AI01', 'AI02'}}; % One pair of column name and requested values.
% EP.who = {'Name', {'AI01', 'AI03'}; 'Include', 1; 'has_import', 0}; % Multiple columns and values. Only subjects fullfilling all criteria are included.

% S = readtable(EP.st_file);
% EP.who = S.Name(find(S.ICA==0 | S.prep4ICA==1));

%% Import and automatic preprocessing.
EEG = prep01_preproc(EP);

%% Semi-automatic prepartion for ICA.
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab('nogui');
prep02_cleanbeforeICA;

%% Run ICA.
EEG = prep03_runICA(EP);

%% Reject ICA components.
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab('nogui');
prep04_rejectICs;

