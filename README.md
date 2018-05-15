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
`osc = OSC136H()
osc.GetBoardSerials()
osc.Connect(<serial>)
osc.Configure('config.bit')
`
### OSC Configuration

### Modifying Channel Parameters

### Modifying Waveform Parameters

### Setting trigger types

### Triggering Channels/Continuous Stimulation

## OSC136H GUI
