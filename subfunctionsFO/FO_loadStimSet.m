
function sStims = FO_loadStimSet(sStimParams)
	
	%% stimulus set selection
	cellAvailSets = {'20D_20B'}; %list of available stim sets, manually add new ones
	
	%get user input
	indSelected = listdlg('PromptString', {'Select a stimulus set'}, 'SelectionMode', 'single', 'ListString', cellAvailSets);
	strSelected = cell2mat(cellAvailSets(indSelected));
	
	%% create stimulus set based on UI
	if strSelected == '20D_20B' %#ok<*BDSCA>
		
		%20 x black disc (4 deg) @20 deg/s, middle of the screen, & 20 'blank'trials
		intTotalStims = 2; %excluding 'blanks'
		intTotalBlanks = 0;
		vecStimSize_deg = [4 4]; %deg
		dblVelocity_deg = 20; %deg/s
		dblStimX_deg = 0; %relative to middle of the screen
		dblStimulus = 0;
		
		%get random indices for blanks
		indBlanks = randperm(intTotalStims + intTotalBlanks); indBlanks = indBlanks(1:intTotalBlanks);
		
		%create stimulus struct
		sStims = struct;
		for indTrial = 1:(intTotalStims + intTotalBlanks)
			sStims(indTrial).vecStimSize_deg = vecStimSize_deg;
			sStims(indTrial).dblVelocity_deg = dblVelocity_deg;
			sStims(indTrial).dblStimX_deg = dblStimX_deg;
			if ~ismember(indTrial, indBlanks)
				sStims(indTrial).dblStimulus = dblStimulus;
			else
				sStims(indTrial).dblStimulus = sStimParams.dblBackground;
			end
			sStims(indTrial).intStimulus = round(mean(sStims(indTrial).dblStimulus) * 255);
		end
	%elseif strSelected == ''
		%add more stimulus sets here
	end
	
end	
	
	