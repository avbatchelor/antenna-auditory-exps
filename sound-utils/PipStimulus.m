classdef PipStimulus < AuditoryStimulus
% Basic subclass for making (amplitude modulated) pips
% 
% SLH 2014
 
    properties (Constant,Hidden)
        defaultModulationDepth  = 1
        defaultModulationFreqHz = 8
        defaultCarrierFreqHz    = 150
        defaultDutyCycle        = .5
        defaultEnvelope         = 'sinusoid'
     end

    properties
        modulationDepth
        modulationFreqHz
        carrierFreqHz
        dutyCycle
        envelope
    end
    
    methods
%%------Constructor-----------------------------------------------------------------
        function obj = PipStimulus(params)
            if nargin < 1
                obj.setDefaultPipParameters();
            else
                obj.setPipParameters(params);
            end
            obj.generateStim();
            obj.makeAlignmentOutput();

            if obj.debug
                obj.plot
            end
        end

%%------Pip Making Utilities---------------------------------------------------------
        function obj = setDefaultPipParameters(obj)
            obj.modulationDepth  = obj.defaultModulationDepth;
            obj.modulationFreqHz = obj.defaultModulationFreqHz;
            obj.carrierFreqHz    = obj.defaultCarrierFreqHz;
            obj.dutyCycle        = obj.defaultDutyCycle;
            obj.envelope         = obj.defaultEnvelope;
        end
        
        function obj = setPipParameters(obj,params)
            try
                obj.modulationDepth  = params.modulationDepth;
                obj.modulationFreqHz = params.modulationFreqHz;
                obj.carrierFreqHz    = params.carrierFreqHz;
                obj.dutyCycle        = params.dutyCycle;
                obj.envelope         = params.envelope;
            catch err 
                disp(err.Msg)
                error('Incorrect fields');
            end
        end

        function obj = generateStim(obj)
            % Use carrier frequency if wanted
            if ~isempty(obj.carrierFreqHz) || obj.carrierFreqHz ~= 0
                obj.stimulus = obj.makeSine(obj.carrierFreqHz);
            else
                obj.stimulus = obj.makeStatic();
            end

            % Apply duty cycle (or pass back if not wanted)
            [~,pulseBounds] = obj.applyDutyCycle();

            % Apply an amplitude modulation (or pass back if not wanted)
            obj.ampModulate(pulseBounds)

            % Scale the stimulus to the maximum voltage in the amp
            obj.stimulus = obj.stimulus*obj.maxVoltage; 

        end

        function [obj,pulseBounds] = applyDutyCycle(obj)
            if obj.dutyCycle > 1 || obj.dutyCycle <= 0
                error('dutyCycle must be <= 1 && > 0')
            elseif obj.dutyCycle == 1
                pulseBounds = [1 length(obj.stimulus)];
            else
                % Number of samples per modulation period, num modulations
                sampsPerMod = ((1/obj.modulationFreqHz)*obj.sampleRate);
                if ~~mod(sampsPerMod,1)
                    warning('modulation period not evenly divisible')
                    sampsPerMod = round(sampsPerMod);
                end
                nMods = (obj.stimulusDur*obj.sampleRate)/sampsPerMod;
                if ~~mod(nMods,1)
                    warning('number modulations per stimulus not evenly divisible');
                    nMods = round(nMods);
                end
                pulseBounds = zeros(nMods,2);
                for iMod = 1:nMods
                    pulseBounds(iMod,:) = (iMod-1)*sampsPerMod + [(1-obj.dutyCycle)*sampsPerMod sampsPerMod];
                end
            end
            % Zero inter pulse intervals to establish a duty cycle over stimulus duration
            dutyCycleBinary = zeros(length(obj.stimulus),1);
            for iMod = 1:nMods
                dutyCycleBinary(pulseBounds(iMod,1):pulseBounds(iMod,2)) = 1;
            end
            obj.stimulus = obj.stimulus.*dutyCycleBinary;
        end

        function obj = ampModulate(obj,pulseBounds)
            switch lower(obj.envelope)
                case {'none',''}
                    % pass back unchanged
                    return
                case {'sinusoid','sin'}
                    % make an envelope that fits the pulse duration
                    dur = pulseBounds(1,2)-pulseBounds(1,1);
                    modEnvelope = obj.modulationDepth*sin(pi*[0:1/dur:1])';
                case {'triangle','tri'}
                    dur = pulseBounds(1,2)-pulseBounds(1,1);
                    modEnvelope = obj.modulationDepth*sawtooth(2*pi*[.25:1/(2*dur):.75],.5)';
                case {'rampup'}
                    dur = pulseBounds(1,2)-pulseBounds(1,1);
                    modEnvelope = obj.modulationDepth*sawtooth(2*pi*[.5:1/(2*dur):1])';
                case {'rampdown'}
                    dur = pulseBounds(1,2)-pulseBounds(1,1);
                    modEnvelope = obj.modulationDepth*sawtooth(2*pi*[0:1/(2*dur):.5],0)';
                otherwise
                    error(['Envelope ' obj.Envelope ' not accounted for.']);
            end
            % apply the envelope to all of the modulation bounds 
            for iMod = 1:size(pulseBounds,1)
                obj.stimulus(pulseBounds(iMod,1):pulseBounds(iMod,2)) = modEnvelope.*obj.stimulus(pulseBounds(iMod,1):pulseBounds(iMod,2));
            end
        end
    end
end
