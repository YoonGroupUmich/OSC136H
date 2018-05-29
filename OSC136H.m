classdef OSC136H < handle
    %   OSC136H Stimulation System
    %   Controller class for the OSC136H Stimulation System.
    %   Phil Dakin, 2018 @University of Michigan
    %   Note 1-indexing on function calls
    
    properties
        % Channels is a (36, 3) matrix, row corresponds to an individual
        % channel, columns are (pipe_in wf, trigger select, on_fpga wf)
        % Pipe_In wf - not used in current iteration
        % trigger select - 0 for PC trigger, 1 for external
        % on_fpga wf - waveform selector for generated wf 1:4 are options
        Channels
        
        % Waveforms is a (4, 4) matrix, row corresponds to an individual
        % pre-programmed waveform, columns are (num_pulses, amp, pw, period)
        % num_pulses - num_pulses sent on trigger
        % amp - amplitude of wave
        % pw - pulse width (describes duty cycle)
        % period - frequency (ms)
        Waveforms
        
        % OKFP Dev object for using the Opal Kelly FP Library
        dev
        
    end
    
    methods(Static)
        % MapChannel
        % Maps a headstage number and channel number to a value in range 
        % [1, 36] that is used by the library to identify the proper
        % communication locations to the OK FPGA.
        % Returns -1 on error.
        function chan = MapChannel(headstage_num, chan_num)
           NUM_HEADSTAGES = 3;
           CHANNELS_PER_HS = 12;
           if chan_num <= 0 || chan_num > CHANNELS_PER_HS || floor(chan_num) ~= chan_num
               fprintf('Invalid channel number.\n');
               chan = -1;
               return
           end
           if headstage_num <= 0 || headstage_num > NUM_HEADSTAGES
               fprintf('Invalid headstage number.\n');
               chan = -1;
               return
           end
           chan = (NUM_HEADSTAGES - headstage_num ) * CHANNELS_PER_HS + chan_num;
        end
    
        % GetChannelWireInfo
        % Takes a channel identifier in range [1, 36] to the OK endpoint
        % that contains the parameters for this channel. Also returns a
        % value "begin" which represents the least significant bit of the
        % channels parameter information, in the OK WireIn.
        function [endpoint, begin] = GetChannelWireInfo(chan)
            INDEX_OFFSET = 1;
            CHANNELS_PER_WIRE = 4;
            INITIAL_WIRE_ENDPOINT = hex2dec('09');
            PARAMETER_BITS = 4;
            
            wire_offset = floor((chan - INDEX_OFFSET) / CHANNELS_PER_WIRE);
            endpoint = INITIAL_WIRE_ENDPOINT + wire_offset;
            in_wire_offset = mod(chan - INDEX_OFFSET, CHANNELS_PER_WIRE);
            begin = PARAMETER_BITS * in_wire_offset;
        end
        
        function [endpoint_a, endpoint_b] = GetWaveformWireInfo(wf)
            INITIAL_WF_WIRE = hex2dec('01');
            WF_OFFSET = 1;
            WIRES_PER_WF = 2;
            endpoint_a = INITIAL_WF_WIRE + (wf - WF_OFFSET) * WIRES_PER_WF;
            endpoint_b = endpoint_a + 1;
        end
    end
    
    methods
        % OSC136H Constructor
        % Initializes the channel and waveform information to all zeroes.
        % Also loads the OK library, and constructs a dev object that will
        % be used for all library interactions with FrontPanel.
        function obj = OSC136H()
            if ~libisloaded('okFrontPanel')
                loadlibrary('okFrontPanel', 'okFrontPanelDLL.h');
            end
            % Initialize a new OSC136H object
            obj.Channels = zeros(36, 3); 
            obj.Waveforms = zeros(4, 4);
            obj.dev = calllib('okFrontPanel', 'okFrontPanel_Construct');
            fprintf('Successfully loaded okFrontPanel.\n');
        end
        
        % OSC136H Destructor
        % Disconnects from the board to prevent connection issues when
        % using multiple instances of the classes. 
        function delete(this)
             this.Disconnect();
        end
        
        % isOpen
        % Checks if we are currently connected to a board.
        function open = isOpen(this)
            open = calllib('okFrontPanel', 'okFrontPanel_IsOpen', this.dev);
        end
        
        % OutputWireInVal
        % Reads the value at a given WireIn endpoint using FP and outputs
        % the 16-bit wire. Useful for checking whether updates worked
        % correctly.
        function OutputWireInVal(this, endpoint)
            WIREIN_SIZE = 16;
            buf = libpointer('uint32Ptr', 10);
            calllib('okFrontPanel', 'okFrontPanel_GetWireInValue', this.dev, endpoint, buf);
            fprintf('WireIn %d: ', endpoint);
            fprintf(dec2bin(get(buf, 'Value'), WIREIN_SIZE));
            fprintf('\n');
        end
        
        % WriteToWireIn
        % Takes an OK FP WireIn endpoint, a beginning bit, a write length,
        % and a value. Writes the first write_length bits of value into the
        % WireIn specified by endpoint, starting at the location begin.
        function WriteToWireIn(this, endpoint, begin, write_length, value)
            % Mask constructed to isolate desired bits.
            mask = (2 ^ write_length) - 1;
            shifter = begin;
            mask = bitshift(mask, shifter);
            val =  bitshift(bitor(0, value), shifter);
            calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', this.dev, endpoint, val, mask);
            calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', this.dev);
        end
        
        % Disconnect
        % Attempts to disconnect a connected OK FPGA.
        function ec = Disconnect(this)
           if ~this.isOpen()
              fprintf('No open board to disconnect!\n');
              ec = 0;
              return
           end
           this.SysReset();
           calllib('okFrontPanel', 'okFrontPanel_Close', this.dev);
           if this.isOpen()
               fprintf('Failed to close board\n')
               ec = -1;
               return
           end
           fprintf('Successfully closed board\n')
           ec = 0;
        end
        
        % Configure
        % Takes a filename as a path to the bitfile, and loads it onto the
        % FPGA. The desired bitfile is titled 'config.bit'.
        function Configure(this, filename)
           ec = calllib('okFrontPanel', 'okFrontPanel_ConfigureFPGA', this.dev, filename);
           if ec ~= "ok_NoError"
               fprintf('Error loading bitfile\n')
               return
           end
           fprintf("Succesfully loaded bitfile\n");
           
           pll = calllib('okFrontPanel', 'okPLL22150_Construct');
           calllib('okFrontPanel', 'okPLL22150_SetReference', pll, 48.0, 0);
           calllib('okFrontPanel', 'okPLL22150_SetVCOParameters', pll, 512, 125);
           
           calllib('okFrontPanel', 'okPLL22150_SetDiv1', pll, 'ok_DivSrc_VCO', 15);
           calllib('okFrontPanel', 'okPLL22150_SetDiv2', pll, 'ok_DivSrc_VCO', 8);
           
           calllib('okFrontPanel', 'okPLL22150_SetOutputSource', pll, 0, 'ok_ClkSrc22150_Div1ByN');
           calllib('okFrontPanel', 'okPLL22150_SetOutputEnable', pll, 0, 1);
           
           calllib('okFrontPanel', 'okPLL22150_SetOutputSource', pll, 1, 'ok_ClkSrc22150_Div2ByN');
           calllib('okFrontPanel', 'okPLL22150_SetOutputEnable', pll, 1, 1);
           
           calllib('okFrontPanel', 'okFrontPanel_SetPLL22150Configuration', this.dev, pll);
        end
        
        % Connect
        % Connects the board to the first openly available FPGA.
        function ec = Connect(this, serial)
            % For now, all this function does is connect to the first
            % available board.
            this.dev = calllib('okFrontPanel', 'okFrontPanel_Construct');
            calllib('okFrontPanel', 'okFrontPanel_OpenBySerial', this.dev, serial);
            open = calllib('okFrontPanel', 'okFrontPanel_IsOpen', this.dev);
            if ~open
                fprintf('Failed to open board\n')
                ec = -1;
                return
            end
            this.SysReset();
            fprintf('Successfully opened board\n')
            ec = 0;
        end
        
        % OutputBoardState
        % Outputs all possible board paramaters in readable format.
        function OutputBoardState(this)
           fprintf('Outputting OSC136H Board State\n')
           counter = 1;
           
           for hs = 1:3
              for chan = 1:12
                  fprintf('Headstage %d Channel %d ', hs, chan);
                  fprintf('pipe_wf %d trigger select %d wf %d\n', this.Channels(counter, 1),...
                      this.Channels(counter, 2), this.Channels(counter, 3));
                  counter = counter + 1;
              end
           end
           totWaveforms = 4;
           for wave = 1:totWaveforms
               fprintf('Wave %d num_pulses %d amp(uA) %d pulse_width(ms) %d period(ms) %d', wave, this.Waveforms(wave, 1),...
                   this.Waveforms(wave, 2), this.Waveforms(wave, 3), this.Waveforms(wave, 4));
               fprintf('\n')
           end
        end
        
        % InitBoardFromConfigFile
        % Takes no arguments, initializes board from config.txt.
        function InitBoardFromConfigFile(this, filename)
            fprintf('Initializing board state from %s\n', filename)
            fd = fopen(filename, 'r');
            if fd == -1
               fprintf('Error opening config file.\n');
               return
            end
            this.Channels = fscanf(fd, '%f', size(this.Channels.'));
            this.Waveforms = fscanf(fd, '%f', size(this.Waveforms.'));
            this.Channels = this.Channels.';
            this.Waveforms = this.Waveforms.';
            fclose(fd);
            
            NUM_HS = 3;
            NUM_CHANNELS = 12;
            counter = 1;
            for hs = 1:NUM_HS
               for chan = 1:NUM_CHANNELS
                    this.UpdateChannelParams(hs, chan, this.Channels(counter, 2), this.Channels(counter, 3));
                    counter = counter + 1;
               end
            end
            for wf = 1:4
               this.UpdateWaveformParams(wf, this.Waveforms(wf, 1),...
                    this.Waveforms(wf, 2),  this.Waveforms(wf, 3),  this.Waveforms(wf, 4));
            end
        end
        
        % Saves State of Board to Config File with name Filename
        function SaveBoardToConfigFile(this, filename)
            fprintf('Writing board configuration to file %s\n', filename);
            fd = fopen(filename, 'w');
            fprintf(fd, '%f %f %f\n', this.Channels.');
            fprintf(fd, '%f %f %f %f\n', this.Waveforms.');
            fclose(fd);
        end
        
        % Gets list of serial numbers for all connected boards
        function serials = GetBoardSerials(this)
            serials = 'No connected devices';
            device_count = calllib('okFrontPanel', 'okFrontPanel_GetDeviceCount', this.dev);
            for d = 0:(device_count - 1)
                sn = calllib('okFrontPanel', 'okFrontPanel_GetDeviceListSerial', this.dev, d, blanks(30));
                if ~exist('snlist', 'var')
                    snlist = sn;
                else
                    snlist = char(snlist, sn);
                end
            end
            if exist('snlist', 'var')
                serials = snlist;
            end
        end
        
        % TriggerChannel
        % Triggers a specific headstage channel.
        function TriggerChannel(this, headstage, chan)
            if ~this.isOpen()
                fprintf('Board not connected\n')
                return
            end
            chan_num = this.MapChannel(headstage, chan);
            if chan_num == -1
               return
            end
            INITIAL_ENDPOINT = hex2dec('40');
            CHANNELS_PER_TRIG = 16;
            INDEX_OFFSET = 1;
            
            endpoint = INITIAL_ENDPOINT + floor(chan_num / CHANNELS_PER_TRIG);
            bit = mod(chan_num - INDEX_OFFSET, CHANNELS_PER_TRIG); % matlab one indexed
            ec = calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', this.dev, endpoint, bit);
            if ec ~= "ok_NoError"
               fprintf('Error triggering channel\n')
               return
           end
           fprintf("Triggered channel %d hs %d\n", chan, headstage);
        end
        
        % Channel Update Functions
        % Each of these functions is used to update the parameters of an
        % individual channel. There are three functions that update the 3
        % individual parameters, and one function that can be used to
        % update all three parameters.
        function ec = UpdateChannelTriggerType(this, headstage, chan, trig)
            if ~this.isOpen()
                fprintf('Board not open\n')
                ec = -1;
                return
            end
            if trig ~= 0 && trig ~= 1
               fprintf('Valid arguments to trig_select are 1 and 0. Error.\n');
               ec = -1;
               return
            end
    
            chan_num = this.MapChannel(headstage, chan);
            if chan_num == -1
               ec = -1;
               return
            end
            PARAM_SIZE = 1; % One bit of trig information.
            PARAM_OFFSET = 2; % 2 bits of offset for param location. 
            
            [endpoint, begin] = this.GetChannelWireInfo(chan_num);
            this.OutputWireInVal(endpoint);
            this.WriteToWireIn(endpoint, begin + PARAM_OFFSET, PARAM_SIZE, trig);
            this.OutputWireInVal(endpoint);
            this.Channels((headstage - 1) * 12 + chan, 2) = trig;
            ec = 0;
        end
        
        function ec = UpdateChannelPipeWf(this, headstage, chan, pipe_wf)
            if ~this.isOpen()
                fprintf('Board not open\n')
                ec = -1;
                return
            end
            % Check for boolean nature of pipe_wf.
            if pipe_wf ~= 0 && pipe_wf ~= 1
               fprintf('Valid arguments to pipe_wf are 1 and 0. Error.\n');
               ec = -1;
               return
            end
            
            chan_num = this.MapChannel(headstage, chan);
            if chan_num == -1
               ec = -1;
               return
            end
            PARAM_SIZE = 1; % One bit of PipeWf information.
            PARAM_OFFSET = 3; % 3 bits of offset for param location. 
            
            [endpoint, begin] = this.GetChannelWireInfo(chan_num);
            this.OutputWireInVal(endpoint);
            this.WriteToWireIn(endpoint, begin + PARAM_OFFSET, PARAM_SIZE, pipe_wf);
            this.OutputWireInVal(endpoint);
            this.Channels((headstage - 1) * 12 + chan, 1) = pipe_wf;
            ec = 0;
        end
        
        function ec = UpdateChannelWaveform(this, headstage, chan, wf)
            if ~this.isOpen()
                fprintf('Board not open\n')
                ec = -1;
                return
            end
            if wf <= 0 || wf > 4
               fprintf('Valid fpga_wf in range [1, 4]. Error.\n');
               ec = 1;
               return
            end
    
            chan_num = this.MapChannel(headstage, chan);
            if chan_num == -1
               ec = -1;
               return
            end
            PARAM_SIZE = 2; % Two bits of waveform selector.
            PARAM_OFFSET = 0; % 0 bits of offset for param location.
            WF_IDX_OFFSET = 1;
            
            [endpoint, begin] = this.GetChannelWireInfo(chan_num);
            this.OutputWireInVal(endpoint);
            this.WriteToWireIn(endpoint, begin + PARAM_OFFSET, PARAM_SIZE, wf - WF_IDX_OFFSET);
            this.OutputWireInVal(endpoint);
            this.Channels((headstage - 1) * 12 + chan, 3) = wf;
            ec = 0;
        end
        
        function UpdateChannelParams(this, headstage, chan, trig_select, fpga_wf)
            pipe_wf = 0;
            if this.UpdateChannelTriggerType(headstage, chan, trig_select) == -1
                return
            elseif this.UpdateChannelWaveform(headstage, chan, fpga_wf) == -1
                return
            elseif this.UpdateChannelPipeWf(headstage, chan, pipe_wf) == -1
                return
            else
                fprintf('Succesfully updated channel parameters.\n');
            end
        end
        
        % Waveform Update Functions
        % Each of these functions is used to update the parameters of an
        % individual waveform.
        
        % Sets number of pulses in the waveform
        function ec = UpdateWaveformPulses(this, wf_num, num_pulses)
            if ~this.isOpen()
                fprintf('Board not open\n')
                ec = -1;
                return
            end
            if wf_num <= 0 || wf_num > 4
               fprintf('Invalid waveform selector. Error.\n');
               ec = -1;
               return
            end
            if num_pulses < 0 || num_pulses > 63
               fprintf('Invalid num_pulses. Valid range [0, 63].\n');
               ec = -1;
               return
            end
            
            [~, endpoint_b] = this.GetWaveformWireInfo(wf_num);
            this.OutputWireInVal(endpoint_b);
            
            PARAM_OFFSET = 10;
            PARAM_SIZE = 6;
            this.WriteToWireIn(endpoint_b, PARAM_OFFSET, PARAM_SIZE, num_pulses);
            this.OutputWireInVal(endpoint_b);
            this.Waveforms(wf_num, 1) = num_pulses;
            ec = 0;
            
        end
        
        % Sets waveform amplitude in uA
        function ec = UpdateWaveformAmplitude(this, wf_num, amp)
            if ~this.isOpen()
                fprintf('Board not open\n')
                ec = -1;
                return
            end
            if wf_num <= 0 || wf_num > 4
               fprintf('Invalid waveform selector. Error.\n');
               ec = -1;
               return
            end
            if amp < 0 || amp > 1023
                fprintf('Invalid amplitude. Valid range [0, 1023].\n');
                ec = -1;
                return
            end
            [~, endpoint_b] = this.GetWaveformWireInfo(wf_num);
            this.OutputWireInVal(endpoint_b);
            PARAM_OFFSET = 0;
            PARAM_SIZE = 10;
            this.WriteToWireIn(endpoint_b, PARAM_OFFSET, PARAM_SIZE, amp);
            this.OutputWireInVal(endpoint_b);
            this.Waveforms(wf_num, 2) = amp;
            ec = 0;
        end
        
        % Sets waveform pulse width in mS
        function ec = UpdateWaveformPulseWidth(this, wf_num, pw)
            if ~this.isOpen()
                fprintf('Board not open\n')
                ec = -1;
                return
            end
            if wf_num <= 0 || wf_num > 4
               fprintf('Invalid waveform selector. Error.\n');
               ec = -1;
               return
            end
            PULSE_WIDTH_STEP = 2.5; %ms
            pw_val = pw / PULSE_WIDTH_STEP;
            
            if floor(pw_val) ~= pw_val
               fprintf('Please enter pulse width as a multiple of 2.5.\n');
               ec = -1;
               return
            end
            if pw_val < 0 || pw_val > 255
               fprintf('Pulse width out of range.\n');
               ec = -1;
               return
            end
            [endpoint_a, ~] = this.GetWaveformWireInfo(wf_num);
            
            this.OutputWireInVal(endpoint_a);
            PARAM_OFFSET = 8;
            PARAM_SIZE = 8;
            this.WriteToWireIn(endpoint_a, PARAM_OFFSET, PARAM_SIZE, pw_val);
            this.OutputWireInVal(endpoint_a);
            this.Waveforms(wf_num, 3) = pw;
            ec = 0;
        end
        
        % Sets waveform period in mS
        function ec = UpdateWaveformPeriod(this, wf_num, period)
            if ~this.isOpen()
                fprintf('Board not open\n')
                ec = -1;
                return
            end
            if wf_num <= 0 || wf_num > 4
               fprintf('Invalid waveform selector. Error.\n');
               ec = -1;
               return
            end
            PERIOD_STEP = 5; %ms
            period_val = period / PERIOD_STEP;
            if floor(period_val) ~= period_val
               fprintf('Please enter pulse width as a multiple of 2.5, period as a multiple of 5. \n');
               ec = -1;
               return
            end
            if period_val < 0 || period_val > 255
               fprintf('Period value out of range.\n');
               ec = -1;
               return
            end
            [endpoint_a, ~] = this.GetWaveformWireInfo(wf_num);
            
            this.OutputWireInVal(endpoint_a);
            PARAM_OFFSET = 0;
            PARAM_SIZE = 8;
            this.WriteToWireIn(endpoint_a, PARAM_OFFSET, PARAM_SIZE, period_val);
            this.OutputWireInVal(endpoint_a);
            this.Waveforms(wf_num, 4) = period;
            ec = 0;
        end
        
        function UpdateWaveformParams(this, wf_num, num_pulses, amp, pw, period)
            % wf_num is one indexed in software, valid range is [1,4].
            
            if this.UpdateWaveformPulses(wf_num, num_pulses) == -1
                return
            elseif this.UpdateWaveformAmplitude(wf_num, amp) == -1
                return
            elseif this.UpdateWaveformPulseWidth(wf_num, pw) == -1
                return
            elseif this.UpdateWaveformPeriod(wf_num, period) == -1
                return
            else
                fprintf('Succesfully updated waveform parameters.\n');
            end
        end
        
        % Reset the electronics, as well as setting all parameters to 0.
        function ec = SysReset(this)
            ec = 0;
            open = calllib('okFrontPanel', 'okFrontPanel_IsOpen', this.dev);
            if ~open
                fprintf('Failed to open board\n')
                ec = -1;
                return
            end
            
            fprintf('Reseting system to default state\n')
            this.Channels = zeros(36, 3); 
            this.Waveforms = zeros(4, 4);
            calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', this.dev, hex2dec('00'), 1, 1);
            calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', this.dev);
            calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', this.dev, hex2dec('00'), 0, 1);
            calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', this.dev);
            for head = 1:3
                for chan = 1:12
                    this.UpdateChannelParams(head, chan, 0, 1);
                    this.ToggleContinuous(head, chan, 0);
                end
            end
            fprintf('\n');
            for wf = 1:4
                this.UpdateWaveformParams(wf, 0, 0, 0, 0);
            end
        end
        
        % Toggle continuous streaming for an individual channel.
        function ToggleContinuous(this, headstage, chan, toggle)
            if ~this.isOpen()
                fprintf('Board not open\n')
                return
            end
            
            chan_num = this.MapChannel(headstage, chan);
            if chan_num == -1
                return
            end
            offset = floor((chan_num - 1) / 16);
            endpoint = hex2dec('12') + offset;
            in_wire_offset = mod((chan_num -1), 16);
            
            this.OutputWireInVal(endpoint);
            
            calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', this.dev, endpoint, bitshift(toggle, in_wire_offset), bitshift(1, in_wire_offset));
            calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', this.dev);
            
            this.OutputWireInVal(endpoint);
            
        end
    end
end

