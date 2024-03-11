%Written by Didi Mamaligas

function TDT = getPhotoSig_DREADD(fname)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SKIP IF ALREADY DONE:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
photoFileName = strrep(fname,'.mat','_TDT.mat');
TDT.fileName = photoFileName;
if ~exist(photoFileName)
    load(fname);
    disp(['GENERATING FILE: ',photoFileName])
else
    disp([photoFileName, ' ALREADY EXISTS'])
    load(photoFileName)
    return;
end

[spectTimes,photoSig,isoSig] = spect_filter(data);
camTimes = data.epocs.Cam1.onset;
for idx = 1:size(spectTimes,2)
   if spectTimes(idx) < camTimes(1) || spectTimes(idx) > camTimes(length(camTimes))
       spectTimes(idx) = NaN;
       isoSig(idx) = NaN;
       photoSig(idx) = NaN;
   end
end
TDT.photoSig = photoSig(~isnan(photoSig));
TDT.isoSig = isoSig(~isnan(isoSig));
TDT.spectTimes = spectTimes(~isnan(spectTimes));


save(photoFileName,'TDT');
end