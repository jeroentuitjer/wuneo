import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/ascii/ascii_clock.dart';
import '../widgets/ascii/airpods_radar.dart';
import '../services/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;

class StartProgramPage extends StatefulWidget {
  const StartProgramPage({super.key});

  @override
  State<StartProgramPage> createState() => _StartProgramPageState();
}

class _StartProgramPageState extends State<StartProgramPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<blue.ScanResult> _airpodsDevices = [];

  @override
  void initState() {
    super.initState();
    _initializeAirpodsRadar();
  }

  void _initializeAirpodsRadar() {
    _bluetoothService.initialize();

    // Update AirPods radar every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateAirpodsRadar();
    });
  }

  void _updateAirpodsRadar() {
    final nearbyDevices = _bluetoothService.nearbyDevices;
    final airpodsDevices = nearbyDevices
        .where((device) =>
            device.device.platformName.toLowerCase().contains('airpods'))
        .toList();

    setState(() {
      _airpodsDevices = airpodsDevices;
    });
  }

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
                // Empty space instead of status box
                const SizedBox(width: 100),
              ],
            ),
            const SizedBox(height: 10),

            // Main content area - Full screen AirPods Radar
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: AirpodsRadar(airpodsDevices: _airpodsDevices),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
