function [condinfo] = get_design_trials(EEG, EP, DINFO)

% Helper function that returns for a given EEG set file trial indices
% corresponding to each of the conditions of a design.

%%
% Loop across all conditions.
for icondition = 1:length(DINFO.design_matrix)
    
    if ~isfield(EP, 'verbose')
        EP.verbose = 1;
    end
    
    if EP.verbose
            fprintf('Finding trials for condition %d of %d. ', ...
                icondition, length(DINFO.design_matrix))
    end
    
    % Loop over all factors in the design.
    for ifactor = 1:DINFO.nfactors
        
        % Determine current factor name and factor level.
        factor_name  = char(EP.D.factor_names(ifactor));
        factor_level = DINFO.design_matrix(icondition, ifactor);
        
        
        % Determine which events correspond to the desired factor level. If
        % factor_level==0 (i.e. for main effects), choose all trials.
        if factor_level <= length(EP.D.factor_values{ifactor}) % wrong if this is a main effect.
            factor_value = EP.D.factor_values{ifactor}{factor_level};
        else
            factor_value = cell2mat(EP.D.factor_values{ifactor});
        end
        
        if ischar(factor_value(1))
            eegevents(ifactor,:) = ismember({EEG.event.(factor_name)}, factor_value);
            %             fprintf('\t%s %s', factor_name, factor_value)
        else
            %             eegevents(ifactor,:) = ismember([EEG.event.(factor_name)], factor_value);
            
            % I round the values in the EEG.event structure in case we
            % are daling with response times, etc. E.G. if the design
            % defines a factor level with values [1:200] meaning
            % response times <= 200 ms, we want to include RTs of
            % 105.004, although that value is not included in the 1:200
            % vector, which has only integer numbers.
            eegevents(ifactor,:) = ismember(round([EEG.event.(factor_name)]), factor_value);
            %             fprintf('\t%s %d', factor_name, factor_value)
        end
        
    end
    
    
    if DINFO.nfactors > 1
        wantedevents = find(all(eegevents));
    else
        wantedevents = find(eegevents);
    end
    
    condinfo(icondition).trials = unique([EEG.event(wantedevents).epoch]);
    
    if EP.verbose
        fprintf('%d trials found\n', length(condinfo(icondition).trials));
    end
    
end

