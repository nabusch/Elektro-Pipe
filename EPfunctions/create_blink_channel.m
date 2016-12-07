function EEG = create_blink_channel(EEG)
% CREATE_BLINK_CHANNEL uses blink events to create a blink channel
%
% More specifically, it assumes that blink events as detected online by
% eyelink systems are saved to the EEG.events structure. This information
% is then used to create a channel consisting of zeros and ones.
% Subsequently, this channel could, for instance, be used to select ICA
% components.
%
% written by Wanja Moessing - moessing@wwu.de

%---------------------------------------
% check if blink information exists
%---------------------------------------
if any(strcmp({EEG.event.type},'L_blink')) || any(strcmp({EEG.event.type},'R_blink'))
    disp('Blink information detected. Will create blink channel now.');
    flat = false;
else
    warning(['No blink events found in event structure.',...
        ' Either this subject didn''t blink or all epochs with blinks',...
        ' have been removed. Will create a flat channel.']);
    flat = true;
end
%---------------------------------------
% create blink channel
%---------------------------------------
%set all trials to zero and subsequently change blinktrials
tmpchan(1,:,:)              = zeros(EEG.pnts,EEG.trials);

if ~flat
    blinkIndex                  = logical(strcmp({EEG.event.type},'L_blink')+...
                                          strcmp({EEG.event.type},'R_blink'));
    tmpevent                    = EEG.event(blinkIndex);
    blinkTrials                 = unique([tmpevent.epoch]);
    for trl = blinkTrials
        curBlinks = logical(strcmp(EEG.epoch(trl).eventtype,'L_blink')+...
                            strcmp(EEG.epoch(trl).eventtype,'R_blink'));
        durBlinks = [tmpevent([tmpevent.epoch]==trl).duration];
        bl        = 0;
        for latency = EEG.epoch(trl).eventlatency(curBlinks)
            bl         = bl+1;
            [~,sBlink] = min(abs(EEG.times-latency{:}));
            eBlink     = min(sBlink+durBlinks(bl)-1,EEG.pnts); %-1 because 'duration' includes startevent sample | %EEG.event.endtime is nonsensical as it relates to original Eyelink timing
            tmpchan(1,sBlink:eBlink,trl) = 1;
        end
    end
end
%---------------------------------------
% assign to EEG structure
%---------------------------------------
EEG.chanlocs(end+1).labels  = 'Blinks';
EEG.chanlocs(end).type      = 'EYE';
EEG.nbchan                  = EEG.nbchan+1;
EEG.data(EEG.nbchan,:,:)    = tmpchan;

end