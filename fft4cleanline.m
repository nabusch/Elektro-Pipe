figure
hold all

plot(EEG.cleanline.freqs, mean(EEG.cleanline.pow))
plot(EEG.cleanline.freqsc, mean(EEG.cleanline.powc))


[amps,  freqs] = my_fft(EEG.data, 2, EEG.srate, EEG.pnts);
pow = mean(amps.^2, 3);
% plot(freqs, mean(pow), 'linewidth', 2)


xlim([1 60])