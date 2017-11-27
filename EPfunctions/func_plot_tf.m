function [h, c] = func_plot_tf(TF,varargin)
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
%       TF: Struct with (minimum) fields 'pow'(power: powPerFreq*time*chan*cond), 
%           'chanloc','freqs','times','condition'.
%
% Keywords for optional input: 
%       'scale': can be 'absmax', 'minmax'(default) or a vector [min max]
%       'smoothness': the ncontours of contourf(). Default=49
%       'title' : title for the plot. default is 'off'.
%       'xlab'  : x-label for the plot. default is 'off'.
%       'ylab'  : y-label for the plot. default is 'off'.
%       'chans' : vector containing numerical indeces or cell vector
%                 containing the desired channel-names. The resulting plot
%                 will show the averaged data of all indicated channels.
%                 Default is all channels.
%       'tlim'  : numerical vector indicating the time-interval to plot.
%                 Default is [min max]
%       'freqs' : Numerical vector of frequency-limit to plot. Default is [min max];
%       'unit'  : string. The function doesn't know what unit your data are
%                 in. Specify a string here to print it next to the scale. 
%       'subjs' : indeces indicating which subject's data to plot. 
%                 If more than 1, average is plotted. Defaults to all.
%       'conds' : cell. indeces of levels for each dimension. defaults to
%                 average of all dimensions. e.g., for a Design with 3
%                 factors this would be {dim1,dim2,dim3}
% 'powfieldname': String. Name of the data field. Default is 'pow'.
%
% Wanja Moessing (moessing@wwu.de) Dec, 2016

%% input checks
p = inputParser;
p.FunctionName = 'funct_plot_tf';
p.addRequired('TF',@isstruct);
p.addOptional('conds','all',@(x) iscell(x) && isnumeric([x{:}]));
p.addOptional('subjs','all',@(x) all(mod(x,1)==0));
p.addOptional('chans', NaN, @(x) isnumeric(x));
p.addOptional('scale','minmax',@(x) (isnumeric(x) && length(x)==2) || any(strcmp(x,{'absmax','minmax'})));
p.addOptional('smoothness',48,@isnumeric);
p.addOptional('title','off',@isstr);
p.addOptional('xlab','off',@isstr);
p.addOptional('ylab','off',@isstr);
p.addOptional('tlim','minmax',@(x) isnumeric(x) && length(x)==2);
p.addOptional('freqs','minmax',@(x) isnumeric(x) && length(x)==2);
p.addOptional('unit','',@isstr);
p.addOptional('powfieldname','pow',@isstr);
parse(p,TF,varargin{:})

%% Transform input
cond        = p.Results.conds;
subjs       = p.Results.subjs;
chans       = p.Results.chans;
scale       = p.Results.scale;
smoothness  = p.Results.smoothness;
titl        = p.Results.title;
xlab        = p.Results.xlab;
ylab        = p.Results.ylab;
tlim        = p.Results.tlim;
freq        = p.Results.freqs;
unit        = p.Results.unit;
pfname      = p.Results.powfieldname;

% no varargin for chans?
if isnan(chans)
    chans = 1:size(TF(1).(pfname),3);
end

%how many dimensions does the current TF have?
dims   = ndims(TF);
maxdim = size(TF);

%create struct that can be used for indexing independent of number of
%dimensions (i.e. factors)
if strcmp(cond,'all')
    for d=1:dims
        conds{d} = maxdim(d);
    end
elseif iscell(cond) && (length(cond)==dims || (length(cond)==1 && size(TF,1)==1)) %everything after || is the 1-factor case which will have ndims 1xLevel = 3
    conds = cond;
else
    error('Please provide condition indeces as cell (i.e., {dim1,dim2,..,dimN}).');
end

%extract the desired data
TF = TF(conds{:});

%check channels
if iscell(chans)
    if all(ismember(chans,{TF.chanlocs.labels}))
        chans = find(ismember({TF.chanlocs.labels},chans));
    else
        error('couldn''t find the specified channels');
    end
elseif ~all(ismember(chans,1:length(TF.chanlocs)))
    error('couldn''t find the specified channels');
end

% define over which subjects to average
if strcmp(subjs,'all')
    nsubs = size(TF.(pfname));
    subjs = 1:nsubs(end);
end

%% extract data
x = TF.times;
y = TF.freqs;
z(:,:,:,:) = TF.(pfname)(:,:,chans,subjs);

%% make z 2-dimensional (i.e., average power over channels and/or subjects)
z = mean(mean(z,4),3);
if all(all(isnan(z)))
    error('Power data are NaN. One reason could be that your condition does not have any trials.');
end
%% create contour figure
[~, h] = contourf(squeeze(x), squeeze(y), z, smoothness, 'linestyle', 'none');

%% adjust scales
%z/power
if strcmp(scale,'minmax')
    lim.z(1) = min(z(:));
    lim.z(2) = max(z(:));
elseif strcmp(scale,'absmax')
    lim.z(2) = max(abs([min(z(:)) max(z(:))]));
    lim.z(1) = -lim.z(2);
else
    lim.z    = scale;
end

% y/frequency
if strcmp(freq,'minmax')
    lim.y = [min(y) max(y)];
else
    lim.y = freq;
end

% x/time
if strcmp(tlim,'minmax')
    lim.x = [min(x) max(x)];
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