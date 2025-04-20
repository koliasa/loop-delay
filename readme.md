# Loop-Delay Plugin for OBS Studio

**Loop-Delay** is a Lua plugin for OBS Studio that automatically plays a media file (video or audio) after a specified delay from the start of streaming or recording. The plugin also allows you to configure media repetition with fixed or random intervals, set the number of repeats, adjust volume, and more.

## Features:
- **Automatic Media Playback**: Media starts playing after a specified delay from the start of streaming or recording.
- **Media Repetition**: Media can repeat indefinitely or a limited number of times.
- **Random Interval**: Allows setting a minimum and maximum interval for random timing between repeats.
- **Stop After Delay**: Media can automatically stop after a specified delay.
- **Media Volume Control**: Adjust the volume of the media source during playback.

---

## Installation

### Requirements:
1. **OBS Studio** version 27.0 or higher.
2. Lua scripting support (enabled by default in modern OBS versions).

### Instructions:
1. **Download the Plugin File**:
   - Save the `loop-delay.lua` file to your computer.

2. **Move the File to the OBS Scripts Folder**:
   - **Windows**: `C:\Users\<YourUsername>\AppData\Roaming\obs-studio\scripts`
   - **macOS**: `/Users/<YourUsername>/Library/Application Support/obs-studio/scripts`
   - **Linux**: `~/.config/obs-studio/scripts`

   If the `scripts` folder does not exist, create it.

3. **Restart OBS Studio**:
   - Open OBS, and the plugin will load automatically.

4. **Add the Plugin to Active Scripts**:
   - Go to `Tools > Scripts`.
   - Find `loop-delay.lua` in the list of available scripts and select it.

---

## Settings

### Main Parameters:
1. **Delay Before First Playback**:
   - Specify the time (in seconds) after which the media will start playing.

2. **Repeat Interval**:
   - **Minimum Interval**: Lower bound for the time between repeats (in seconds).
   - **Maximum Interval**: Upper bound for the time between repeats (in seconds).
   - If "Use random interval" is enabled, the time between repeats will be randomly chosen within the specified range.

3. **Number of Repeats**:
   - Specify how many times the media should repeat. If "Repeat forever" is enabled, the media will repeat indefinitely.

4. **Stop Media After Delay**:
   - Specify the time (in seconds) after which the media will automatically stop.

5. **Media Volume**:
   - Set the volume level of the media (from 0.0 to 1.0).

6. **Auto-Start**:
   - Choose whether the plugin should start automatically when streaming or recording begins.

---

## Usage

### Step 1: Set Up Media Source
1. Create a new media source in your OBS scene (`Media Source`).
2. Select the file to play (video or audio).
3. Remember the name of this source.

### Step 2: Configure the Plugin
1. Go to `Tools > Scripts`.
2. Select the `loop-delay.lua` plugin.
3. In the plugin settings:
   - Select the name of your media source.
   - Configure delay, intervals, number of repeats, and other parameters.

### Step 3: Testing
1. Start streaming or recording.
2. Observe the behavior of the media:
   - It should start playing after the specified delay.
   - Repeats should occur at the specified interval.
   - If a stop delay is set, the media should stop after that time.

---

## Supported Platforms

The plugin is compatible with the following operating systems:
- **Windows**
- **macOS**
- **Linux**

All these platforms support Lua scripting in OBS Studio.

---

## Issues and Support

If you encounter issues or have suggestions for improvement:
1. Check the OBS log (`View > Log Files > View Current Log`) for errors.
2. Contact the plugin author or create an issue on the project page.

---

## Author

This plugin was developed by Ihor Koliasa.  
License: MIT  
[GitHub Repository](https://github.com/koliasa/loop-delay)
