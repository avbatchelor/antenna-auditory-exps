function pipHistory = runPipsInteractive(pipType,logSessionData)
%function runPipsInteractive(pipType[='a'],pipHz[=1])
%% runPipsInteractive.m
% 
% run an "interactive" session of pips for hunting while doing ephys
%
% SLH 2014

%% Deal with input
if ~exist('pipType','var')
    pipType = 'a';
elseif ~ischar(pipType)
    error('pipType should be a character')
end
if ~exist('logSessionData','var')
    logSessionData = 0;
end

%% Set up pip object
params = selectPip(pipType);
stim = PipStimulus(params);

%% Configure daq

% analog output

% digital output 


%% Send the pulses

% record history of pips in session
pipHistory = [stim];

% digital pulse every time I send a new pip type

%% Helper functions
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
end
