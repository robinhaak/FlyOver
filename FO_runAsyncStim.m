
function [sTrialData,sStimParams]= FO_runAsyncStim()
	
	%% switches
	boolDebug = false;
	
	%% start memory maps
	try
		%% data switch
		mmapSignal = JoinMemMap('dataswitch');
		
		%% load stim params
		mmapParams = JoinMemMap('sStimParams','struct');
		sStimParams = mmapParams.Data;
		if ~isstruct(sStimParams) && isscalar(sStimParams) && sStimParams == 0
			error([mfilename ':DataMapNotInitialized'],'Data transfer failed. Did you start the other matlab first?');
		end
		strHostAddress = sStimParams.strHostAddress;
	catch
		error([mfilename ':DataMapNotInitialized'],'Memory mapping and/or data transfer failed. Did you start the other matlab first?');
	end
	
	%% connect to spikeglx
	if boolDebug == 1
		hSGL = [];
	else
		hSGL = SpikeGL(strHostAddress);
	end
	
	%% start PTB
	try
		fprintf('Starting PsychToolBox extension...\n');
		%% open window
		AssertOpenGL;
		KbName('UnifyKeyNames');
		intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
		if boolDebug == 1, vecInitRect = [0 0 640 640];else; vecInitRect = [];end
		try
			Screen('Preference', 'SkipSyncTests', 0);
			[ptrWindow,vecRect] = Screen('OpenWindow', sStimParams.intUseScreen,sStimParams.intBackground,vecInitRect);
		catch ME
			warning([mfilename ':ErrorPTB'],'Psychtoolbox error, attempting with sync test skip [msg: %s]',ME.message);
			Screen('Preference', 'SkipSyncTests', 1);
			[ptrWindow,vecRect] = Screen('OpenWindow', sStimParams.intUseScreen,sStimParams.intBackground,vecInitRect);
		end
		
		%correct gamma
		if boolDebug == false
		end
		
% 		% background grey
% 		Screen('FillRect',ptrWindow, sStimParams.intBackground);
% 		Screen('Flip',ptrWindow);
		
		%window variables
		sStimParams.intScreenWidth_pix = vecRect(3)-vecRect(1);
		sStimParams.intScreenHeight_pix = vecRect(4)-vecRect(2);
		sStimParams.dblPixelsPerDeg = sStimParams.intScreenWidth_pix/sStimParams.dblScreenWidth_deg;
		
		%% MAXIMIZE PRIORITY
		intOldPriority = 0; %#ok<*NASGU>
		if boolDebug == 0
			intPriorityLevel=MaxPriority(ptrWindow);
			intOldPriority = Priority(intPriorityLevel);
		end
		
		%% get monitor refresh rate
		sStimParams.dblStimFrameRate = Screen('FrameRate', ptrWindow);
		intStimFrameRate = round(sStimParams.dblStimFrameRate);
		dblStimFrameDur = mean(1/sStimParams.dblStimFrameRate);
		dblInterFlipInterval = Screen('GetFlipInterval', ptrWindow);
		if dblStimFrameDur/dblInterFlipInterval > 1.05 || dblStimFrameDur/dblInterFlipInterval < 0.95
			warning([mfilename ':InconsistentFlipDur'],sprintf('Something iffy with flip speed and monitor refresh rate detected; frame duration is %fs, while flip interval is %fs!',dblStimFrameDur,dblInterFlipInterval)); %#ok<SPWRN>
		end

		%% add parameters to stim struct
		sStims = sStimParams.sStims; %lazy
		for indTrial = 1:length(sStims)
			sStims(indTrial).dblStimX_pix = sStimParams.intScreenWidth_pix/2+sStims(indTrial).dblStimX_deg*sStimParams.dblPixelsPerDeg;
			sStims(indTrial).vecStimSize_pix = sStims(indTrial).vecStimSize_deg*sStimParams.dblPixelsPerDeg;
			dblPixelsPerSec = sStims(indTrial).dblVelocity_deg*sStimParams.dblPixelsPerDeg;
			sStims(indTrial).dblPixelsPerFrame = dblPixelsPerSec/sStimParams.dblStimFrameRate;
			sStims(indTrial).intNumFrames = round((sStimParams.intScreenHeight_pix+sStims(indTrial).vecStimSize_pix(2))/sStims(indTrial).dblPixelsPerFrame);
		end
		sStimParams.sStims = sStims;
		
		%% pre-allocate
		sTrialData=struct;
		sTrialData.TrialNumber = [];
		sTrialData.ActStimType = [];
		sTrialData.ActOnNI = [];
		sTrialData.ActOffNI = [];
		
		%% run until we get the signal to stop
		intStimNumber = mmapSignal.Data(1);
		%send signal we're ready to start
		fprintf('Preparation complete. Sending go-ahead signal!\n');
		mmapSignal.Data(2) = -1;
		intTrialCounter = 0;
		while intStimNumber ~= -1
			%check if we need to show a new stimulus
			intStimNumber = mmapSignal.Data(1);
			intStimType = mmapSignal.Data(2);
			if intStimNumber > 0
				%% set counter
				intTrialCounter = intTrialCounter + 1;
				
				%% call PresentFlyOver
				[dblStimOnNI,dblStimOffNI] = FO_customDraw(hSGL,ptrWindow,intStimNumber,sStimParams);
				
				%% save data
				sTrialData.TrialNumber(intTrialCounter) = intStimNumber;
				sTrialData.ActStimType(intTrialCounter) = 1; %intStimType
				sTrialData.ActOnNI(intTrialCounter) = dblStimOnNI;
				sTrialData.ActOffNI(intTrialCounter) = dblStimOffNI;
				
				%% reset signal
				mmapSignal.Data=[0 0];
			end
			%pause to avoid cpu overload
			pause(0.01);
		end
		
		%% export all data
		mmapData = InitMemMap('sTrialData',sTrialData);
		clear mmapData;
		
		%signal we're done
		mmapSignal.Data(1) = -2;
		mmapSignal.Data(2) = -2;
		
		%% close PTB
		Screen('Close',ptrWindow);
		Screen('CloseAll');
		ShowCursor;
		Priority(0);
		Screen('Preference', 'Verbosity',intOldVerbosity);
		
		%% wait until data has been received
		while mmapSignal.Data(1) ~= -3
			pause(0.1);
		end
		
	catch ME
		%% catch me and throw me
		Screen('Close');
		Screen('CloseAll');
		ShowCursor;
		Priority(0);
		Screen('Preference', 'Verbosity',intOldVerbosity);
		%% show error
		rethrow(ME);
	end
end