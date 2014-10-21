function [data,count] = loadDaqLog(filepath,nChans)
    fid   = fopen(filepath,'r');
    data  = fread(fid,'double');
    data  = reshape(data,nChans,[]);
    count = data(1,:);
    data  = data(2:end,:);
    [~]   = fclose(fid);
end
