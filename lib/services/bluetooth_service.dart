import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  bool _isInitialized = false;
  bool _isNearby = false;
  Timer? _scanTimer;
  List<ScanResult> _nearbyDevices = [];

  // Callback for when proximity status changes
  Function(bool isNearby)? onProximityChanged;

  bool get isNearby => _isNearby;
  List<ScanResult> get nearbyDevices => _nearbyDevices;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Initializing Bluetooth service...');

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        print('Bluetooth not supported');
        return;
      }
      print('Bluetooth is supported');

      // Check Bluetooth adapter state
      final adapterState = await FlutterBluePlus.adapterState.first;
      print('Bluetooth adapter state: $adapterState');

      if (adapterState == BluetoothAdapterState.on) {
        print('Bluetooth is ON - starting scan');
        _isInitialized = true;
        _startScanning();
      } else if (adapterState == BluetoothAdapterState.unknown) {
        print('Bluetooth permission needed - requesting access...');
        // Try to request Bluetooth permission
        try {
          await FlutterBluePlus.turnOn();
          print('Bluetooth turned on successfully');
          _isInitialized = true;
          _startScanning();
        } catch (e) {
          print('Failed to turn on Bluetooth: $e');
        }
      } else {
        print('Bluetooth adapter state: $adapterState');
      }
    } catch (e) {
      print('Bluetooth initialization error: $e');
    }
  }

  void _startScanning() {
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _scanForDevices();
    });
  }

  Future<void> _scanForDevices() async {
    try {
      print('Starting Bluetooth scan...');
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      FlutterBluePlus.scanResults.listen((results) {
        print('Scan results: ${results.length} devices found');
        _nearbyDevices = results;
        _updateProximityStatus();
      });
    } catch (e) {
      print('Bluetooth scan error: $e');
    }
  }

  void _updateProximityStatus() {
    // Check if any device is nearby (RSSI > -70 indicates close proximity)
    bool wasNearby = _isNearby;
    _isNearby = _nearbyDevices.any(
        (result) => result.rssi > -70 && result.device.platformName.isNotEmpty);

    // Notify if status changed
    if (wasNearby != _isNearby && onProximityChanged != null) {
      onProximityChanged!(_isNearby);
    }

    // Log detected devices for debugging
    if (_nearbyDevices.isNotEmpty) {
      print('Nearby devices:');
      for (var device in _nearbyDevices) {
        if (device.rssi > -70) {
          print('  - ${device.device.platformName} (RSSI: ${device.rssi})');
          _checkBatteryLevel(device.device);
        }
      }
    }
  }

  Future<void> _checkBatteryLevel(BluetoothDevice device) async {
    try {
      // Try to read battery level from device
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
                print('    Battery: $batteryLevel%');
              }
            }
          }
        }
      }
    } catch (e) {
      // Battery info not available for this device
    }
  }

  void dispose() {
    _scanTimer?.cancel();
    FlutterBluePlus.stopScan();
  }

  String getStatusMessage() {
    if (!_isInitialized) return 'Bluetooth: Not available';
    if (_isNearby) return 'Bluetooth: Device nearby';
    return 'Bluetooth: No devices nearby';
  }
}
