antenna-auditory-exps
==================================
First pass at code to send sound stimuli and record electrophysiologically from auditory neurons.

SLH 2014

#### outline
- Generate signals:
    - AuditoryStimulus.m superclass with shared methods, 
    - ChirpStimulus.m,PipStimulus.m, subclass with specific methods / defaults
- Send signals (nidaq-based):
    - use daq toolbox callbacks to queue signals
    - use digital output to align signals for analysis
- Run experiment:
    - runPipsInteractive.m opens interactive session of playing pips at some frequency determined by initial args to the function, and then by user input on command line.
        - takes character input as type of pip (a,b,c etc.,)
        - uses session-based interface to queue output data continuously  
    - runPipsSet.m will run a specific experiment with a number of different pips
