function D = get_design(designidx)
% D = GET_DESIGN(designidx) gets & defines designs for EEG analysis 
%
% Functions handling the design information will select the appropriate
% trials from the EEG datasets using the information stored in the
% EEG.event structure, such as correctness, stimulus type, etc.
%
% designidx (optional input): if given, the function will return only the
%   design of this index. Default is to return all designs defined in this
%   file.
% d.factor_names:   refers to the information stored in the EEG.event
%   structure. Thus, defining a factor with factor name "Correct" requires
%   that there be an event field EEG.event.Correct! 
% d.factor_values:  defines
%   which values/levels of factor_name you are interested in. Defining the
%   factor values as {1 0} requires that EEG.event.Correct actually takes
%   values of 0 and 1.
% d.factor_names_label (optional): sometimes the fieldnames in EEG.event are ugly
%   of even not descriptive. In order to facilitate later processing and
%   plotting of the results, you can choose a nicer string here.
% d.factor_values_label (optional): likewise, values in EEG.event are often
%   not informative. What does EEG.event.cue_type = 1 mean. You can define an
%   informative string here.

D(1).factor_names  = {'presentation_no', 'ReportCorrect'};
D(1).factor_values = { {1 2 3}, {0 1}};
D(1).factor_names_label = {'presentation', 'accuracy'};
D(1).factor_values_label = { {'first', 'second', 'third'}, {'error', 'correct'} };

% Make sure we return only the desired designs.
if nargin~=0
    D = D(designidx);
end

return

 
%%------------------------------------------------------------
% EXAMPLES
% These should not be actually execute by the function because
% they are located after the return statement.
% ------------------------------------------------------------
D(99).factor_names  = {'cue_dir', 'report_correct'};
D(99).factor_values = { {1 2 3}, {0 1} };
D(99).factor_names_label = {'cue direction', 'accuracy'};
D(99).factor_values_label = { {'valid', 'invalid', 'neutral'}, {'error', 'correct'} };

% You can use the syntax:
% d.factor_values = {{[1:320],[640:960]}};
% If the factor represents a continuous numerical variable such as trial
% number or reaction times, you may want to combine value RANGES, such as
% early vs. late trials or fast vs. slow responses.
D(99).factor_names  = {'SetSize', 'Trial'};
D(99).factor_values = { {1 2}, {[1:320],[640:960]} };

% You can use the syntax:
% d.factor_values = {{1 2 [3 4]}}
% The square brackets mean: look for trials with values of 1 and 2 in
% EEG.event and treat them as the same factor level. This would be useful
% for example when subjects use a 4-point rating scale, but rarely use
% levels 3 and 4, so that you want to combine these rating levels.
D(99).factor_names  = {'ismasked', 'hemifield', 'rating'};
D(99).factor_values = { {0 1}, {1 2}, {1 2 [3 4]} };
