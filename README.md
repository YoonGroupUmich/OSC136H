# OSC1-36-H Optoelectrode Stimulation System - OSC136H Software Library/GUI
Matlab GUI and library for interacting with University of Michigan's OSC136H stimulation system.

## Installation
To use the OSC136H library requires the installation of Opal Kelly FrontPanel, Matlab 2015b (or newer), and the MinGW compiler for Matlab. The OSC136H library is currently only compatible with Windows 64-bit.

### Installing Opal Kelly Frontpanel
Use the included driver to install Opal Kelly Frontpanel on your PC. 

### Installing MinGW for Matlab
MinGW is available for all Matlab versions 2015b and newer, but requires a workaround for any version 2017a and previous. The work around is described in the Bug Report in the following link. 

https://www.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c++-compiler

## OSC136H Library
The OSC136H class is an object that represents the state of the OSC136H stimulation system. It maintains all the information describing the state of the system, and allows the user to modify this state. One can use this class to trigger LEDS and update waveform information. For parameter information, please see the parameter subsection.

### Example Usage
```
osc = OSC136H(); % Constructs OSC136H object
osc.Connect(<serial>); % Connects to board with serial number <serial>
osc.Configure('config.bit'); % Configures board with proper bitfile
osc.InitBoardFromConfigFile('config.txt'); % Initializes board parameters
osc.UpdateWaveformParams(2, 10, 10, 50, 100); % Updates waveform 2 parameters with 10 pulses @ 10 uA, 50 ms pulse width, 100 ms period
osc.UpdateChannelParams(1, 1, 0, 1); % Updates headstage 1 channel 1 parameters
osc.UpdateChannelParams(1, 2, 1, 2); % Updates headstage 1 channel 2 parameters
osc.TriggerChannel(1, 1); % triggers headstage 1, channel 1
osc.ToggleContinuous(3, 1, 1); % turns on continuous wave on headstage 3 channel 1
osc.OutputBoardState(); % outputs all current board parameters
```
### OSC Setup
The OSC136H class has several methods which are used to configure the system. If there are multiple Opal Kelly devices connected to your PC, you will need the serial number of the OSC136H to properly connect to the system. You will also need the serial number of your OSC136H Opal Kelly, if there are multiple Opal Kelly boards connected (for instance, an Intan Recording System).

#### `GetBoardSerials(this)`
Returns a list of all available Opal Kelly device serial numbers.

#### `Connect(this, serial)`
Connects OSC136H object to an OSC136H system. `serial` is a string argument that is the serial number of the OSC136H Opal Kelly. If `serial` is an empty string, will connect to the first available Opal Kelly board. Performs a system reset on initializing connection. Prints and returns -1 on error.

#### `Disconnect(this)`
Disconnects an OSC136H object. If there is a disconnect failure, or there is no Opal Kelly connected, returns -1 and prints an error message. 

#### `Configure(this, filename)`
Configures the internal FPGA with a bitfile specified by the string `filename`, as well as setting the Opal Kelly PLL clock. Prints on error. This function must be called with the configuration bitfile before using the system to ensure the system is properly initialized.

### Configuration Files
The OSC136H system parameters can be initialized by properly formatted configuration files. An example of a properly formatted configuration file is given below. Note that the comments provided are only for explanation, and a proper config file cannot have any comments. The system can be initialized by config files, and can also save current configurations to a config file. 

NOTE: The <pipe_wf> parameter is necessary in config files but is not included in any other functions in this implementation. 

```
0 0 1 # Headstage 1, Channel 1 parameters <pipe_wf> <trigger_type> <waveform_select>
0 0 1 # Headstage 1, Channel 2...
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1 # Headstage 2, Channel 1...
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1 # Headstage 3, Channel 1...
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
10 10 5 10 # Waveform 1 parameters <num_pulses> <amplitude (uA)> <pulse width (ms)> <period (ms)>
10 10 5 10 # Waveform 2 parameters...
10 10 5 10
10 10 5 10
```

#### `InitBoardFromConfigFile(this, filename)`
Initializes all board parameters from a given (properly formatted) configuration file. `filename` is a string argument referring to the name of the config file to load. Prints and returns on file opening error.

#### `SaveBoardToConfigFile(this, filename)`
Saves the current board configuration to a config file with name `filename`. Creates the file if it does not already exist.

### Modifying Channel Parameters
Each of the 36 OSC1 channels has 2 parameters. The first parameter `trig_select` is a boolean flag representing the trigger mode of the channel. The second parameter `fpga_wf` is the integer ID of the predefined waveform to use on the channel. Note that both channels and headstages are 1 indexed since the implementation is Matlab.

#### `UpdateChannelTriggerType(this, headstage, chan, trig)`
Updates the `chan` channel on the `headstage` headstage to have `trig` bit set as the trigger selector for the channel. `trig` must be a boolean flag of 1 or 0. If `trig` is 1, then the channel will be set to use the external trigger. If `trig` is 0, then the channel will be set to use the internal PC trigger (i.e. a call to `TriggerChannel(this, headstage, chan)`). Returns -1 and prints on error.

#### `UpdateChannelWaveform(this, headstage, chan, wf)`
Updates the `chan` channel on the `headstage` headstage to use the generated waveform defined by the integer identifier `wf`. Since there are four possible generated waveforms, `wf` must be a valid identifier in range [1,4]. Returns -1 and prints on error.

#### `UpdateChannelParams(this, headstage, chan, trig_select, fpga_wf)`
Performs all updates listed above. Prints on error.

### Modifying Waveform Parameters
The software library allows for 4 possible generated waveforms. Each of these waveforms is described by the following four parameters:
`num_pulses` - the number of pulses sent on a trigger (valid range 0-63)
`amplitude` - current amplitude in uA (valid range 0-1023)
`pulse_width` - width of a pulse in ms (valid range 0-637.5 in steps of 2.5 ms)
`period` - period of a pulse in ms (valid range 0-1275 in steps of 5 ms) 

Note that the duty cycle of a generated wave is `pulse_width / period`. Note that the waveforms are 1 indexed since the implementation is in Matlab.

#### `UpdateWaveformPulses(this, wf_num, num_pulses)`
Updates the waveform identified by `wf_num` to send `num_pulses` pulses on a trigger.

#### `UpdateWaveformAmplitude(this, wf_num, amp)`
Updates the waveform identified by `wf_num` to have amplitude `amp` in uA.

#### `UpdateWaveformPulseWidth(this, wf_num, pw)`
Updates the waveform identified by `wf_num` to have a pulse width of `pw` in ms. Note that `pw` must be a multiple of 2.5.

#### `UpdateWaveformPeriod(this, wf_num, period)`
Updates the waveform identified by `wf_num` to have a period of `period` in ms. Note that `period` must be a multiple of 5.

#### `UpdateWaveformParams(this, wf_num, num_pulses, amp, pw, period)`
Updates the waveform identified by `wf_num` to have the given parameters (see above functions).

### Trigger Types/Continuous Stimulation
The system supports both internal (from-PC) and external (any external source) triggers for channels. The type of trigger used by a channel can be changed by calling `UpdateChannelTriggerType`, documented earlier. There are two methods defined in the library to trigger channels, both defined below.

#### `TriggerChannel(this, headstage, chan)`
Sends an internal trigger to the `chan` channel on the `headstage` headstage. 

#### `ToggleContinuous(this, headstage, chan, toggle)`
Toggles continuous waveform output on the `chan` channel on the `headstage` headstage. If `toggle` is set to 1, then the channel will be continuously streaming. If `toggle` is set to 0, then the channel will be turned off. 

### Outputting Board State

#### `OutputBoardState(this)`
Outputs all board parameters in readable text format.

## OSC136H GUI
A visual interface for the above library is provided in the file 'OSCGUI.m'. The GUI can be built by clicking run in the matlab editor while viewing the file, or by typing `GUI = OSCGUI()` at the command prompt. 
