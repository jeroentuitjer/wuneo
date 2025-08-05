# WUNEO

A Flutter app with AirPod radar detection and retro-style interface.

## Features

- **AirPod Radar**: Real-time Bluetooth scanning to detect AirPods and other devices
- **Device Tracking**: Counts unique devices seen during radar sessions
- **Retro Interface**: ASCII art style with green terminal aesthetics
- **Real-time Updates**: Live device detection with signal strength indicators
- **Cross-platform**: Works on iOS and Android

## AirPod Radar

The main feature of WUNEO is the AirPod Radar that:

- **Scans for Bluetooth devices** in real-time
- **Detects AirPods** and other Apple devices
- **Shows signal strength** with color-coded dots:
  - 🟢 Green: Strong signal (close by)
  - 🔵 Cyan: Medium signal
  - 🟡 Yellow: Weak signal
  - 🔴 Red: Very weak signal (far away)
- **Tracks unique devices** seen during each session
- **Displays device names** next to each dot
- **Animated radar sweep** for authentic radar feel

## Running the App

```bash
flutter pub get
flutter run
```

## Bluetooth Permissions

The app requires Bluetooth permissions to scan for devices:

- **iOS**: Automatically requests permission when radar is opened
- **Android**: Requires location permission for Bluetooth scanning

## Architecture

- **Services**: Bluetooth scanning and device management
- **Widgets**: Custom radar display with ASCII art style
- **State Management**: Real-time device tracking and counting
- **Platforms**: iOS and Android support

## Usage

1. **Open the app** to see the WUNEO menu
2. **Select "AirPod Radar"** to start scanning
3. **Watch the radar** for detected devices
4. **Check the counter** in the top-right for device statistics
5. **Tap anywhere** to return to the main menu

The radar will continuously scan for nearby Bluetooth devices and display them as colored dots on the radar screen.
