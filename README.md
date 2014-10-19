antenna-auditory-exps
==================================
This repository has matlab code to stimulate antenna with sound during sharp electrode recordings, and record electrophysiological data with a nidaq. This README file is for documentation and will likely change a lot.

SLH 2014

#### outline
- Generate signals:
    - AuditoryStimulus.m superclass with shared methods, 
    - ChirpStimulus.m,PipStimulus.m, subclass with specific methods / defaults
- Send signals (nidaq-based):
    - use daq toolbox callbacks to queue signals
    - use digital encoding to align signals for analysis
- Acquire data (nidaq-based):
    - acquireDaqChans continuously writes a logfile 
        - run from within runPipsSet or in a separate instance of Matlab     
        - e.g. to record random snippets use in separate Matlab instance 
- Run experiment:
    - runPipsInteractive.m opens interactive session of playing pips at some frequency determined by initial args to the function, and then by user input on command line.
        - takes # input as Hz of pips (limited range based on pip)
        - takes character input as type of pip (a,b,c etc.,)
        - calls makeAmpModSignals.m to generate waveforms
        - uses session-based interface to queue output data continuously  
    - runPipsSet.m will run a specific experiment with a number of different pips
        - a metadata json file is created that has

#### ./sound-files
- Contains example sound files for methods explanation
