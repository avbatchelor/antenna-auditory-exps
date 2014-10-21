function [count,data] = loadDaqLog(filepath,nChans)
    fid   = fopen(filepath,'r');
    % all cards are single precision
    data  = single(fread(fid,'single'));
    data  = reshape(data,nChans+1,[]);
    count = data(1,:);
    data  = data(2:end,:);
    [~]   = fclose(fid);
end
