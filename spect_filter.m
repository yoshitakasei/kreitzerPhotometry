%Written by Chris Donahue

function [spectTimes,photoSig,isoSig] = spect_filter(data)
% Spectral filtering of raw modulated photometry signal (zeroLag)
% adapted from spect_Script SFO: 8.8.17


rx = data.streams.Fi1r.data(1,:);%1:100000); % take first 100k points
Fs = data.streams.Fi1r.fs; % Sampling rate

freqRange = 100:5:600; % Frequencies to calculate spectrogram in Hz
winSize = 0.04; % Window size for spectrogram (sec)
spectSample = 0.005; % Step size for spectrogram (sec)
inclFreqWin = 3; % Number of frequency bins to average (on either side of peak freq)
filtCut = 300; % Cut off frequency for low pass filter of data

% Convert spectrogram window size and overlap from time to samples
spectWindow = 2.^nextpow2(Fs .* winSize);
spectOverlap = ceil(spectWindow - (spectWindow .* (spectSample ./ winSize)));
disp(['Calculating spectrum using window size ', num2str(spectWindow ./ Fs)])

% Create low pass filter fot final data
lpFilt = designfilt('lowpassiir','FilterOrder',8, 'PassbandFrequency',300,...
    'PassbandRipple',0.01, 'SampleRate',Fs);

% Calculate spectrogram
[spectVals,spectFreqs,spectTimes]=spectrogram(rx,spectWindow,spectOverlap,freqRange,Fs);
spectAmpVals = double(abs(spectVals));


% Find the two carrier frequencies
avgFreqAmps = mean(spectAmpVals,2);
[pks,locs]=findpeaks(double(avgFreqAmps),'minpeakheight',max(avgFreqAmps./10));

if length(pks)>1 % Kluge for when isosbestic LED not on
    sig2 = mean(abs(spectVals((locs(2)-inclFreqWin):(locs(2)+inclFreqWin),:)),1);
    filtSig2 = filtfilt(lpFilt,double(sig2)); % isosBestic
    isoSig = filtSig2';
else
    isoSig = [];
end
% Calculate signal at each frequency band
sig1 = mean(abs(spectVals((locs(1)-inclFreqWin):(locs(1)+inclFreqWin),:)),1);

% Low pass filter the signals
filtSig1 = filtfilt(lpFilt,double(sig1)); % gCaMP
photoSig = filtSig1';


% remove outliers:
rmIdx = find(zscore(photoSig)<=-4);
spectTimes(rmIdx) = [];
photoSig(rmIdx) = [];
isoSig(rmIdx) = [];