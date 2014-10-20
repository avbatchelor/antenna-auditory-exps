function meta = runPipsInteractive(pipType,logSessionData,experimentName)
%function runPipsInteractive(pipType[='a'],pipHz[=1])
%% runPipsInteractive.m
% 
% run an "interactive" session of pips for hunting while doing ephys
%
% NOTE: pips should be longer than 100ms to ensure data can be gaplessly queued (see NotifyWhenScansQueuedBelow below)
%
% SLH 2014

%--------------------------------------------------------------------------
%% Deal with input
%--------------------------------------------------------------------------
if ~exist('pipType','var')
    pipType = 'a';
elseif ~ischar(pipType)
    error('pipType should be a character')
end
if ~exist('logSessionData','var')
    logSessionData = 0;
elseif logSessionData == 1
    daqSaveDir = 'C:\temp_daq\'
    if ~exist(daqSaveDir,'dir')
        mkdir(daqSaveDir)
    end
end
if ~exist('experimentName','var')
    experimentName = 'default';
end

%--------------------------------------------------------------------------
%% Set up pip object
%--------------------------------------------------------------------------
params = selectPip(pipType);
stim = PipStimulus(params);

%--------------------------------------------------------------------------
%% Metadata
%--------------------------------------------------------------------------
% record history of pips in session
meta.fullDateTime = datestr(now,30);
% record history of pips in session
meta.pipHistory = stim;
% save path info
meta.logged = logSessionData; 
meta.daqSaveDir = daqSaveDir;
if logSessionData
    meta.daqSaveDir = daqSaveDir;
    daqSaveFile = [experimentName '_' meta.fullDateTime];
    meta.daqSaveFile = daqSaveFile;
else
    meta.daqSaveDir = '';
    meta.daqSaveFile = '';
end

%--------------------------------------------------------------------------
%% Configure daq
%--------------------------------------------------------------------------
fprintf('****\n**** Initializing DAQ\n****\n')
try daqreset; catch; end

niOut = daq.createSession('ni');
% devID found with daq.GetDevices or NI's MAX software
devID = 'Dev1';
niOut.Rate = 20E3;
niOut.IsContinuous = true;

% Analog Channels / names for documentation
aO = niOut.addAnalogOutputChannel(devID,[1],'Voltage');
aO(1).Name = 'pre-amplified auditory stim 1';

% Set when the daq should request more data with DataRequired listener
useManualNotify = 0;
if useManualNotify
    % 100ms seems to be the minimum time to queue up a new stimulus
    aO.NotifyWhenScansQueuedBelow = niIn.Rate*.1;
else
    aO.IsNotifyWhenScansQueuedBelowAuto = true
end

% Add a listener for DataRequired that queues more data to the daq
niOut.addlistener('DataRequired',@(src,event)src.queueMoreData(stim.stimulus));

% Digital Channels / names for documentation
dO = niOut.addDigitalChannel(devID,{'Port0/Line4'},'OutputOnly');
dO(1).Name = 'pip stim alignment';

if logSessionData
    niIn = daq.createSession('ni');

    % Fast + continuous sampling of axopatch output
    niIn.Rate = 20E3;
    niIn.IsContinuous = true;

    % Use a logfile for acquisition
    logFileID = fopen(fullfile(daqSaveDir,daqSaveFile),'w');
    niIn.addlistener('DataAvailable',@(src,evt)logDaqData(src,evt,logFileID));

    aI = niIn.addAnalogInputChannel(devID,[0 1 2 3 4 5],'Voltage');
    aI(1).Name = 'pre-amplified auditory stim 1';
    aI(2).Name = 'axopatch 200b x100mV voltage output';
    aI(3).Name = 'axopatch 200b command input';
    aI(4).Name = 'axopatch 200b current output';
    aI(5).Name = 'axopatch 200b mode';
    aI(6).Name = 'axopatch 200b gain';

    dI = niIn.addDigitalChannel(devID,{'Port0/Line7'},'Bidirectional');
    dI(1).Name = 'pip stim alignment'; 
end

%--------------------------------------------------------------------------
%% Send pulses
%--------------------------------------------------------------------------
if logSessionData
    niIn.startBackground();
    fprintf('****\n**** Started Acquisition\n****\n')
    pause(.5)
end

% add initial data to the daq queue
niOut.queueOutputData(stim.stimulus);
 
niOut.startBackground()
fprintf('****\n**** Started Delivery\n****\n')

continueExp = 1;
while continueExp
    userInput = input(['Select Pip with {a/b/c/...} Stop with {Q/q}: '],'s');
    if ~isempty(userInput)
        if sum([lower(userInput) == 'q']) > 0
            continueExp = 0;
        elseif sum([lower(userInput) ~= 'q']) > 0
            % change stim
            stim = selectPip(lower(userInput));
        end 
    end
end 

% Close daq objects
if logSessionData
    niIn.stop;
    [~] = fclose(logFileID);
    fprintf('****\n**** Stopped Acquisition\n****\n')
    fprintf(['daqSaveDir:  ' meta.daqSaveDir '\n'])
    fprintf(['daqSaveFile: ' meta.daqSaveFile '\n'])
end
niOut.stop;

%--------------------------------------------------------------------------
%% Helper functions
%--------------------------------------------------------------------------
function pipParams = selectPip(pt)
    switch pt
        case {'a'}
            % normal hunting pip
            pipParams.modulationDepth  = 1;
            pipParams.modulationFreqHz = 1;
            pipParams.carrierFreqHz    = 150;
            pipParams.dutyCycle        = .15;
            pipParams.envelope         = 'sinusoid';
        case {'b'}
            % faster hunting pip
            pipParams.modulationDepth  = 1;
            pipParams.modulationFreqHz = 3;
            pipParams.carrierFreqHz    = 150;
            pipParams.dutyCycle        = .1;
            pipParams.envelope         = 'sinusoid';
        case {'z'}
            % testing, temp
            pipParams.modulationDepth  = 1;
            pipParams.modulationFreqHz = 5;
            pipParams.carrierFreqHz    = 300;
            pipParams.dutyCycle        = .4;
            pipParams.envelope         = 'triangle';
         otherwise
            warning(['pipType ' pt ' not accounted for using default'])
            pipParams = selectPip('a');
    end
end
