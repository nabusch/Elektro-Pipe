function [] = cleanline_qualityplot(EEG)
% CLEANLINE_QUALITYPLOT plots a fft check for cleanline.
% 
% this script simply plots a comparison of pre- and post-cleanline fft, to
% assure proper functioning
% The plots are not shown, as the intention is to quietly save them in a
% single .ps at the end of preprocessing.
% needs:
% EEG.chanlocs.labels = channel labels
% EEG.cleanline.pow   = fft before cleanline
% EEG.cleanline.powc  = fft after cleanline
% EEG.cleanline.freqsc= to get the x-axis rights
%
% written by Wanja Moessing - moessing@wwu.de


set(0,'DefaultFigureVisible','off');
%find xticks
HzIdx = [];
for i=[5,10:10:70,75]
    [~,tmp] = min(abs(EEG.cleanline.freqs-i)); %only display frequencies up to 75Hz
    HzIdx = [HzIdx,tmp];
end

%loop over two different scales. This enables us to see the finegraned
%details in one plot and the overall picture in the other.
handleIdx = 0;
pres_chan = randi([1,length({EEG.chanlocs.labels})],1,10);%select 10 random some channels
for Y_intersp = [10,150]
    clear plotdat plotdatc sel_chans plotdat2 plotdatc2 sel_chans2;
    handleIdx = handleIdx+1;
    k         = 0;
    for i = pres_chan 
        k             = k+1;
        sel_chans(k)  = {EEG.chanlocs(i).labels};
        plotdat(:,k)  = (EEG.cleanline.pow(i,1:HzIdx(end))+k*Y_intersp);
        plotdatc(:,k) = (EEG.cleanline.powc(i,1:HzIdx(end))+k*Y_intersp);
        %data for 2nd plot
        i2             = min(i+1, length({EEG.chanlocs.labels})); %in case last chan was included above...
        sel_chans2(k)  = {EEG.chanlocs(i2).labels};
        plotdat2(:,k)  = (EEG.cleanline.pow(i2,1:HzIdx(end))+k*Y_intersp);
        plotdatc2(:,k) = (EEG.cleanline.powc(i2,1:HzIdx(end))+k*Y_intersp);
    end
    for iter = 1:2
        switch iter
            case 1
                figure;
                h1(:,handleIdx) = plot(plotdat,'r');
                hold on;
                h2(:,handleIdx) = plot(plotdatc,'b');
                hold off;
                legend([h1(1,handleIdx),h2(1,handleIdx)],'pre-cleanline','post-cleanline');
                chans = sel_chans;
            case 2
                figure;
                h3(:,handleIdx) = plot(plotdat2,'r');
                hold on;
                h4(:,handleIdx) = plot(plotdatc2,'b');
                hold off;
                legend([h3(1,handleIdx),h4(1,handleIdx)],'pre-cleanline','post-cleanline');
                chans = sel_chans2;
        end
        axis([1 HzIdx(end) 0 (k+1)*Y_intersp]);
        ax            = gca;
        ax.XTick      = HzIdx;
        ax.XTickLabel = EEG.cleanline.freqsc([ax.XTick]);
        ax.YTick      = Y_intersp:Y_intersp:(k*Y_intersp);
        ax.YTickLabel = chans;
        title({'Cleanline quality check for a random set of channels Y-interspace is: ',num2str(Y_intersp)});
    end
end
set(0,'DefaultFigureVisible','on');