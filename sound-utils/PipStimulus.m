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
            obj.makeAlignmentData();
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
            if ~empty(obj.carrierFreqHz) || obj.carrierFreqHz ~= 0
                obj.stimulus = obj.makeSine(obj.carrierFreqHz);
            else
                obj.stimulus = obj.makeStatic();
            end

            % Apply duty cycle (or pass back if not wanted)
            pulseBounds = obj.addDutyCycle();

            % Apply an amplitude modulation (or pass back if not wanted)
            obj.amplitudeModulate(pulseBounds)

            % Scale the stimulus to the maximum voltage in the amp
            obj.stimulus = obj.stimulus*obj.maxVoltage; 

            % Plot
            if obj.debug
                obj.plot
            end
        end

        function [obj,pulseBounds] = applyDutyCycle(obj)
            if obj.dutyCycle > 1 || obj.dutyCycle <= 0
                error('dutyCycle must be <= 1 && > 0')
            elseif obj.dutyCycle == 1
                pulseBounds = [1 length(obj.stimulus)];
            else
                % Number of samples per modulation period, num modulations
                sampsPerMod = ((1/obj.modulationFreqHz)*obj.sampleRate);
                if ~mod(sampsPerMod,1)
                    warning('modulation period not evenly divisible')
                    sampsPerMod = round(sampsPerMod);
                end
                nMods = (obj.stimulusDur*obj.sampleRate)/sampsPerMod;
                if ~mod(nMods,1)
                    warning('number modulations per stimulus not evenly divisible');
                    nMods = round(nMods);
                end
                pulseBounds = zeros(nMods,2);
                for iMod = 1:nMods
                    pulseBounds(iMod,:) = sampsPerMod + [(1-obj.dutyCycle)*sampsPerMod sampsPerMod];
                end
            end
            % Zero inter pulse intervals to establish a duty cycle over stimulus duration
            dutyCycleBinary = zeros(length(obj.stimulus),1);
            dutyCycleBinary(pulseBounds(:,1):pulseBounds(:,2)) = 1;
            obj.stimulus = obj.stimulus.*dutyCycleBinary;
        end

        function obj = ampModulate(obj,bounds)
            switch lower(obj.envelope)
                case {'none',''}
                    % pass back unchanged
                    return
                case {'sinusoid','sin'}
                    % make an envelope that fits the pulse duration
                    modEnvelope = obj.modulationDepth*sin(pi*bounds(:,2)-bounds(:,1)+1);
                case {'triangle','tri'}
                    modEnvelope = obj.modulationDepth*sawtooth(pi*bounds(:,2)-bounds(:,1)+1,.5);
                case {'sawtooth','saw'}
                    modEnvelope = obj.modulationDepth*sawtooth(pi*bounds(:,2)-bounds(:,1)+1,1);
                case {'sawtooth-rev','revsaw'}
                    modEnvelope = obj.modulationDepth*sawtooth(pi*bounds(:,2)-bounds(:,1)+1,-1);
                otherwise
                    error(['Envelope ' obj.Envelope ' not accounted for.']);
            end
            % apply the envelope to all of the modulation bounds 
            for iMod = 1:size(bounds,1)
                obj.stimulus(bounds(iMod,1):bounds(iMod,2)) = modEnvelope.*obj.stimulus(bounds(iMod,1):bounds(iMod,2));
            end
        end
    end
end
