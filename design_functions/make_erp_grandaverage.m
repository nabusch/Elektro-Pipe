function [erp, ntrials] = make_erp_grandaverage(EEG, DINFO, design_trials)


for icondition = 1:DINFO.n_conditions
    
    if isempty(design_trials(icondition).trials)
        ntrials(icondition) = 0;
        erp(:,:,icondition) = NaN;
        continue
    else
        ntrials(icondition) = length(design_trials(icondition).trials);
        erp(:,:,icondition) = mean(EEG.data(:,:,design_trials(icondition).trials),3);
    end
    
end

