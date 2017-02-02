function EEG = func_importBehavior(EEG, cfg)

% This function includes the behavioral data as recorded by Psychtoolbox in
% the EEG structure.
% Problem: some recording were started too late or terminated too early, so
% that the EEG structure lacks a few trials. This function matches the EEG
% triggers with the corresponding information ion the behavioral data to
% find out which information about which trials to merge.


% Load the logfile.
load([cfg.dir_behavior cfg.subject_name '_Logfile.mat'])

  
% This code assumes that the "logfile" is a Matlab struct called Info.T,
% where T is a struct of length ntrials, such that T(17) contains all the
% info for the 17th trial. We want to automatically include all fields in
% Info.T in our new EEG structure, but we can do this only for fields that
% have scalar values.

% Change this lines accordingly if your structure has a different name.
Trials = Info.T;
fields = fieldnames(Trials);
TrialsOut = [];

% Exclude trials where the eye tracker detected bad gaze.
if isfield(Trials, cfg.badgaze_fieldname)
    badtrials = [Trials.(cfg.badgaze_fieldname)] == 1;
    Trials(badtrials) = [];
end

ntrials = length(Trials);

for ifield = 1:length(fields)
    
   fieldlength = length(getfield(Trials,(fields{ifield}) ));
   
   Starttrial = 1;
   while fieldlength == 0 || isempty(fieldlength)
      Starttrial = Starttrial + 1;
      fieldlength = length(getfield(Trials(Starttrial:end),(fields{ifield}) ));
   end
   
   
   if fieldlength == 1
       
       % Test if this field has only scalar values. If yes, copy it to the
       % new "Logfile".
       for itrial = 1:ntrials
        TrialsOut(itrial).(fields{ifield}) = Trials(itrial).(fields{ifield});
       end       
       
   end
end

outfields = fieldnames(TrialsOut);


% Run through all events and import the behavioral data. The important
% assumption is that each epoch of the EEG data set corresponds to one
% trial in the logfile and the first trials in both data structures
% correspond to the same trial!
for ievent = 1:length(EEG.event)

    thisepoch = EEG.event(ievent).epoch;

    for ifield = 1:length(outfields)  
        
        % Check if the field in the log file is empty. If yes, fill with
        % arbitrary value.
        try
        new_event_value = TrialsOut(thisepoch).(outfields{ifield});
        catch ME
            warning('If you''re getting caught here, probably some trial(s) weren''t deleted in the EEG but in the logfile data.')
            keyboard;
        end
        if isempty(new_event_value)
            fillvalue = 666;
            fprintf('Empty event field found on trial %d in event field %s!\n', thisepoch, outfields{ifield});
            fprintf('Filling this field with arbitrary value of %d\n', fillvalue)
            new_event_value = fillvalue;
        end
        EEG.event(ievent).(outfields{ifield}) = new_event_value;
    end
end


% Issue a warning if the number of trials in the Logfile does not match the
% number in the EEG file.
if length(EEG.epoch) ~= ntrials
    w = sprintf('\nEEG file has %d trials, but Logfile has %d trials.\nYou should check this!', ...
        length(EEG.epoch), ntrials);
    warning(w)
end


%if specified in get_cfg, use latency checks to delete trials where a
%trigger differed more than 3ms from the median latency of that kind of
%trigger.
if cfg.deletebadlatency
    rejidx=zeros(1,length(EEG.epoch));
    rejidx(EEG.latencyBasedRejection)=1;
    if any(rejidx)
        warning(['Deleting %i trials because they included triggers that had',...
            ' weird latency glitches for some triggers.\nYou should check',...
            ' your code and/or setup!'],sum(rejidx));
        fid = fopen([cfg.dir_eeg,'TrialsWithBadLatency.txt'], 'wt');
        fprintf( fid, ['The following trials where deleted after\n',...
            'coregistration with behavioral data. That is because\n',...
            'one of the triggers %s differed by more than 3ms from the\n',...
            'median latency of this trigger across all trials.\n\n',...
            'Trials: %s\n'], num2str(cfg.checklatency), num2str(find(rejidx)));
        fclose(fid);
        EEG = pop_rejepoch(EEG,rejidx,0);
    end
end

% Update the EEG.epoch structure.
EEG = eeg_checkset(EEG, 'eventconsistency');

% Include the full trials structure in the EEG strucutre. You never know
% when it might be useful, especially for the more complex fields that
% could not be included in the EPOCH structure.
EEG.trialinfo = Trials;
