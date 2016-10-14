function who_idx = get_subjects(EP)
% helper function to decode which subjects are to be processed.

% EP.who = 1; % Single numerical index.
% EP.who = [1 3]; % Vector of numerical indices.
% EP.who = 'AI01'; % Single string.
% EP.who = {'Pseudonym', {'AI01', 'AI02'}}; % One pair of column name and requested values.
% EP.who = {'Pseudonym', {'AI01', 'AI03'}; 'Include', 1; 'has_import', 0}; % Multiple columns and values. Only subjects fullfilling all criteria are included.

if isempty(EP.who)
    who_idx = 1:height(EP.S);
    
elseif isnumeric(EP.who) % If who is just a numeric index.
    who_idx = EP.who;
    
    
elseif isstr(EP.who) % If who is a single string.
    names = EP.S.Name;
    who_idx = find(strcmp(EP.who, names));
    
    
elseif iscell(EP.who) % If who is a set of field names and values
    
    for ivar = 1:size(EP.who,1)
        
        req_varname = EP.who{ivar,1}; %requested field name, e.g. Pseudonym or Include
        req_values =  EP.who{ivar,2}; % requested value, e.g. 'AI01' or 1.
        
        subject_values = EP.S.(req_varname);
        
        if isnumeric(subject_values)
            subject_values(isnan(subject_values)) = 0;
        end
        
        var_idx(ivar,:) = ismember(subject_values, req_values{:});
    end
    
    who_idx = find(all(var_idx, 1)); % select subjects who fullfill all criteria.
    
end