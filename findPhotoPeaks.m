function [peakInfo, riseInfo, troughInfo] = findPhotoPeaks(t,corrData,thresh)
% find Peaks in photoSignal: actually finds peak magnitudes by looking at
% trough to peak distances. Does fine but could be improved for pulling out rise times. 

% peaks Amplitude is actual amplitude in dFoF
% rise amplitude is difference from trough to Peak (might change this to
        % rise location to peak??
% trough amplitude is actual amplitude at the trough
                             
mnPkDst = 3; % start of peak cannot be more than 2 sec before peak

[pks locs] = findpeaks(double(corrData));


% find minimums:
sigInv = 1.01*max(corrData) - corrData;
[pksMn locsMn] = findpeaks(double(sigInv));



% THIS WILL BE THE ALGORITHM TO CHOOSE THROUGH PEAKS:
count = 1;
rmPkCnt = 0;
for i = 1:length(pks)
  
    mnIdx  = find(locsMn < locs(i), 1, 'last'); % find index of last trough
    % if no trough exists before peak, skip to next peak
    if ~any(mnIdx)
        continue;
    end
    if t(locsMn(mnIdx)) + mnPkDst < t(locs(i))
        rmPkCnt = rmPkCnt+1;
%         disp(['Peak ', num2str(i), ...
%             ' excluded because trough-peak dist too great: ', ...
%             num2str(filtTime(locs(i)) - filtTime(locsMn(mnIdx)))]);
        [mnVal,mnIdx] = find(t > t(locs(i)) - mnPkDst,1,'first');
    end
    
    % Find the max slope between the trough and peak
    [pkSlope,pkSlopeInd] = max(diff(corrData(locsMn(mnIdx):locs(i))));
    rIdx = locsMn(mnIdx) + pkSlopeInd; % peak slope index

    
    [pkRise,pkRiseInd] = max(diff(diff(corrData(locsMn(mnIdx):rIdx)))); % 2nd derivative (trough to rise)

    r2Idx = locsMn(mnIdx) + pkRiseInd;
    
    % Store only peaks that exceed a threshold
    if (pks(i)-corrData(locsMn(mnIdx))) > thresh && ~isempty(r2Idx) % added to prevent crashing
        
        peakInfo.t(count) = t(locs(i));
        peakInfo.sampleNum(count) = find(t >= t(locs(i)), 1, 'first');
        peakInfo.amp(count) = corrData(peakInfo.sampleNum(count)); % Actual amplitude at peak

        
        
        troughInfo.t(count) = t(locsMn(mnIdx));
        troughInfo.sampleNum(count) = find(t >= t(locsMn(mnIdx)), 1, 'first');
        troughInfo.amp(count) = corrData(troughInfo.sampleNum(count)); % actual amplitude at trough
        
        riseInfo.t(count) = t(r2Idx);
        riseInfo.sampleNum(count) = find(t >= t(r2Idx), 1, 'first');
        riseInfo.amp(count) = peakInfo.amp(count) - troughInfo.amp(count); % RELATIVE AMPITUDES (Peak-Trough)

        
        
        count = count+1;
    end
end    




% 
% Remove outliers: (get rid of anything >4 std below minimum)
% zthresh = -4;
% [z] = zscore(corrData(troughInfo.sampleNum))';
% rmInds = find(z<zthresh | riseInfo.amp<0);
% peakInfo.t(rmInds) = [];
% peakInfo.sampleNum(rmInds) = [];
% peakInfo.amp(rmInds) = [];
% riseInfo.t(rmInds) = [];
% riseInfo.sampleNum(rmInds) = [];
% riseInfo.amp(rmInds) = [];
% troughInfo.t(rmInds) = [];
% troughInfo.sampleNum(rmInds) = [];
% troughInfo.amp(rmInds) = [];


% Throw warning if too many peaks were removed:
disp([num2str(100*rmPkCnt/length(peakInfo.t),'%1.1f'),'% PEAKS REMOVED',...
    ': trough-peak greater than ',num2str(mnPkDst),'s'])
if (100*rmPkCnt/length(peakInfo.t))>5
    warning('TOO MANY PEAKS REMOVED: CHECK FILE!!!')
end
        
    
% % Uncomment to see peaks and amplitudes:
figure
subplot(2,1,1)
hold on
plot(t,corrData,'k')
hold on
% axis([peakInfo.t(1) peakInfo.t(end) -.02 0.3])
plot(peakInfo.t,corrData(peakInfo.sampleNum),'b.')
plot(riseInfo.t,corrData(riseInfo.sampleNum),'g.')
plot(troughInfo.t,corrData(troughInfo.sampleNum),'r.')
ylim([-5 10])
subplot(2,1,2)
hold on
hist(riseInfo.amp,200)
xlabel('Amplitudes')
ylabel('Frequency')
title('Trough to peak amplitude distribution')




