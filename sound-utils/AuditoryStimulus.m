classdef AuditoryStimulus < handle
% Basic superclass for auditory stimuli that holds samplerate and a plotting function
%
% SLH 2014
    properties (Constant,Hidden)
        % Default setting for duration and rate
        defaultStimDurMs = 1
        defaultSampleRate = 1E5

        % Default setting for amplifier input maximum
        defaultMaxVoltage = 1

        % Default setting for plotting
        defaultFontSize = 14
        defaultLineWidth = 2

        % Various subclass effects
        debug = 0
    end

    properties
        stimulusDur
        sampleRate
        maxVoltage
        stimulus
        alignment
    end

    methods
%%------Constructor-----------------------------------------------------------------
        function obj = AuditoryStimulus(params)
            if nargin < 1
                obj.sampleRate = obj.defaultSampleRate;
                obj.stimulusDur = obj.defaultStimDurMs;
                obj.maxVoltage = obj.defaultMaxVoltage;
            else
                obj.sampleRate = params.sampleRate;
                obj.stimulusDur = params.stimulusDur;
                obj.maxVoltage = params.maxVoltage;
            end
            obj.stimulus = [];
            obj.alignment = [];
        end

%%------Common Utilities---------------------------------------------------------
        function carrier = makeSine(obj,frequency)
            ts = (1/obj.sampleRate):(1/obj.sampleRate):(obj.stimulusDur);
            carrier = sin(2*pi*frequency*ts)';
        end
        
        function static = makeStatic(obj,frequency)
            static = ones(obj.sampleRate*obj.stimulusDur,1);
        end

        function obj = makeAlignmentOutput(obj)
            % Alignment is set to an arbitrary large fraction to ensure even slow daq
            % sampling will pick it up
            obj.alignment = zeros(length(obj.stimulus),1);
            obj.alignment(1:ceil(numel(obj.stimulus)/4)) = 1;
        end

%%------Plotting--------------------------------------------------------------------
        function [figHandle,plotHandle] = plot(obj,varargin)
            timeInMs = (1E3/obj.sampleRate):(1E3/obj.sampleRate):(1E3*length(obj.stimulus)/obj.sampleRate);
            figHandle = figure('Color',[1 1 1],'Name','AuditoryStimulus'); 
            plotHandle = plot(timeInMs,obj.stimulus);
            set(plotHandle,'LineWidth',obj.defaultLineWidth)

            box off; axis on; 
            set(gca,'TickDir','Out')
            title('Current AuditoryStimulus','FontSize',obj.defaultFontSize)
            ylabel('Amplitude (V)','FontSize',obj.defaultFontSize)
            xlabel('Time (ms)','FontSize',obj.defaultFontSize)
        end
    end

end
