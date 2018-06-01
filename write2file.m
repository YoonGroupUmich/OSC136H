function write2file

%   This script helps you create the valid .txt file for pipe
%   initialization. It writes the temp array to the file specified by filename.
%   Note that this script is independent of the GUI and OSC136H class, so any change is valid
%   as long as the .txt file read by the pipe is columns of specified amplitude ranging
%   from [0, 1023].

    fid = fopen('custom_waveform.pipe','wt');
    
    % To do
    SIZE = 32768;
    temp(SIZE, 1) = 0;
    for i = 1 : SIZE
        temp(i) = mod(i, 300);
    end
    
    % end
    
    fprintf(fid,'%d\n',temp);
    fprintf("Write Success to custom_waveform.pipe.\n");
    fclose(fid);
    
end