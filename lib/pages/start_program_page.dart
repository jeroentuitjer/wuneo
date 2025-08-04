import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/ascii/ascii_clock.dart';
import '../services/bluetooth_service.dart';
import '../services/weather_service.dart';
import '../services/decibel_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;

class StartProgramPage extends StatelessWidget {
  const StartProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with clock only
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ASCII Clock in top left
                const AsciiClock(),
                // Empty status area
                Container(
                  width: 100,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.grey[900]!.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Main content area - Terminal Log
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TerminalLog(),
                ),
              ),
            ),

            // Footer
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TerminalLog extends StatefulWidget {
  const TerminalLog({super.key});

  @override
  State<TerminalLog> createState() => _TerminalLogState();
}

class _TerminalLogState extends State<TerminalLog> {
  final List<String> _logMessages = [];
  Timer? _updateTimer;
  DateTime _startTime = DateTime.now();
  int _messageCounter = 0;
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isUserNearby = false;

  // Focus & Health tracking
  DateTime? _lastMovementTime;
  int _movementCount = 0;
  DateTime? _lastPostureAlert;
  bool _isInDeepWorkMode = false;

  // Phone pickup detection
  int? _lastIPhoneRSSI;
  DateTime? _lastIPhonePickup;
  bool _isPhonePickedUp = false;

  // Weather service
  final WeatherService _weatherService = WeatherService();

  // Volume monitoring
  bool _isVolumeTooHigh = false;
  DateTime? _lastVolumeAlert;

  // Decibel service
  final DecibelService _decibelService = DecibelService();

  @override
  void initState() {
    super.initState();
    _addInitialMessages();
    _startPeriodicUpdates();
    _initializeBluetooth();
    _initializeWeather();
    _initializeDecibelService();
  }

  void _addInitialMessages() {
    _addMessage('Session started');
    _addMessage('Time tracking active');
    _addMessage('Ready for work');
  }

  void _initializeBluetooth() {
    _bluetoothService.onProximityChanged = (isNearby) {
      setState(() {
        _isUserNearby = isNearby;
        if (isNearby) {
          _showJeroenDevices();
        } else {
          _addMessage('User left area');
        }
      });
    };
    _bluetoothService.initialize();
  }

  void _initializeWeather() {
    _weatherService.initialize().then((_) {
      // Add initial weather message
      _addMessage(_weatherService.getWeatherMessage());

      // Start weather updates (less frequent)
      Timer.periodic(const Duration(minutes: 10), (timer) {
        final weatherMessage = _weatherService.getWeatherMessage();
        _addMessage(weatherMessage);

        // Rain alert
        if (_weatherService.isRaining) {
          _addMessage('RAIN ALERT: Consider taking umbrella or staying inside');
        }
      });
    });
  }

  void _initializeDecibelService() {
    _decibelService.initialize();

    // Update UI every 10 seconds with new decibel reading
    Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        // This will trigger a rebuild to show updated decibel values
      });
    });
  }

  void _setAirpodsForDecibelService(blue.BluetoothDevice airpodsDevice) {
    _decibelService.setAirpodsDevice(airpodsDevice);
  }

  void _showJeroenDevices() {
    final nearbyDevices = _bluetoothService.nearbyDevices;
    final jeroenDevices = nearbyDevices
        .where((device) =>
            device.device.platformName.toLowerCase().contains('jeroen') ||
            device.device.platformName.toLowerCase().contains('iphone') ||
            device.device.platformName.toLowerCase().contains('airpods') ||
            device.device.platformName.toLowerCase().contains('macbook'))
        .toList();

    if (jeroenDevices.isNotEmpty) {
      _addMessage('Jeroen devices detected:');
      for (var device in jeroenDevices) {
        _addDeviceInfo(device);
      }
    } else {
      _addMessage('Device detected nearby');
    }
  }

  Future<void> _addDeviceInfo(blue.ScanResult device) async {
    final batteryLevel = await _getBatteryLevel(device.device);
    final connectionInfo = await _getConnectionInfo(device.device);
    final sensorInfo = await _getSensorInfo(device.device);

    // Add phone pickup status for iPhone
    String pickupStatus = '';
    if (device.device.platformName.toLowerCase().contains('iphone')) {
      pickupStatus =
          _isPhonePickedUp ? 'Status: In Hand' : 'Status: On Surface';
    }

    // Add volume status for AirPods and set up decibel monitoring
    String volumeStatus = '';
    if (device.device.platformName.toLowerCase().contains('airpods')) {
      volumeStatus = _isVolumeTooHigh ? 'Volume: HIGH' : 'Volume: OK';
      // Set AirPods device for decibel service
      _setAirpodsForDecibelService(device.device);
    }

    final deviceInfo = [
      device.device.platformName,
      'ID: ${device.device.remoteId}',
      'RSSI: ${device.rssi}',
      'Connected: ${device.device.isConnected}',
      'Battery: $batteryLevel',
      connectionInfo,
      sensorInfo,
      pickupStatus,
      volumeStatus,
    ].join(' | ');
    _addMessage('  - $deviceInfo');

    // Check for low battery warning
    if (batteryLevel != 'N/A') {
      final batteryPercent = int.tryParse(batteryLevel.replaceAll('%', ''));
      if (batteryPercent != null && batteryPercent <= 50) {
        _addMessage(
            '  LOW BATTERY: ${device.device.platformName} at $batteryLevel');
      }
    }
  }

  Future<String> _getConnectionInfo(blue.BluetoothDevice device) async {
    try {
      if (device.platformName.toLowerCase().contains('airpods')) {
        // Check if AirPods are connected to iPhone or MacBook
        final nearbyDevices = _bluetoothService.nearbyDevices;
        final airpodsDevice = nearbyDevices
            .where((d) => d.device.remoteId == device.remoteId)
            .firstOrNull;

        if (airpodsDevice != null) {
          final connectedToIPhone = nearbyDevices.any((d) =>
              d.device.platformName.toLowerCase().contains('iphone') &&
              d.rssi > -60 &&
              airpodsDevice.rssi > -60);
          final connectedToMacBook = nearbyDevices.any((d) =>
              d.device.platformName.toLowerCase().contains('macbook') &&
              d.rssi > -60 &&
              airpodsDevice.rssi > -60);

          if (connectedToIPhone && connectedToMacBook) {
            return 'Connected to iPhone & MacBook';
          } else if (connectedToIPhone) {
            return 'Connected to iPhone';
          } else if (connectedToMacBook) {
            return 'Connected to MacBook';
          } else {
            return 'Not connected';
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<String> _getBatteryLevel(blue.BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase().contains('battery')) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid
                .toString()
                .toLowerCase()
                .contains('battery')) {
              final value = await characteristic.read();
              if (value.isNotEmpty) {
                final batteryLevel = value.first;
                return '${batteryLevel}%';
              }
            }
          }
        }
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<String> _getSensorInfo(blue.BluetoothDevice device) async {
    try {
      if (device.platformName.toLowerCase().contains('airpods')) {
        final services = await device.discoverServices();
        for (var service in services) {
          // Look for sensor-related services
          if (service.uuid.toString().toLowerCase().contains('sensor') ||
              service.uuid.toString().toLowerCase().contains('motion') ||
              service.uuid.toString().toLowerCase().contains('accelerometer')) {
            for (var characteristic in service.characteristics) {
              if (characteristic.uuid
                      .toString()
                      .toLowerCase()
                      .contains('data') ||
                  characteristic.uuid
                      .toString()
                      .toLowerCase()
                      .contains('motion')) {
                try {
                  final value = await characteristic.read();
                  if (value.isNotEmpty) {
                    _processMovementData(value);
                    return 'Motion: Active';
                  }
                } catch (e) {
                  // Characteristic might not be readable
                }
              }
            }
          }

          // Look for audio/volume services
          if (service.uuid.toString().toLowerCase().contains('audio') ||
              service.uuid.toString().toLowerCase().contains('volume') ||
              service.uuid.toString().toLowerCase().contains('media')) {
            _checkVolumeLevel(device);
          }
        }
        return 'Motion: N/A';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  void _checkVolumeLevel(blue.BluetoothDevice device) {
    // Simulate volume detection based on device activity
    // In real implementation, this would read actual volume levels
    final now = DateTime.now();

    // Check if device is actively playing (simulated)
    if (device.isConnected) {
      // Simulate high volume detection
      if (!_isVolumeTooHigh && _lastVolumeAlert == null) {
        _isVolumeTooHigh = true;
        _lastVolumeAlert = now;
        _addMessage('VOLUME ALERT: AirPods volume may be too high');
      }
    }
  }

  void _checkAllDeviceVolumes() {
    final nearbyDevices = _bluetoothService.nearbyDevices;
    final airpodsDevices = nearbyDevices
        .where((device) =>
            device.device.platformName.toLowerCase().contains('airpods'))
        .toList();

    for (var device in airpodsDevices) {
      if (device.device.isConnected) {
        // Simulate volume monitoring
        final now = DateTime.now();
        if (_lastVolumeAlert == null ||
            now.difference(_lastVolumeAlert!).inMinutes > 5) {
          _addMessage(
              'VOLUME CHECK: AirPods connected - monitor volume levels');
          _lastVolumeAlert = now;
        }
      }
    }
  }

  void _processMovementData(List<int> data) {
    final now = DateTime.now();
    _lastMovementTime = now;
    _movementCount++;

    // Check for deep work mode (consistent small movements)
    if (_movementCount > 10 && _movementCount < 50) {
      if (!_isInDeepWorkMode) {
        _isInDeepWorkMode = true;
        _addMessage('DEEP WORK MODE: Focus detected');
      }
    } else if (_movementCount > 100) {
      // Too much movement = stress indicator
      _addMessage('STRESS DETECTED: High movement rate');
      _movementCount = 0;
    }

    // Check for posture (head down too long)
    if (_lastPostureAlert == null ||
        now.difference(_lastPostureAlert!).inMinutes > 5) {
      _addMessage('POSTURE ALERT: Check your head position');
      _lastPostureAlert = now;
    }
  }

  void _checkPhonePickup() {
    final nearbyDevices = _bluetoothService.nearbyDevices;
    final iPhoneDevice = nearbyDevices
        .where((device) =>
            device.device.platformName.toLowerCase().contains('iphone') &&
            device.rssi > -70)
        .firstOrNull;

    if (iPhoneDevice != null) {
      final currentRSSI = iPhoneDevice.rssi;
      final now = DateTime.now();

      // Detect phone pickup by RSSI change
      if (_lastIPhoneRSSI != null) {
        final rssiChange = currentRSSI - _lastIPhoneRSSI!;

        // If RSSI improved significantly (phone moved closer)
        if (rssiChange > 10 && !_isPhonePickedUp) {
          _isPhonePickedUp = true;
          _lastIPhonePickup = now;
          _addMessage('PHONE PICKUP: iPhone detected in hand');

          // Focus reminder if in deep work mode
          if (_isInDeepWorkMode) {
            _addMessage(
                'TAKE BACK FOCUS: Put phone down to maintain deep work');
          }
        }
        // If RSSI worsened significantly (phone put down)
        else if (rssiChange < -10 && _isPhonePickedUp) {
          _isPhonePickedUp = false;
          _addMessage('PHONE PUT DOWN: iPhone returned to surface');

          // Positive feedback if returning to focus
          if (_isInDeepWorkMode) {
            _addMessage('FOCUS RESTORED: Good choice, back to deep work');
          }
        }
      }

      _lastIPhoneRSSI = currentRSSI;
    }
  }

  void _startPeriodicUpdates() {
    // First minute: frequent updates
    Timer.periodic(const Duration(seconds: 10), (timer) {
      final duration = DateTime.now().difference(_startTime);

      if (duration.inMinutes >= 1) {
        // After first minute: limit to one message per 10 seconds
        if (_messageCounter % 6 == 0) {
          // Every 6th update (10s * 6 = 60s)
          _addRandomMessage();
        }
      } else {
        // First minute: normal updates
        _addRandomMessage();
      }
    });

    // Check phone pickup more frequently
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPhonePickup();
    });

    // Check volume levels periodically
    Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkAllDeviceVolumes();
    });
  }

  void _addMessage(String message) {
    setState(() {
      _logMessages.add('${_getTimestamp()} $message');
      if (_logMessages.length > 20) {
        _logMessages.removeAt(0);
      }
    });
  }

  void _addRandomMessage() {
    final duration = DateTime.now().difference(_startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    String message;

    // Check for standup reminder at 08:55
    if (currentHour == 8 && currentMinute == 55) {
      message = 'STANDUP REMINDER: Daily standup starts in 5 minutes at 9:00';
      _addMessage(message);
      return;
    }

    if (_isUserNearby) {
      // Check if iPhone is specifically detected
      final nearbyDevices = _bluetoothService.nearbyDevices;
      final iPhoneDevice = nearbyDevices
          .where((device) =>
              device.device.platformName.toLowerCase().contains('iphone') &&
              device.rssi > -70)
          .firstOrNull;

      // Check for break reminders and health alerts
      if (minutes >= 50 && minutes % 10 == 0) {
        message = 'BREAK REMINDER: Take a 5-minute break';
      } else if (hours >= 1 && minutes % 15 == 0) {
        message = 'ERGONOMICS: Stand up and stretch';
      } else if (_isInDeepWorkMode) {
        message = 'DEEP WORK: ${minutes} minutes focused';
        if (iPhoneDevice != null) {
          message +=
              ' - ${iPhoneDevice.device.platformName} (${iPhoneDevice.device.remoteId})';
        }
      } else {
        if (hours >= 1) {
          message = '${hours}h ${minutes}m in progress';
          if (iPhoneDevice != null) {
            message +=
                ' - ${iPhoneDevice.device.platformName} (${iPhoneDevice.device.remoteId})';
          }
        } else if (minutes >= 30) {
          message = '${minutes} minutes in progress';
          if (iPhoneDevice != null) {
            message +=
                ' - ${iPhoneDevice.device.platformName} (${iPhoneDevice.device.remoteId})';
          }
        } else {
          message = '${minutes} minutes in progress';
          if (iPhoneDevice != null) {
            message +=
                ' - ${iPhoneDevice.device.platformName} (${iPhoneDevice.device.remoteId})';
          }
        }
      }
    } else {
      message = 'Session paused - No devices nearby';
    }

    _addMessage(message);
    _messageCounter++;
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}]';
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _bluetoothService.dispose();
    _weatherService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TERMINAL LOG',
              style: TextStyle(
                color: Colors.green[400],
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _logMessages.length,
                  itemBuilder: (context, index) {
                    final message = _logMessages[index];
                    Color textColor = Colors.green[400]!;

                    // Check if message is a standup reminder
                    if (message.contains('STANDUP REMINDER')) {
                      textColor = Colors.blue[400]!;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        // Decibel meters in bottom right corner
        Positioned(
          bottom: 5,
          right: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // AirPods decibel meter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Text(
                  _decibelService.getAirpodsDecibelStatus(),
                  style: TextStyle(
                    color: _decibelService.getAirpodsDecibelColor(),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // AirPods device info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Text(
                  _decibelService.getAirpodsDeviceInfo(),
                  style: TextStyle(
                    color: Colors.cyan[400],
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Ambient decibel meter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Text(
                  _decibelService.getAmbientDecibelStatus(),
                  style: TextStyle(
                    color: _decibelService.getAmbientDecibelColor(),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
