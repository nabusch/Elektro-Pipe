function [h, c] = func_plot_tf(TF,conds,varargin)
% FUNC_PLOT_TF(TF,conds,varargin) creates a simple time-frequency plot
% 
% func_plot_tf(TF,conds,varargin) creates a simple Time-Frequency plot. 
% It is designed to be directly applicable to the output of design_runtf().
%
% Output:
%       h: figure handle
%       c: colorbar handle
%
% Required input:
%       TF: Struct with (minimum) fields 'pow'(power: powPerFreq*time*chan), 
%           'chanloc','freqs','times','condition'. Each row should contain
%           data for one condition.
%       conds: indeces of conditions over which to average data for
%              plotting.
%
% Keywords for optional input: 
%       'scale': can be 'absmax', 'minmax'(default) or a vector [min max]
%       'smoothness': the ncontours of contourf(). Default=49
%       'title': title for the plot. default is 'off'.
%       'xlab': x-label for the plot. default is 'off'.
%       'ylab': y-label for the plot. default is 'off'.
%       'chans': vector containing numerical indeces or cell vector
%                containing the desired channel-names. The resulting plot
%                will show the averaged data of all indicated channels.
%                Default is all channels.
%       'tlim' : numerical vector indicating the time-interval to plot.
%                Default is [min max]
%       'freqs': Numerical vector of frequency-limit to plot. Default is [min max];
%       'unit': string. The function doesn't know what unit your data are
%                in. Specify a string here to print it next to the scale. 
%
% Wanja Moessing (moessing@wwu.de) Dec 6, 2016

%% input checks
p = inputParser;
p.FunctionName = 'funct_plot_tf';
p.addRequired('TF',@isstruct);
p.addRequired('conds',@isnumeric);
p.addOptional('chans',1:size(TF(1).pow,3),@(x) length(unique(x))==length(x));
p.addOptional('scale','minmax',@(x) isnumeric(x) && length(x)==2);
p.addOptional('smoothness',48,@isnumeric);
p.addOptional('title','off',@isstr);
p.addOptional('xlab','off',@isstr);
p.addOptional('ylab','off',@isstr);
p.addOptional('tlim','minmax',@(x) isnumeric(x) && length(x)==2);
p.addOptional('freqs','minmax',@(x) isnumeric(x) && length(x)==2);
p.addOptional('unit','',@isstr);
parse(p,TF,conds,varargin{:})

%% Transform input
chans       = p.Results.chans;
scale       = p.Results.scale;
smoothness  = p.Results.smoothness;
titl        = p.Results.title;
xlab        = p.Results.xlab;
ylab        = p.Results.ylab;
tlim        = p.Results.tlim;
freq        = p.Results.freqs;
unit        = p.Results.unit;

if iscell(chans)
    if all(ismember(chans,{TF(1).chanlocs.labels}))
        chans = find(ismember({TF(1).chanlocs.labels},chans));
    else
        error('couldn''t find the specified channels');
    end
elseif ~all(ismember(chans,1:length(TF(1).chanlocs)))
    error('couldn''t find the specified channels');
end
%% extract data
x = TF(conds(1)).times;
y = TF(conds(1)).freqs;

for iCond = conds
    z(:,:,:,iCond) = TF(iCond).pow(:,:,chans);
end
%% make z 2-dimensional (i.e., average power over channels and/or conditions)
z = mean(mean(z,4),3);

%% create contour figure
[~, h] = contourf(x, y, z, smoothness, 'linestyle', 'none');

%% adjust scales
%z/power
if strcmp(scale,'minmax')
    lim.z(1) = min(z(:));
    lim.z(2) = max(z(:));
elseif strcmp(scale,'absmax')
    lim.z(1) = max(abs([min(z(:)) max(z(:))]));
    lim.z(2) = -blim;
else
    lim.z    = scale;
end

% y/frequency
if strcmp(freq,'minmax')
    lim.y = [min(TF(1).freqs) max(TF(1).freqs)];
else
    lim.y = freq;
end

% x/time
if strcmp(tlim,'minmax')
    lim.x = [min(TF(1).times) max(TF(1).times)];
else
    lim.x = tlim;
end

set(gca, 'clim', lim.z, 'xlim', lim.x, 'ylim', lim.y);

%% add title & labels
if ~strcmp(titl,'off')
    title(titl, 'fontweight', 'bold', 'fontsize', 12, 'interpreter', 'none');
end
if ~strcmp(xlab,'off')
    xlabel(xlab, 'fontweight', 'bold', 'fontsize', 12, 'interpreter', 'none');
end
if ~strcmp(ylab,'off')
    ylabel(ylab, 'fontweight', 'bold', 'fontsize', 12, 'interpreter', 'none');
end

c = colorbar('TickLabelInterpreter', 'none','location','eastoutside');
set(c.Label,'String',unit, 'fontweight', 'bold', 'fontsize', 12, 'interpreter', 'none')
end