function [ft_lay, elec] = elektro_easycap_txt2cart(fname, data)

if nargin == 0
    fname = [];
end

if isempty(fname) 
    disp('no input. reading ''easycap_m43v3_biosemi_buschlab_scalponly.txt''')
    fname = 'easycap_m43v3_biosemi_buschlab_scalponly.txt';
end

elec = ft_read_sens(fname, 'fileformat', 'easycap_txt', 'senstype', 'eeg');
cfg =[];
cfg.elec = elec;

if nargin < 2
    ft_lay = ft_prepare_layout(cfg);
else
    [ft_lay, data2] = ft_prepare_layout(cfg, data);
end
end