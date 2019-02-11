function [amps, freqs] = my_fft(data, timedim, srate, npoints, return_complex);
%function [amps, freqs] = my_fft(data, timedim, srate, npoints, return_complex)
%
% Function for computing FFT on EEG data. The function return only the
% positive half of the FFT spectrum - this is the part that you are
% normally interested in.
%
% - data: EEG data with arbitrary dimensions. Can be channels x times x
% trials or just a single vector of time points or whatever.
% - timedim: which dimension corresponds to time.
% - srate: sampling rate.
% - npoints: length of the FFT
% - return_complex: 1=return complex values; 0=return only absolute.
%
% Example:
% [amps, freqs] = my_fft(EEG.data, 2, EEG.srate, 1024)
%
% Written by Niko Busch - Charite Berlin (niko.busch@gmail.com)
%
% 2011-05-23

if nargin==4
    return_complex = 0;
end

% Create the frequency axis.
if mod(npoints,2)==0
    k=-npoints/2:npoints/2-1; % N even
else
    k=-(npoints-1)/2:(npoints-1)/2; % N odd
end
T = npoints/srate;
freqs = k/T; 


% Remove mean from data.
% TESTED THIS AND IT DOES NOT MAKE A DIFFERENCE FOR THE SPECTRUM.
% repdims = ones(1, length(size(data)));
% repdims(timedim) = size(data, timedim);
% 
% avdata = mean(data,timedim);
% avdata = repmat(avdata, repdims);
% data = data-avdata;

% Compute and normalize FFT.
X = fft(data, npoints, timedim)/size(data,timedim); 

% Extract only the positive half of the spectrum
cutOff = freqs>0;
% ..no matter what the order of X is..
inds = repmat({':'}, 1, ndims(X));
inds{timedim} = cutOff;
X = X(inds{:});

freqs = freqs(cutOff);

% Compute the power.
if return_complex==1
    amps = X;
elseif return_complex==0    
    amps = abs(X);
end


