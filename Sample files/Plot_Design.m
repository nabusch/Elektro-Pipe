%% Load data.
clear
EP.dir_experiment = 'C:\Users\nbusch\Documents\Corenats\';
EP.project_name = 'Grand_ERP_encoding';
EP.design_idx = 1;

filename = fullfile([EP.dir_experiment, EP.project_name '_D' num2str(EP.design_idx), ...
    filesep, EP.project_name '_D' num2str(EP.design_idx), '.mat']);

load(filename);
%% The data are now in a multidimensional struct variable, in which each 
%  dimension represents an experimental factor. So, if you would analyse
%  your data with a 2x3 ANOVA, the ALLEEG struct is 2x3 large. However, it
%  is not possible to average variables that are inside a struct. So, to
%  faciliate processing, we construct an array with all data from all
%  conditions, preserving the dimensions which represent conditions.
clear eeg
for icondition = 1:numel(ALLEEG)
    eeg(icondition,:,:,:) = ALLEEG(icondition).data;
end

eeg_size = size(eeg);
eeg = reshape(eeg, [size(ALLEEG) eeg_size(end-2) eeg_size(end-1) eeg_size(end)]);

dims.chans = length(size(eeg))-2;
dims.times = length(size(eeg))-1;
dims.subjs = length(size(eeg));

%%
t = ALLEEG(1).times;

chans{1,1} = [ 1:11]; % Left anterior
chans{1,2} = [12:19]; % Left central
chans{1,3} = [20:27]; % Left posterior
chans{2,1} = [34:36 39:46]; % Right anterior
chans{2,2} = [49:56]; % Right central
chans{2,3} = [57:64]; % Right posterior


figure('color', 'w');

for i_side = 1:size(chans,1)
    for i_antpost = 1:size(chans,2)
        
        erp = mmean(eeg(1:3,2,chans{i_side,i_antpost},:,:),[dims.chans dims.subjs]);
        
        sanesubplot(size(chans,2), size(chans,1), {i_antpost, i_side})
        hold all
        plot(t, erp)
        
        if i_side == 1 & i_antpost == 1
            legend(ALLEEG(1).DINFO.factor_values_label{1})
        end
        
        set(gca, 'xlim', [-200 max(t)], 'tickdir', 'out')
    end
end

%%
gfp = my_gfp(eeg, dims.chans, 1:64, 1);
gfp = mean(gfp,4);

figure('color', 'w');

subplot(2,1,1)
    plotgfp = squeeze(gfp(1:3,1,:));
    plot(t, plotgfp)
        set(gca, 'xlim', [-200 max(t)], 'tickdir', 'out')
subplot(2,1,2)
    plotgfp = squeeze(gfp(1:3,2,:));
    plot(t, plotgfp)
        set(gca, 'xlim', [-200 max(t)], 'tickdir', 'out')

