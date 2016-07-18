function eegplot_selectelec(varargin)



show_mocap_timer = timerfind('tag','mocapDisplayTimer'); if ~isempty(show_mocap_timer),  end; % nima
fig = varargin{1};

ax1 = findobj('tag','backeeg','parent',fig);
tmppos = get(ax1, 'currentpoint');
g = get(fig,'UserData'); % get data of backgroung image {g.trialstag g.winrej incallback}
if g.incallback ~= 1 % interception of nestest calls
    if g.trialstag ~= -1,
        lowlim = round(g.time*g.trialstag+1);
        highlim = round(g.winlength*g.trialstag);
    else,
        lowlim  = round(g.time*g.srate+1);
        highlim = round(g.winlength*g.srate);
    end;
    if (tmppos(1) >= 0) & (tmppos(1) <= highlim),
        g.setelectrode = 1;
        if isempty(g.winrej) Allwin=0;
        else Allwin = (g.winrej(:,1) < lowlim+tmppos(1)) & (g.winrej(:,2) > lowlim+tmppos(1));
        end;
        if any(Allwin) % remove the mark or select electrode if necessary
            lowlim = find(Allwin==1);
            if g.setelectrode  % select electrode
                ax2 = findobj('tag','eegaxis','parent',fig);
                tmppos = get(ax2, 'currentpoint');
                tmpelec = g.chans + 1 - round(tmppos(1,2) / g.spacing);
                tmpelec = min(max(tmpelec, 1), g.chans);
                g.winrej(lowlim,tmpelec+5) = ~g.winrej(lowlim,tmpelec+5); % set the electrode
            else  % remove mark
                g.winrej(lowlim,:) = [];
            end;
        else
            if g.trialstag ~= -1 % find nearest trials boundaries if epoched data
                alltrialtag = [0:g.trialstag:g.frames];
                I1 = find(alltrialtag < (tmppos(1)+lowlim) );
                if ~isempty(I1) & I1(end) ~= length(alltrialtag),
                    g.winrej = [g.winrej' [alltrialtag(I1(end)) alltrialtag(I1(end)+1) g.wincolor zeros(1,g.chans)]']';
                end;
            else,
                g.incallback = 1;  % set this variable for callback for continuous data
                if size(g.winrej,2) < 5
                    g.winrej(:,3:5) = repmat(g.wincolor, [size(g.winrej,1) 1]);
                end;
                if size(g.winrej,2) < 5+g.chans
                    g.winrej(:,6:(5+g.chans)) = zeros(size(g.winrej,1),g.chans);
                end;
                g.winrej = [g.winrej' [tmppos(1)+lowlim tmppos(1)+lowlim g.wincolor zeros(1,g.chans)]']';
            end;
        end;
        g.setelectrode = 0;
        set(fig,'UserData', g);
        eegplot('drawp', 0);  % redraw background
    end;
end;

