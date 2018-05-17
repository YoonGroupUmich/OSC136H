classdef OSCGUI < handle
    
    properties        
      os
      f
      
      serial_selector
      
      Channel_WF_selectors
      Channel_Trig_selectors
      
      WF_pulse_selectors
      WF_period_selectors
      WF_amp_selectors
      WF_pw_selectors
    end
    
    methods
        function obj = OSCGUI()
            obj.f = figure('Name', 'OSC136H Stim Control', 'NumberTitle', 'off', 'Visible','off','Units', 'characters', 'Position',[0 0 400 80]);
            set(obj.f, 'MenuBar', 'none');
            set(obj.f, 'ToolBar', 'none');
            
            obj.os = OSC136H();
            
            obj.Channel_WF_selectors = zeros(3, 12);
            obj.Channel_Trig_selectors = zeros(3, 12);
            
            obj.WF_pulse_selectors = zeros(4, 1);
            obj.WF_period_selectors = zeros(4, 1);
            obj.WF_amp_selectors = zeros(4, 1);
            obj.WF_pw_selectors = zeros(4, 1);
            
            obj.CreateSetup();
            obj.CreateHeadstagePanels();
            obj.CreateWaveformPanels();
            obj.f.Visible = 'on';
        end
        
        function CreateHeadstagePanels(this)
           for hs = 1:3
              hs_panel = uipanel('Title', strcat("Headstage ", num2str(hs)), 'FontUnits', 'normalized', 'FontSize', (1/14), 'BackgroundColor', 'white', 'Units', 'normalized',...
                  'Position', [.4 .7 - (.05 + ((hs - 1) * .3)) .55 .3]);
              this.PopulateHeadstagePanel(hs_panel, hs);
           end
        end
     
        function PopulateHeadstagePanel(this, parent, hs)
            for chan = 1:12
                uicontrol('Style', 'text', 'String', strcat('Shank ', num2str(ceil(chan / 3)), ' LED ', num2str(mod(chan - 1, 3) + 1)), 'Units', 'normalized', 'Parent',... 
                            parent, 'Position', [.0 .90 - (chan - 1) * (1/13) .1 1/13], 'Background', 'white');
                this.Channel_WF_selectors(hs, chan) = uicontrol('Style', 'popupmenu', 'String', {'Waveform 1', 'Waveform 2', 'Waveform 3', 'Waveform 4'}, 'Units', 'normalized', 'Parent',... 
                            parent, 'Position', [.1 .90 - (chan - 1) * (1/13) .2 1/13], 'Background', 'white', 'UserData', struct('hs', hs, 'chan', chan), 'Callback', @this.WFSelectorCB);
                this.Channel_Trig_selectors(hs, chan)= uicontrol('Style', 'popupmenu', 'String', {'PC Trigger', 'External Trigger'}, 'Units', 'normalized', 'Parent',... 
                            parent, 'Position', [.3 .90 - (chan - 1) * (1/13) .2 1/13], 'Background', 'white', 'UserData', struct('hs', hs, 'chan', chan), 'UserData', struct('hs', hs, 'chan', chan),...
                            'Callback', @this.TrigSelectorCB);
                uicontrol('Style', 'togglebutton', 'String', 'Continuous Stream', 'Units', 'normalized', 'Parent', parent, 'UserData', struct('hs', hs, 'chan', chan),... 
                            'Position', [.5 .90 - (chan - 1) * (1/13) .25 1/13], 'Background', 'y', 'UserData', struct('hs', hs, 'chan', chan), 'Callback', @this.ContinuousButtonCB);
                uicontrol('Style', 'pushbutton', 'String', ['Trigger Channel  ', num2str(chan)], 'Units', 'normalized', 'Callback', @this.TriggerCallback, 'Parent',... 
                            parent, 'Position', [.75 .90 - (chan - 1) * (1/13) .25 1/13], 'UserData', struct('Headstage', hs, 'Channel', chan));
            end
        end
        
        function WFSelectorCB(this, source, eventdata)
            this.os.UpdateChannelWaveform(source.UserData.hs, source.UserData.chan, get(source, 'Value'));
        end
        
        function TrigSelectorCB(this, source, eventdata)
            this.os.UpdateChannelTriggerType(source.UserData.hs, source.UserData.chan, get(source, 'Value') - 1);
        end
        
        function ContinuousButtonCB(this, source, eventdata)
            state = get(source, 'Value');
            if state == get(source, 'Max')
               this.os.ToggleContinuous(source.UserData.hs, source.UserData.chan, 1);
               set(source, 'Background', 'g');
            else
               this.os.ToggleContinuous(source.UserData.hs, source.UserData.chan, 0);
               set(source, 'Background', 'y');
            end
        end
        
        function CreateSetup(this)
            setup_panel = uipanel('Title', 'Setup', 'FontSize', 12, 'BackgroundColor', 'white', 'Units', 'normalized',...
                'Position', [.05 .78 .34 .17]);
            hbutton = uicontrol('Style','pushbutton','String','Connect','Units', 'normalized', 'Position',[.55 .65 .4 .3],'Callback',@this.ConnectCallback, 'Parent', setup_panel);
            align(hbutton,'Center','None');
            config_button = uicontrol('Style','pushbutton','String','Configure','Units', 'normalized', 'Position',[.05 .05 .30 .45],'Callback',@this.ConfigCallback, 'Parent', setup_panel);
            align(config_button,'Center','None');
            load_parameter_button = uicontrol('Style','pushbutton','String','Load Parameters from File','Units', 'normalized', 'Position',[.35 .05 .30 .45],...
                'Callback',@this.LoadParameterCallback, 'Parent', setup_panel);
            align(load_parameter_button,'Center','None');
            save_parameter_button = uicontrol('Style','pushbutton','String','Save Parameters To File','Units', 'normalized', 'Position',[.65 .05 .30 .45],...
                'Callback',@this.SaveParameterCallback, 'Parent', setup_panel);
            align(save_parameter_button,'Center','None');
            this.serial_selector = uicontrol('Style', 'popupmenu', 'String', this.os.GetBoardSerials(), 'Units', 'normalized', 'Parent',... 
                            setup_panel, 'Position', [.05 .65 .4 .2], 'Background', 'white');
            uicontrol('Style', 'text', 'String', 'Select your OSC136H Opal Kelly Serial', 'Units', 'normalized', 'Parent',...
                setup_panel, 'Position', [.05, .90, .4, .1], 'Background' , 'White')
            
            reset = uicontrol('Style','pushbutton','String','Reset','Units', 'normalized', 'Position',[.05 .05 .1 .05],'Callback',@this.ResetCallback, 'Background', 'r');
            align(reset,'Center','None');
        end
        
        function ResetCallback(this, source, eventdata)
            ec = this.os.SysReset();
            if ec == 0
               this.UpdateParamDisplay(); 
            end
        end
        
        function SaveParameterCallback(this, source, eventdata)
            [filename, path] = uiputfile('*.txt', 'Name Configuration File to Save');
            if ~isequal(filename, 0)
               this.os.SaveBoardToConfigFile(strcat(path, filename));
            end
            
        end
        function LoadParameterCallback(this, source, eventdata)
            [config_file, path] = uigetfile('*.txt', 'Select configuration txt file');
            if ~isequal(config_file, 0)
               this.os.InitBoardFromConfigFile(strcat(path, config_file));
               this.UpdateParamDisplay();
            end
        end
        
        function UpdateParamDisplay(this)
            for hs = 1:3
               for chan = 1:12
                  set(this.Channel_WF_selectors(hs,chan), 'Value', this.os.Channels((hs-1) * 12 + chan, 3));
                  set(this.Channel_Trig_selectors(hs,chan), 'Value', this.os.Channels((hs-1) * 12 + chan, 2) + 1);
               end
            end
            for wf = 1:4
                set(this.WF_pulse_selectors(wf), 'String', num2str(this.os.Waveforms(wf, 1))); 
                set(this.WF_amp_selectors(wf), 'String', num2str(this.os.Waveforms(wf, 2)));
                set(this.WF_pw_selectors(wf), 'String', num2str(this.os.Waveforms(wf, 3)));
                set(this.WF_period_selectors(wf), 'String', num2str(this.os.Waveforms(wf, 4)));
            end
        end
         
        function ConfigCallback(this, source, eventdata)
           [bitfile, path] = uigetfile('*.bit', 'Select the control bitfile');
           if ~isequal(bitfile, 0)
               this.os.Configure(strcat(path, bitfile));
           end
        end
        function CreateWaveformPanels(this)
            for wf = 1:4
               wf_panel = uipanel('Title', strcat("Waveform ", num2str(wf)), 'FontSize', 12, 'BackgroundColor', 'white', 'Units', 'normalized',...
                  'Position', [.05 .60 - ((wf -1) * .15) .34 .15]);
               this.PopulateWaveformPanels(wf_panel, wf);
            end
        end
        
        function PopulateWaveformPanels(this, parent, wf)
            uicontrol('Style', 'text', 'String', 'Number of Pulses', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.1 .75 .2 .2], 'Background', 'white');
            uicontrol('Style', 'text', 'String', 'Amplitude (uA)', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.6 .75 .2 .2], 'Background', 'white');
            uicontrol('Style', 'text', 'String', 'Pulse Width(ms)', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.1 .25 .2 .2], 'Background', 'white');
            uicontrol('Style', 'text', 'String', 'Period(ms)', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.6 .25 .2 .2], 'Background', 'white');
            
            this.WF_pulse_selectors(wf) = uicontrol('Style', 'edit', 'String', '0', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.1 .55 .2 .2], 'Background', 'white', 'UserData', struct('wf', wf), 'Callback', @this.PulseSelectCB);
            this.WF_amp_selectors(wf) = uicontrol('Style', 'edit', 'String', '0', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.6 .55 .2 .2], 'Background', 'white', 'UserData', struct('wf', wf), 'Callback', @this.AmpSelectCB);
            this.WF_pw_selectors(wf) = uicontrol('Style', 'edit', 'String', '0', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.1 .05 .2 .2], 'Background', 'white', 'UserData', struct('wf', wf), 'Callback', @this.PWSelectCB);
            this.WF_period_selectors(wf) = uicontrol('Style', 'edit', 'String', '0', 'Units', 'normalized', 'Parent',... 
                parent, 'Position', [.6 .05 .2 .2], 'Background', 'white', 'UserData', struct('wf', wf), 'Callback', @this.PeriodSelectCB);
        end
        
        function PulseSelectCB(this, source, eventdata)
            ec = 0;
            val = get(source, 'String');
            num = str2double(val);
            if ~isnan(num)
                ec = this.os.UpdateWaveformPulses(source.UserData.wf, num);
            end
            if isnan(num)
               errordlg('Please enter only numeric values for number of pulses.', 'Type Error');
               this.UpdateParamDisplay();
            end
            if ec == -1
               errordlg('Invalid value for num pulses, valid values integers in range 0 to 63', 'Num Pulses Range Error');
               this.UpdateParamDisplay();
            end
        end
        
        function AmpSelectCB(this, source, eventdata)
            ec = 0;
            val = get(source, 'String');
            num = str2double(val);
            if ~isnan(num)
                ec = this.os.UpdateWaveformAmplitude(source.UserData.wf, num);
            end
            if isnan(num)
               errordlg('Please enter only numeric values for amplitude.', 'Type Error');
               this.UpdateParamDisplay();
            end
            if ec == -1
               errordlg('Invalid value for amplitude, valid values integers in range 0 to 1023 uA', 'Amplitude Range Error');
               this.UpdateParamDisplay();
            end
        end
        
        function PWSelectCB(this,source, eventdata)
            ec = 0;
            val = get(source, 'String');
            num = str2double(val);
            if ~isnan(num)
                ec = this.os.UpdateWaveformPulseWidth(source.UserData.wf, num);
            end
            if isnan(num)
               errordlg('Please enter only numeric values for pulse width.', 'Type Error');
               this.UpdateParamDisplay();
            end
            if ec == -1
               errordlg('Invalid value for pulse width, valid values multiples of 2.5 in range 0 to 637.5 ms', 'Pulse Width Range Error');
               this.UpdateParamDisplay();
            end
        end
        
        function PeriodSelectCB(this, source, eventdata)
            ec = 0;
            val = get(source, 'String');
            num = str2double(val);
            if ~isnan(num)
                ec = this.os.UpdateWaveformPeriod(source.UserData.wf, num);
            end
            if ec == -1
               errordlg('Invalid value for period, valid values multiples of 5 in range 0 to 1275 ms', 'Period Range Error');
               this.UpdateParamDisplay();
            end
            if isnan(num)
               errordlg('Please enter only numeric values for period.', 'Type Error');
               this.UpdateParamDisplay();
            end
        end
        
        function TriggerCallback(this, source, eventdata)
            this.os.TriggerChannel(source.UserData.Headstage, source.UserData.Channel)
        end
            
        function ConnectCallback(this, source, eventdata)
            if source.String == "Connect"
                contents = get(this.serial_selector, 'String');
                serial_string = contents(get(this.serial_selector, 'Value'),:);
                ec = this.os.Connect(serial_string);
                if ec == 0
                    set(source, 'String', 'Disconnect');
                end
            else
                ec = this.os.Disconnect();
                if ec == 0
                    set(source, 'String', 'Connect');
                end
            end 
        end
        
        

    end
end