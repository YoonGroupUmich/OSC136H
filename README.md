# OSC136H
Matlab GUI and library for interacting with University of Michigan's OSC136H stimulation system.

## Installation
To use the OSC136H library requires the installation of Opal Kelly FrontPanel, Matlab 2017b (or newer), and the MinGW compiler for Matlab.

### Installing Opal Kelly Frontpanel

### Installing Matlab

### Installing MinGW for Matlab

## OSC136H Library
The OSC136H class is an object that represents the state of the OSC136H stimulation system. It maintains all the information describing the state of the system, and allows the user to modify this state. One can use this class to trigger LEDS and update waveform information. For parameter information, please see the parameter subsection.

### Example Usage
```
osc = OSC136H(); % Constructs OSC136H object
osc.Connect(<serial>); % Connects to board with serial number <serial>
osc.Configure('config.bit'); % Configures board with proper bitfile
osc.InitBoardFromConfigFile('config.txt'); % Initializes board parameters
osc.UpdateWaveformParams(2, 10, 10, 50, 100); % Updates waveform 2 parameters with 10 pulses @ 10 uA, 50 ms pulse width, 100 ms period
osc.UpdateChannelParams(1, 1, 0, 0, 1); % Updates headstage 1 channel 1 parameters
osc.UpdateChannelParams(1, 2, 0, 1, 2); % Updates headstage 1 channel 2 parameters
osc.TriggerChannel(1, 1); % triggers headstage 1, channel 1
osc.ToggleContinuous(3, 1, 1); % turns on continuous wave on headstage 3 channel 1
osc.OutputBoardState(); % outputs all current board parameters
```
### OSC Setup
The OSC136H class has several methods which are used to configure the system. If there are multiple Opal Kelly devices connected to your PC, you will need the serial number of the OSC136H to properly connect to the system.

#### GetBoardSerials(this)
Returns a list of all available Opal Kelly device serial numbers.

#### Connect(this, serial)
Connects OSC136H object to an OSC136H system. `serial` is a string argument that is the serial number of the OSC136H Opal Kelly. If `serial` is an empty string, will connect to the first available Opal Kelly board. Performs a system reset on initializing connection. Prints and returns -1 on error.

#### Disconnect(this)
Disconnects an OSC136H object. If there is a disconnect failure, or there is no Opal Kelly connected, returns -1 and prints an error message. 

#### Configure(this, filename)
Configures the internal FPGA with a bitfile specified by the string `filename`, as well as setting the Opal Kelly PLL clock. Prints on error. This function must be called with the configuration bitfile before using the system to ensure the system is properly initialized.

### Configuration Files
The OSC136H system parameters can be initialized by properly formatted configuration files. An example of a properly formatted configuration file is given below. Note that the comments provided are only for explanation, and a proper config file cannot have any comments. The system can be initialized by config files, and can also save current configurations to a config file. 
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

#### SaveBoardToConfigFile(this, filename)
Saves the current board configuration to a config file with name `filename`. Creates the file if it does not already exist.

### Modifying Channel Parameters
Each of the 36 OSC1 channels has 3 parameters. The first parameter `pipe_wf` is a boolean flag that is currently unused, but will be used in future versions to allow the user to send in a custom waveform. The second parameter `trig_select` is a boolean flag representing the trigger mode of the channel. The third parameter `fpga_wf` is the integer ID of the predefined waveform to use on the channel. 

#### UpdateChannelTriggerType(this, headstage, chan, trig)
This function updates the `chan` channel 

#### Then do individual updates

### Modifying Waveform Parameters
Description of parameters

#### UpdateWaveformParams()

#### Then do individual updates

### Setting/Saving Parameters with Config Files
#### Init
#### Save

### Setting trigger types

### Triggering Channels/Continuous Stimulation

### Outputting Board State
## OSC136H GUI
