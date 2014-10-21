function writeDaqH5fs(h5filepath,count,data,samplerate,precision,ids,names)
%function writeDaqH5fs(h5filepath,count,data,samplerate,precision,ids,names)
    % Path
    [pathstr,name,ext] = fileparts(h5filepath);
    if isempty(ext)
        ext = '.h5'
        h5filepath = fullfile(pathstr,[name ext]);
    end

    % Data / sampling parameters
    h5create(h5filepath,'/daq/count/',size(count),'Datatype',precision);
    h5write(h5filepath,'/daq/count/',count);
    h5writeatt(h5filepath,'/daq','samplerate',samplerate,)

    nSamps = size(data,1);
    for i = 1:size(data,2)
        h5create(h5filepath,['/daq' '/' num2str(i)],[1 nSamps],'Datatype',precision);
        h5write(h5filepath,['/daq' '/' num2str(i)],data(:,i));
        h5writeatt(h5filepath,['/daq' '/' num2str(i)],'id',ids{i});
        h5writeatt(h5filepath,['/daq' '/' num2str(i)],'name',names{i});
    end
end
