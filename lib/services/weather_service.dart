import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  String _currentWeather = 'Unknown';
  String _currentTemperature = 'Unknown';
  bool _isRaining = false;
  Timer? _updateTimer;
  Position? _currentPosition;

  String get currentWeather => _currentWeather;
  String get currentTemperature => _currentTemperature;
  bool get isRaining => _isRaining;

  Future<void> initialize() async {
    try {
      print('Weather Service: Initializing...');
      
      // Get current location
      await _getCurrentLocation();
      
      // Start periodic updates
      _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _updateWeather();
      });
      
      // Initial weather update
      await _updateWeather();
      
    } catch (e) {
      print('Weather Service: Initialization error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Weather Service: Location permission denied');
          return;
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('Weather Service: Location obtained - ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
    } catch (e) {
      print('Weather Service: Location error: $e');
    }
  }

  Future<void> _updateWeather() async {
    if (_currentPosition == null) {
      print('Weather Service: No location available');
      return;
    }

    try {
      print('Weather Service: Fetching weather data...');
      
      // Buienradar API endpoint for current location
      final lat = _currentPosition!.latitude;
      final lon = _currentPosition!.longitude;
      final url = 'https://data.buienradar.nl/2.0/feed/json';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Weather request timeout');
        },
      );

      if (response.statusCode == 200) {
        await _parseWeatherData(response.body, lat, lon);
      } else {
        print('Weather Service: HTTP error ${response.statusCode}');
      }
      
    } catch (e) {
      print('Weather Service: Weather update error: $e');
    }
  }

  Future<void> _parseWeatherData(String jsonData, double lat, double lon) async {
    try {
      // Find the nearest weather station to current location
      final data = jsonData;
      
      // Simple parsing for rain detection
      if (data.toLowerCase().contains('regen') || 
          data.toLowerCase().contains('rain') ||
          data.toLowerCase().contains('drizzle') ||
          data.toLowerCase().contains('shower')) {
        _isRaining = true;
        _currentWeather = 'Rainy';
      } else if (data.toLowerCase().contains('zonnig') ||
                 data.toLowerCase().contains('sunny') ||
                 data.toLowerCase().contains('clear')) {
        _isRaining = false;
        _currentWeather = 'Sunny';
      } else {
        _isRaining = false;
        _currentWeather = 'Cloudy';
      }

      // Extract temperature (simplified)
      final tempMatch = RegExp(r'"temperature":\s*([0-9.-]+)').firstMatch(data);
      if (tempMatch != null) {
        _currentTemperature = '${tempMatch.group(1)}°C';
      } else {
        _currentTemperature = 'Unknown';
      }

      print('Weather Service: Weather updated - $_currentWeather, $_currentTemperature, Raining: $_isRaining');
      
    } catch (e) {
      print('Weather Service: Parse error: $e');
    }
  }

  String getWeatherMessage() {
    if (_isRaining) {
      return 'WEATHER: Rain detected - $_currentTemperature';
    } else {
      return 'WEATHER: $_currentWeather - $_currentTemperature';
    }
  }

  void dispose() {
    _updateTimer?.cancel();
  }
} 