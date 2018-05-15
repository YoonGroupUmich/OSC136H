# OSC136H
Matlab GUI and library for interacting with University of Michigan's OSC136H stimulation system.

## Installation
To use the OSC136H library requires the installation of Opal Kelly FrontPanel, Matlab 2017b (or newer), and the MinGW compiler for Matlab.

### Installing Opal Kelly Frontpanel

### Installing Matlab

### Installing MinGW for Matlab

## OSC136H Library
The OSC136H class is an object that represents the state of the OSC136H stimulation system. It maintains all the information describing the state of the system, and allows the user to modify this state. One can use this class to trigger LEDS and update waveform information.

### Example Usage
```
osc = OSC136H();
osc.Connect(<serial>);
osc.Configure('config.bit');
osc.InitBoardFromConfigFile('config.txt');
osc.UpdateWaveformParams(2, 10, 10, 50, 100);
osc.UpdateChannelParams(1, 1, 0, 0, 1);
osc.UpdateChannelParams(1, 2, 0, 1, 2);
osc.TriggerChannel(1, 1);
osc.ToggleContinuous(3, 1, 1);
```
### OSC Configuration
The OSC136H class has several methods which are used to configure the system. If there are multiple Opal Kelly devices connected to your PC, you will need the serial number of the OSC136H to properly connect to the system.

#### GetBoardSerials(this)
Returns a list of all available Opal Kelly device serial numbers.

#### Connect(this, serial)
Connects OSC136H object to an OSC136H system. `serial` is a string argument that is the serial number of the OSC136H Opal Kelly. If `serial` is an empty string, will connect to the first available Opal Kelly board. Prints and returns -1 on error.

#### Disconnect(this)
Disconnects an OSC136H object. If there is a disconnect failure, or there is no Opal Kelly connected, returns -1 and prints an error message. 

#### Configure(this, filename)
Configures the internal FPGA with a bitfile specified by the string `filename`. Prints on error. This function must be called with the configuration bitfile before using the system to ensure the system is properly initialized.

### Configuration Files
The OSC136H system parameters can be initialized by properly formatted configuration files. An example of a properly formatted configuration file is given below:
```
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
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 0 1
0 1 2
0 1 2
0 1 2
0 1 2
0 1 2
0 1 2
10 10 5 10
8 8 5 5
6 6 10 20
4 4 7.5 15
```
### Modifying Channel Parameters
Description of parameters

#### UpdateChannelParams()

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
