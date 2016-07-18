function mypop_eegplot(EEG, icacomp, superpose, reject ,varargin)

% same as pop_eegplot except that you can select single electrodes on
% individual trials.
% global ALLEEG CURRENTSET
if nargin < 1
	help pop_eegplot;
	return;
end;	
if nargin < 2
	icacomp = 1;
end;	
if nargin < 3
	superpose = 0;
end;
if nargin < 4
	reject = 0;
end;

myoptions = {'ctrlselectcommand'
    {'eegplot_selectelec(gcbf);', ...
    'eegplot(''defmotioncom'', gcbf);', ...
    'eegplot(''defupcom'',     gcbf);'};
    };
topcommand = '';

pop_eegplot(EEG, icacomp, superpose, reject ,topcommand,varargin{:},myoptions{:});





