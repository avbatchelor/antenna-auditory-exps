function [count,data,id,name] = readDaqH5fs(h5filepath,chans)
%function [count,data,id,name] = readDaqH5fs(h5filepath,chans[=:])
    if ~exist('chans','var')
        info = h5info(h5filepath,'/daq');
        % count is its own Dataset
        chans = 1:(numel(info.Datasets)-1); 
    end
    
    count = h5read(h5filepath,['/daq/count']);
    iChan = 1;
    for chan = chans
        data{iChan} = h5read(h5filepath,['/daq' '/' num2str(chan)]);
        id{iChan}   = h5readatt(h5filepath,['/daq' '/' num2str(chan)],'id');
        name{iChan} = h5readatt(h5filepath,['/daq' '/' num2str(chan)],'name');
        iChan = iChan + 1;
    end
end
