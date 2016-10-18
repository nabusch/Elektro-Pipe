function DINFO = get_design_matrix(D)
% function dinfo = get_design_matrix(D)
% Helper function that reads in a design file and creates a design matrix.


% It is possible (optional) to define labels in the design file that are more
% descriptive or less ugle than the factor names and values. But if these
% do not exists, substitute with condition names and values.
if isfield(D, 'factor_names_label')
    DINFO.factor_names_label = D.factor_names_label;
else
    DINFO.factor_names_label = D.factor_names;
end

if isfield(D, 'factor_values_label')
    DINFO.factor_values_label = D.factor_values_label;
else
    DINFO.factor_values_label = D.factor_values;
end




DINFO.factor_names  = D.factor_names;
DINFO.factor_values = D.factor_values;
DINFO.nfactors      = length(D.factor_names);

for ifactor = 1:DINFO.nfactors
    DINFO.nlevels(ifactor)  = length(D.factor_values{ifactor});
end

% Genereate design matrix including all main effects and interactions. The
% +1 term will result in an additional factor level. In subesequent
% procedure, the last factor level will be interpreted as a main effect,
% i.e. all levels of this factor together.
DINFO.design_matrix = fullfact(DINFO.nlevels+1);