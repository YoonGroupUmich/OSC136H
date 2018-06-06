function write2file

%   This script helps you create the valid .txt file for pipe
%   initialization. It writes the temp array to the file specified by filename.
%   Note that this script is independent of the GUI and OSC136H class, so any change is valid
%   as long as the .txt file read by the pipe is columns of specified amplitude ranging
%   from [0, 1023].

    fid = fopen('custom_waveform.cwave','wt');
    
    % To do
    SIZE = 2000;
    temp(SIZE, 1) = 0;
    for i = 1 : SIZE
%         temp(i) = mod(i, 200);
          temp(i) = floor(100 * sin(i / (1000 / 2 / pi)) + 100);
    end
    
    % end
    
    fprintf(fid,'%d\n',temp);
    fprintf("Write Success to custom_waveform.cwave.\n");
    fclose(fid);
    
end