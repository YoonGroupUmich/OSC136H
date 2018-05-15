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
The OSC136H class has several methods which are used to configure the system.

#### Connect(this, serial)

#### Disconnect(this, serial)

#### Configure

### Modifying Channel Parameters
Description of parameters

#### UpdateChannelParams()

#### Then do individual updates

### Modifying Waveform Parameters
Description of parameters

#### UpdateWaveformParams()

#### Then do individual updates

### Config Files
Describe config files
### Setting/Saving Parameters with Config Files
#### Init
#### Save

### Setting trigger types

### Triggering Channels/Continuous Stimulation

### Outputting Board State
## OSC136H GUI
