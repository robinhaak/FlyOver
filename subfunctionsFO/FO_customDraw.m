
function [dblStimOnNI,dblStimOffNI]= FO_customDraw(hSGL,ptrWindow,intStimNr,sStimParams)
	
	%% get NI onset timestamp
	if ~isempty(hSGL)
		intStreamNI = -1;
		dblSampFreqNI = GetSampleRate(hSGL, intStreamNI);
		dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
	else
		dblStimOnNI = nan;
	end
	
	%% draw on screen
	%retrieve stimulus parameters
	sStim = sStimParams.sStims(intStimNr);
	
	%loop through frames
	dblStimY_pix = sStimParams.intScreenHeight_pix;
	dblStamp = Screen('Flip', ptrWindow);
	
	for intFrame = 1:sStim.intNumFrames
		vecBoundingRect = [sStim.dblStimX_pix-sStim.vecStimSize_pix(1)/2, dblStimY_pix, ...
			sStim.dblStimX_pix+sStim.vecStimSize_pix(1)/2, dblStimY_pix+sStim.vecStimSize_pix(2)];
		Screen('FillOval', ptrWindow, sStim.intStimulus, vecBoundingRect);
		dblStamp = Screen('Flip', ptrWindow, dblStamp+0.5/sStimParams.dblStimFrameRate);
		dblStimY_pix = dblStimY_pix-sStim.dblPixelsPerFrame;
	end
	
	Screen('Flip', ptrWindow, dblStamp+0.5/sStimParams.dblStimFrameRate);
	
	%% get NI offset timestamp
	if ~isempty(hSGL)
		dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
	else
		dblStimOffNI = nan;
	end
	
	%% save temp object
	%save object
	sObject = sStimParams;
	%add timestamps
	sObject.dblStimOnNI = dblStimOnNI;
	sObject.dblStimOffNI = dblStimOffNI;
	sObject.intStimType = 1;%  intStimType;
	save(fullfile(sStimParams.strTempObjectPath,['Object',num2str(intStimNr),'.mat']),'sObject');
end