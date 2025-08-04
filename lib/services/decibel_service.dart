import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;

class DecibelService {
  static final DecibelService _instance = DecibelService._internal();
  factory DecibelService() => _instance;
  DecibelService._internal();

  double _airpodsDecibels = 0.0; // Start at 0 when not connected
  double _ambientDecibels = 45.0;
  Timer? _updateTimer;
  final Random _random = Random();
  DateTime _lastUpdate = DateTime.now();
  blue.BluetoothDevice? _airpodsDevice;
  bool _airpodsConnected = false;

  double get airpodsDecibels => _airpodsDecibels;
  double get ambientDecibels => _ambientDecibels;
  bool get isAirpodsConnected => _airpodsConnected;

  void initialize() {
    // Start periodic decibel updates
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateDecibels();
    });
  }

  void setAirpodsDevice(blue.BluetoothDevice device) {
    _airpodsDevice = device;
    print('Decibel Service: AirPods device set: ${device.platformName}');
  }

  void _updateDecibels() {
    final now = DateTime.now();
    final timeOfDay = now.hour;
    final minute = now.minute;

    if (_airpodsDevice != null) {
      // Try to read real ambient noise from AirPods microphones
      _readAirpodsAmbientNoise();
    } else {
      // Fallback to time-based simulation
      _simulateAmbientNoise(timeOfDay, minute);
    }

    // Only simulate AirPods volume if they are actually connected
    if (_airpodsConnected && _airpodsDevice != null) {
      // Simulate AirPods volume based on ambient and time
      double baseAirpods = _ambientDecibels + 15; // Usually louder than ambient

      // Adjust based on time of day (people listen louder in quiet times)
      if (timeOfDay >= 20 || timeOfDay < 7) {
        baseAirpods += 5; // Night listening is often louder
      }

      // Add realistic variation
      final airpodsVariation = (_random.nextDouble() - 0.5) * 12;
      _airpodsDecibels = (baseAirpods + airpodsVariation).clamp(40.0, 95.0);
    } else {
      // AirPods not connected, set to 0
      _airpodsDecibels = 0.0;
    }

    _lastUpdate = now;

    print(
        'Decibel Service: Time: ${timeOfDay.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}, Ambient: ${_ambientDecibels.toStringAsFixed(1)} dB, AirPods: ${_airpodsDecibels.toStringAsFixed(1)} dB (Connected: $_airpodsConnected)');
  }

  Future<void> _readAirpodsAmbientNoise() async {
    try {
      if (_airpodsDevice == null) return;

      // Check if AirPods are connected
      _airpodsConnected = _airpodsDevice!.isConnected;

      if (!_airpodsConnected) {
        print('Decibel Service: AirPods not connected');
        _airpodsDecibels = 0.0;
        return;
      }

      // Discover services
      final services = await _airpodsDevice!.discoverServices();

      // Look for audio/microphone service
      for (var service in services) {
        if (service.uuid.toString().toLowerCase().contains('audio') ||
            service.uuid.toString().toLowerCase().contains('microphone')) {
          // Read microphone characteristics
          for (var characteristic in service.characteristics) {
            if (characteristic.properties.read) {
              try {
                final value = await characteristic.read();
                // Convert raw microphone data to decibels
                _ambientDecibels = _convertRawToDecibels(value);
                print(
                    'Decibel Service: Real ambient noise from AirPods: ${_ambientDecibels.toStringAsFixed(1)} dB');
                return;
              } catch (e) {
                print('Decibel Service: Error reading AirPods microphone: $e');
              }
            }
          }
        }
      }

      // If no real data available, fall back to simulation
      _simulateAmbientNoise(DateTime.now().hour, DateTime.now().minute);
    } catch (e) {
      print('Decibel Service: Error accessing AirPods: $e');
      _airpodsConnected = false;
      _airpodsDecibels = 0.0;
      _simulateAmbientNoise(DateTime.now().hour, DateTime.now().minute);
    }
  }

  double _convertRawToDecibels(List<int> rawData) {
    // Convert raw microphone data to decibels
    // This is a simplified conversion - real implementation would be more complex
    if (rawData.isEmpty) return 45.0;

    // Calculate RMS (Root Mean Square) of the audio data
    double sum = 0;
    for (int i = 0; i < rawData.length; i++) {
      sum += rawData[i] * rawData[i];
    }
    double rms = sqrt(sum / rawData.length);

    // Convert to decibels (simplified)
    // Assuming 16-bit audio, max value is 32767
    double normalized = rms / 32767;
    if (normalized <= 0) return 30.0;

    // Convert to dB scale (30-80 dB range)
    double db = 30 + (20 * log(normalized) / ln10);
    return db.clamp(30.0, 80.0);
  }

  void _simulateAmbientNoise(int timeOfDay, int minute) {
    // Simulate realistic ambient noise based on time of day
    double baseAmbient = 40.0; // Default quiet level

    // Morning rush (7-9 AM): higher ambient noise
    if (timeOfDay >= 7 && timeOfDay < 9) {
      baseAmbient = 55.0 + _random.nextDouble() * 10;
    }
    // Lunch time (12-14): moderate noise
    else if (timeOfDay >= 12 && timeOfDay < 14) {
      baseAmbient = 50.0 + _random.nextDouble() * 8;
    }
    // Afternoon (14-17): normal working noise
    else if (timeOfDay >= 14 && timeOfDay < 17) {
      baseAmbient = 45.0 + _random.nextDouble() * 6;
    }
    // Evening (17-20): quieter
    else if (timeOfDay >= 17 && timeOfDay < 20) {
      baseAmbient = 42.0 + _random.nextDouble() * 5;
    }
    // Night (20-7): very quiet
    else {
      baseAmbient = 35.0 + _random.nextDouble() * 8;
    }

    // Add some realistic variation
    final ambientVariation = (_random.nextDouble() - 0.5) * 8;
    _ambientDecibels = (baseAmbient + ambientVariation).clamp(30.0, 75.0);
  }

  String getAirpodsDecibelStatus() {
    if (!_airpodsConnected) {
      return 'AirPods: Not Connected';
    }

    // Get connected device info
    String deviceInfo = '';
    if (_airpodsDevice != null) {
      deviceInfo = ' → ${_airpodsDevice!.platformName}';
    }

    if (_airpodsDecibels < 60) {
      return 'AirPods: ${_airpodsDecibels.toStringAsFixed(1)} dB (Safe)';
    } else if (_airpodsDecibels < 75) {
      return 'AirPods: ${_airpodsDecibels.toStringAsFixed(1)} dB (Moderate)';
    } else if (_airpodsDecibels < 85) {
      return 'AirPods: ${_airpodsDecibels.toStringAsFixed(1)} dB (Loud)';
    } else {
      return 'AirPods: ${_airpodsDecibels.toStringAsFixed(1)} dB (Very Loud)';
    }
  }

  String getAirpodsDeviceInfo() {
    if (!_airpodsConnected || _airpodsDevice == null) {
      return 'AirPods: Not Connected';
    }
    return 'AirPods → ${_airpodsDevice!.platformName}';
  }

  String getAmbientDecibelStatus() {
    // Als AirPods niet verbonden zijn, toon geen omgevingsgeluid
    if (!_airpodsConnected) {
      return 'Room: No Data';
    }

    if (_ambientDecibels < 40) {
      return 'Room: ${_ambientDecibels.toStringAsFixed(1)} dB (Quiet)';
    } else if (_ambientDecibels < 55) {
      return 'Room: ${_ambientDecibels.toStringAsFixed(1)} dB (Normal)';
    } else if (_ambientDecibels < 65) {
      return 'Room: ${_ambientDecibels.toStringAsFixed(1)} dB (Loud)';
    } else {
      return 'Room: ${_ambientDecibels.toStringAsFixed(1)} dB (Very Loud)';
    }
  }

  Color getAirpodsDecibelColor() {
    if (!_airpodsConnected) {
      return Colors.grey;
    }

    if (_airpodsDecibels < 60) {
      return Colors.green;
    } else if (_airpodsDecibels < 75) {
      return Colors.yellow;
    } else if (_airpodsDecibels < 85) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color getAmbientDecibelColor() {
    // Als AirPods niet verbonden zijn, toon grijze kleur
    if (!_airpodsConnected) {
      return Colors.grey;
    }

    if (_ambientDecibels < 40) {
      return Colors.blue;
    } else if (_ambientDecibels < 55) {
      return Colors.cyan;
    } else if (_ambientDecibels < 65) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  bool get isAirpodsVolumeTooHigh => _airpodsConnected && _airpodsDecibels > 80;
  bool get isAmbientTooLoud => _ambientDecibels > 60;

  void dispose() {
    _updateTimer?.cancel();
  }
}
