function pipHistory = runPipsInteractive(pip,logSessionData)
%function runPipsInteractive(pipType[='a'],pipHz[=1])
%% runPipsInteractive.m
% 
% run an "interactive" session of pips for hunting while doing ephys
%
% SLH 2014

%% Deal with input
if ~exist('pip','var')
    pip.Type = 'a';
    pip.Hz   = 1;
    pip.Duty = .1;
end
if ~exist('logSessionData','var')
    logSessionData = 0;
end

%% Set up pip object
pipParams.modulationDepth  = 1;
pipParams.modulationFreqHz = 1;
pipParams.carrierFreqHz    = 150;
pipParams.dutyCycle        = .2;
pipParams.envelope         = 'sinusoid';

stim = PipStimulus(pipParams);

%% Configure daq

% analog output

% digital output 


%% Send the pulses

% record history of pips in session
pipHistory = [];

% digital pulse every time I send a new pip type
