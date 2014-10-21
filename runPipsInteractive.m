function meta = runPipsInteractive(pipType,logSessionData,experimentName)
%function meta = runPipsInteractive(pipType[='a'],logSessionData[=0],experimentName[=''])
%% runPipsInteractive.m
% 
% run an "interactive" session of pips for hunting while doing ephys
%
% NOTE: pips should be longer than 100ms to ensure data can be gaplessly queued (see NotifyWhenScansQueuedBelow below)
% TODO: change the acquisition and generation stages to use something closer to rig-specific objects
%
% SLH 2014
%#ok<*NBRAK>

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
end
if ~exist('experimentName','var')
    experimentName = 'default-interactive';
end
baseDaqDir = 'C:\temp_daq\';

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
meta.daqSaveDir = baseDaqDir;
if logSessionData
    if ~exist(baseDaqDir,'dir')
        mkdir(baseDaqDir)
    end
    if ~exist(fullfile(baseDaqDir,experimentName),'dir')
        mkdir(fullfile(baseDaqDir,experimentName))
    end
    daqSaveDir = fullfile(baseDaqDir,experimentName);
    daqSaveFile = ['daq_raw_' experimentName '_' meta.fullDateTime];

    metaSaveFile = ['meta_' experimentName '_' meta.fullDateTime];
    
    meta.metaSaveFile = metaSaveFile;
    meta.daqSaveDir = daqSaveDir;
    meta.daqSaveFile = daqSaveFile;
else
    meta.daqSaveDir = '';
    meta.daqSaveFile = '';
    meta.metaSaveFile = '';
end

%--------------------------------------------------------------------------
%% Configure daq
%--------------------------------------------------------------------------
fprintf('****\n**** Initializing DAQ\n****\n')
close all force; daqreset;

niOut = daq.createSession('ni');
% devID found with daq.GetDevices or NI's MAX software
devID = 'Dev1';
niOut.Rate = 20E3;
niOut.IsContinuous = true;

% Analog Channels / names for documentation
aO = niOut.addAnalogOutputChannel(devID,[1],'Voltage'); 
aO(1).Name = 'pre-amplified auditory stim 1';

% Set when the daq should request more data with DataRequired listener
useManualNotify = 1;
if useManualNotify
    % 100ms seems to be the minimum time to queue up a new stimulus
    niOut.NotifyWhenScansQueuedBelow = niOut.Rate*.1;
end
% Add a listener for DataRequired that queues more data to the daq
niOut.addlistener('DataRequired',@(src,event)passData(src,event,stim));

% Digital Channels / names for documentation
dO = niOut.addDigitalChannel(devID,{'Port0/Line4'},'OutputOnly');
dO(1).Name = 'pip stim alignment';

if logSessionData
    niIn = daq.createSession('ni');

    % Fast + continuous sampling of axopatch output
    niIn.Rate = 20E3;
    niIn.IsContinuous = true;

    % Use a logfile for acquisition
    logFileID = fopen(fullfile(daqSaveDir,[daqSaveFile '.dat']),'w');
    niIn.addlistener('DataAvailable',@(src,evt)logDaqData(src,evt,logFileID));

    aI = niIn.addAnalogInputChannel(devID,[0 1 2 3 4 5],'Voltage');
    aI(1).Name = 'pre-amplified auditory stim 1';
    aI(2).Name = 'axopatch 200b x100mV voltage output';
    aI(3).Name = 'axopatch 200b command input';
    aI(4).Name = 'axopatch 200b current output';
    aI(5).Name = 'axopatch 200b mode';
    aI(6).Name = 'axopatch 200b gain';

    dI = niIn.addDigitalChannel(devID,{'Port0/Line7'},'InputOnly');
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
niOut.queueOutputData([stim.stimulus stim.alignment]);
 
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
            selectPip(lower(userInput),stim);
            stim.generateStim();
            meta.pipHistory = [meta.pipHistory stim];
        end
    end
end 

% Close daq objects
niOut.stop;

% Save logged data
if logSessionData
    niIn.stop;
    [~] = fclose(logFileID);

    fprintf('****\n**** Loading logged data\n****\n')
    nDaqChans = numel(aI) + numel(dI);
    % Load daq data from raw, uncompressed file
    [count,data] = loadDaqLog(fullfile(daqSaveDir,[daqSaveFile '.dat']),nDaqChans);

    % Write data to transparent filestructure
    writeDaqH5fs(fullfile(daqSaveDir,[daqSaveFile '.h5']),count,data,niIn.Rate,'single',...
        {niIn.Channels(:).ID},{niIn.Channels(:).Name});
    fprintf('****\n**** Saved data to .h5\n****\n')
    
    % Remove redundant log file
    delete(fullfile(daqSaveDir,[daqSaveFile '.dat']));    

    % Save metadata as simple flat json file (requires jsonlab)
    if ~exist('savejson','file')
        warning('savejson not found, using mat file')
        save(fullfile(daqSaveDir,[metaSaveFile '.mat']),'meta','-v7.3');
    else
        [~] = savejson('',meta,fullfile(daqSaveDir,[metaSaveFile '.mat']));
        fprintf('****\n**** Saved metadata to .json\n****\n')
    end
end

%--------------------------------------------------------------------------
%% Helper functions
%--------------------------------------------------------------------------
function obj = selectPip(pt,obj)
    switch pt
        case {'a'}
            % normal hunting pip
            obj.stimulusDur      = 1;
            obj.modulationDepth  = 1;
            obj.modulationFreqHz = 2;
            obj.carrierFreqHz    = 150;
            obj.dutyCycle        = .1;
            obj.envelope         = 'sinusoid';
        case {'b'}
            % faster hunting pip
            obj.stimulusDur      = 1;
            obj.modulationDepth  = 1;
            obj.modulationFreqHz = 5;
            obj.carrierFreqHz    = 150;
            obj.dutyCycle        = .1;
            obj.envelope         = 'sinusoid';
        case {'z'}
            % testing, temp
            obj.stimulusDur      = 1;
            obj.modulationDepth  = 1;
            obj.modulationFreqHz = 5;
            obj.carrierFreqHz    = 300;
            obj.dutyCycle        = .2;
            obj.envelope         = 'triangle';
         otherwise
            warning(['pipType ' pt ' not accounted for using default'])
            obj = selectPip('a');
    end
end

function passData(src,~,obj)
    src.queueOutputData([obj.stimulus obj.alignment]);
end

end
