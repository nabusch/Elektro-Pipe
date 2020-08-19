function [EEG, com] = mypop_selectcomps( EEG, compnum, fig, selfcall );
% mypop_selectcomps() - 
% WM 03-2020 : Just like pop_selectcomps, but adjusted for usage in the
% elektro-pipe, together vie viewcomp
%
%
% Display components with button to vizualize their
%                  properties and label them for rejection.
% Usage:
%       >> OUTEEG = pop_selectcomps( INEEG, compnum );
%
% Inputs:
%   INEEG    - Input dataset
%   compnum  - vector of component numbers
%
% Output:
%   OUTEEG - Output dataset with updated rejected components
%
% Note:
%   if the function POP_REJCOMP is ran prior to this function, some 
%   fields of the EEG datasets will be present and the current function 
%   will have some more button active to tune up the automatic rejection.   
%
% Author: Arnaud Delorme, CNL / Salk Institute, 2001
%
% See also: pop_prop(), eeglab()

% Copyright (C) 2001 Arnaud Delorme, Salk Institute, arno@salk.edu
%
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

% 01-25-02 reformated help & license -ad 

% this function messes around with base workspace and local variables.
% Make sure there's no different copy of "EEG" in base
if nargin < 4
    selfcall = false; %check if it's a recursive call. only delete if first call.
end
if ~selfcall
    if evalin('base', 'exist(''EEG'')')
        if ~isequal(EEG, evalin('base', 'EEG'))
            warning(['Wanja: pop_selectcomps sometimes uses base workspace and '...
                'sometimes doesn''t. Found a copy of ''EEG'' in base that '...
                'differs from the local copy passed to this function. Will now '...
                'overwrite the version in base. Are you sure this is what you want?']);
            assignin('base', 'EEG', EEG);
        end
    end
    
    if evalin('base', 'exist(''EEG'')')
        if ~isequal(EEG, evalin('base', 'EEG'))
            warning(['Wanja: pop_selectcomps sometimes uses base workspace and '...
                'sometimes doesn''t. It also writes stuff in EEG and in ALLEEG.'...
                'Elektro-pipe never uses ALLEEG, so i am deleting it now in base.']);
            evalin('base', 'clear ALLEEG');
        end
    end
end
COLREJ = '[1 0.6 0.6]';
COLACC = '[0.75 1 0.75]';
PLOTPERFIG = 35;

com = '';
if nargin < 1
	help mypop_selectcomps;
	return;
end;	

if nargin < 2   
    compnum = 1:size(EEG.icaact, 1);
end
fprintf('Drawing figure...\n');
currentfigtag = ['selcomp' num2str(rand)]; % generate a random figure tag

%close all idling selcomp figures
% close(findobj('-regexp','tag','^selc.*'));

if length(compnum) > PLOTPERFIG
    for index = 1:PLOTPERFIG:length(compnum)
        EEG = mypop_selectcomps(EEG, compnum([index:min(length(compnum),index+PLOTPERFIG-1)]), [], true);
%         uiwait(findobj('-regexp','tag','^selc.*'));
    end

    com = [ 'pop_selectcomps(EEG, ' vararg2str(compnum) ');' ];
    return;
end

if isempty(EEG.reject.gcompreject)
	EEG.reject.gcompreject = zeros( size(EEG.icawinv,2));
end
try, icadefs; 
catch, 
	BACKCOLOR = [0.8 0.8 0.8];
	GUIBUTTONCOLOR   = [0.8 0.8 0.8]; 
end

% set up the figure
% -----------------
column =ceil(sqrt( length(compnum) ))+1;
rows = ceil(length(compnum)/column);
if exist('fig', 'var')
    if isempty(fig)
        figisempty = true;
    else
        figisempty = false;
    end
end

if ~exist('fig','var') | figisempty
	figure('name', [ 'Reject components by map - mypop_selectcomps() (dataset: ' EEG.setname ')'], 'tag', currentfigtag, ...
		   'numbertitle', 'off', 'color', BACKCOLOR);
	set(gcf,'MenuBar', 'none');
	pos = get(gcf,'Position');
	set(gcf,'Position', [pos(1) 20 800/7*column 600/5*rows]);
    incx = 120;
    incy = 110;
    sizewx = 100/column;
    if rows > 2
        sizewy = 90/rows;
	else 
        sizewy = 80/rows;
    end
    pos = get(gca,'position'); % plot relative to current axes
	hh = gca;
	q = [pos(1) pos(2) 0 0];
	s = [pos(3) pos(4) pos(3) pos(4)]./100;
	axis off;
end

% figure rows and columns
% -----------------------  
if EEG.nbchan > 64
    disp('More than 64 electrodes: electrode locations not shown');
    plotelec = 0;
else
    plotelec = 1;
end
count = 1;
for ri = compnum
    if exist('fig','var') & ~figisempty
        button = findobj('parent', fig, 'tag', ['comp' num2str(ri)]);
        if isempty(button)
            error( 'mypop_selectcomps(): figure does not contain the component button');
        end;
    else
		button = [];
	end;		
		 
	if isempty( button )
		% compute coordinates
		% -------------------
		X = mod(count-1, column)/column * incx-10;  
        Y = (rows-floor((count-1)/column))/rows * incy - sizewy*1.3;  

		% plot the head
		% -------------
        if ~strcmp(get(gcf, 'tag'), currentfigtag);
            figure(findobj('tag', currentfigtag));
        end
		ha = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q);
        if plotelec
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                      'off', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
        else
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                      'off', 'electrodes','off', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
        end
		axis square;

		% plot the button
		% ---------------
         if ~strcmp(get(gcf, 'tag'), currentfigtag);
             figure(findobj('tag', currentfigtag));
         end
		button = uicontrol(gcf, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
                           [X Y+sizewy sizewx sizewy*0.25].*s+q, 'tag', ['comp' num2str(ri)]);
%         command = sprintf('pop_prop_extended( EEG, 0, %d, gcbo, { ''freqrange'', [1 50] });', ri);
%         command = @(a,b,c,d,e,f,g) pop_prop_extended(c,d,e,f,g);
		set( button, 'callback',  {@sub_pop_prop_extended, EEG, 0, ri, gcbo, {'freqrange', [1 50]}});
	end
	set( button, 'backgroundcolor', eval(fastif(EEG.reject.gcompreject(ri), COLREJ,COLACC)), 'string', int2str(ri)); 	
	drawnow;
	count = count +1;
end

% draw the bottom button
% ----------------------
if ~exist('fig','var')
    if ~strcmp(get(gcf, 'tag'), currentfigtag);
        figure(findobj('tag', currentfigtag));
    end
	hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Cancel', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
			'Position',[-10 -10  15 sizewy*0.25].*s+q, 'callback', 'close(gcf); fprintf(''Operation cancelled\n'')' );
	hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Set threhsolds', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
			'Position',[10 -10  15 sizewy*0.25].*s+q, 'callback', 'pop_icathresh(EEG); mypop_selectcomps( EEG, gcbf);' );
	if isempty( EEG.stats.compenta	), set(hh, 'enable', 'off'); end;	
	hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'See comp. stats', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
			'Position',[30 -10  15 sizewy*0.25].*s+q, 'callback',  ' ' );
	if isempty( EEG.stats.compenta	), set(hh, 'enable', 'off'); end;	
	hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Help', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
			'Position',[70 -10  15 sizewy*0.25].*s+q, 'callback', 'pophelp(''pop_selectcomps'');' );
	command = '[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); eegh(''[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);''); close(gcf)';
	hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'OK', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
			'Position',[90 -10  15 sizewy*0.25].*s+q, 'callback',  {@closecomm, EEG});
			% sprintf(['eeg_global; if %d pop_rejepoch(%d, %d, find(EEG.reject.sigreject > 0), EEG.reject.elecreject, 0, 1);' ...
		    %		' end; pop_compproj(%d,%d,1); close(gcf); eeg_retrieve(%d); eeg_updatemenu; '], rejtrials, set_in, set_out, fastif(rejtrials, set_out, set_in), set_out, set_in));
end

com = [ 'mypop_selectcomps(EEG, ' vararg2str(compnum) ');' ];
uiwait(findobj('tag',currentfigtag));
return;		
end

function [EEG] = closecomm(a,b,EEG)
% ALLEEG = evalin('base', 'ALLEEG');
% CURRENTSET = evalin('base', 'CURRENTSET');
% [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
% EEG.history = eegh(EEG,'[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);');
close(gcf);
% assignin('caller', 'EEG', EEG);
end

function [fh, EEG, com] = sub_pop_prop_extended(a,b,c,d,e,f,g)
[fh, EEG, com] = pop_prop_extended(c,d,e,f,g);
while true
    try
        waitforbuttonpress
    catch
        break
    end
end
% uiwait(fh);
rejcomp = evalin('base', 'EEG.reject.gcompreject');
assert(sum(rejcomp ~= EEG.reject.gcompreject) <= 1, 'Base and current workspace got messed up!');
EEG.reject.gcompreject = rejcomp;
assignin('caller', 'EEG', EEG);
end