import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static Timer? _updateTimer;
  static WeatherData? _currentWeather;
  static Position? _currentPosition;

  // Weather scraping configuration
  static const String _weatherUrl = 'https://wttr.in/';

  static Future<void> initialize() async {
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      print('Weather Service initialization already in progress...');
      return;
    }

    if (_isInitialized) {
      print('Weather Service already initialized');
      return;
    }

    _isInitializing = true;

    try {
      print('Weather Service initializing with web scraping...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled, using simulated weather');
        _initializeSimulatedMode();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied, using simulated weather');
          _initializeSimulatedMode();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            'Location permission permanently denied, using simulated weather');
        _initializeSimulatedMode();
        return;
      }

      // Get current location with better error handling
      try {
        print('Getting current location...');
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        print(
            'Location obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

        // Verify the location is reasonable (not 0,0 or simulator default)
        if (_currentPosition!.latitude == 0.0 &&
            _currentPosition!.longitude == 0.0) {
          print('Invalid location detected (0,0), using simulated weather');
          _initializeSimulatedMode();
          return;
        }
      } catch (e) {
        print('Failed to get location: $e, using simulated weather');
        _initializeSimulatedMode();
        return;
      }

      _isInitialized = true;
      print('Weather Service initialized with web scraping');

      // Update weather every 5 minutes
      _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _updateWeather();
      });

      // Initial weather update
      await _updateWeather();
    } catch (e) {
      print(
          'Failed to initialize Weather Service: $e, falling back to simulated mode');
      _initializeSimulatedMode();
    } finally {
      _isInitializing = false;
    }
  }

  static void _initializeSimulatedMode() {
    _isInitialized = true;
    print('Weather Service initialized in simulated mode');

    // Update weather every 2 minutes for more frequent changes
    _updateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updateSimulatedWeather();
    });

    // Initial weather update
    _updateSimulatedWeather();
  }

  static Future<void> _updateWeather() async {
    if (_currentPosition == null) {
      _updateSimulatedWeather();
      return;
    }

    try {
      // Use wttr.in service which provides weather data without API key
      final url = Uri.parse(
          '$_weatherUrl${_currentPosition!.latitude},${_currentPosition!.longitude}?format=j1');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];

        final tempC = double.parse(current['temp_C']);
        final weatherDesc = current['weatherDesc'][0]['value'].toLowerCase();
        final humidity = int.parse(current['humidity']);

        _currentWeather = WeatherData(
          condition: _mapWeatherCondition(weatherDesc),
          temperature: tempC.round(),
          humidity: humidity,
          lastUpdated: DateTime.now(),
        );

        print(
            'Real weather updated: ${_currentWeather!.condition.name} at ${_currentWeather!.temperature}°C');
      } else {
        print(
            'Weather scraping error: ${response.statusCode}, using simulated data');
        _updateSimulatedWeather();
      }
    } catch (e) {
      print('Weather scraping failed: $e, using simulated data');
      _updateSimulatedWeather();
    }
  }

  static void _updateSimulatedWeather() {
    // Simulate different weather conditions
    final conditions = [
      WeatherCondition.clear,
      WeatherCondition.cloudy,
      WeatherCondition.rainy,
      WeatherCondition.stormy,
      WeatherCondition.snowy,
      WeatherCondition.foggy,
    ];

    final random = Random();
    final condition = conditions[random.nextInt(conditions.length)];
    final temperature = 10 + random.nextInt(20); // 10-30°C

    _currentWeather = WeatherData(
      condition: condition,
      temperature: temperature,
      humidity: 40 + random.nextInt(40), // 40-80%
      lastUpdated: DateTime.now(),
    );

    print('Simulated weather updated: ${condition.name} at $temperature°C');
  }

  static WeatherCondition _mapWeatherCondition(String weatherDesc) {
    final desc = weatherDesc.toLowerCase();

    if (desc.contains('clear') || desc.contains('sunny')) {
      return WeatherCondition.clear;
    } else if (desc.contains('cloud') || desc.contains('overcast')) {
      return WeatherCondition.cloudy;
    } else if (desc.contains('rain') ||
        desc.contains('drizzle') ||
        desc.contains('shower')) {
      return WeatherCondition.rainy;
    } else if (desc.contains('storm') || desc.contains('thunder')) {
      return WeatherCondition.stormy;
    } else if (desc.contains('snow') || desc.contains('sleet')) {
      return WeatherCondition.snowy;
    } else if (desc.contains('fog') ||
        desc.contains('mist') ||
        desc.contains('haze')) {
      return WeatherCondition.foggy;
    } else {
      return WeatherCondition.clear;
    }
  }

  static WeatherData? getCurrentWeather() {
    if (!_isInitialized) {
      print('Weather Service not initialized. Call initialize() first.');
      return null;
    }

    // If no weather data exists, create initial data
    if (_currentWeather == null) {
      _updateSimulatedWeather();
    }

    return _currentWeather;
  }

  static String getWeatherAscii(WeatherCondition condition) {
    if (!_isInitialized) {
      print('Weather Service not initialized. Call initialize() first.');
      return 'Service not initialized';
    }
    switch (condition) {
      case WeatherCondition.clear:
        return '''
    \\  /     CLEAR SKY
     \\/       
      /\\      
     /  \\     
    /    \\    
''';
      case WeatherCondition.cloudy:
        return '''
   ___   ___   CLOUDY
  (   ) (   )   
   ---   ---   
''';
      case WeatherCondition.rainy:
        return '''
   ___   ___   RAINY
  (   ) (   )   
   ---   ---   
    |   |   |   
    |   |   |   
''';
      case WeatherCondition.stormy:
        return '''
   ___   ___   STORMY
  (   ) (   )   
   ---   ---   
    |   |   |   
    |   |   |   
  ⚡ ⚡ ⚡ ⚡ ⚡
''';
      case WeatherCondition.snowy:
        return '''
   ___   ___   SNOWY
  (   ) (   )   
   ---   ---   
    *   *   *   
    *   *   *   
''';
      case WeatherCondition.foggy:
        return '''
   ___   ___   FOGGY
  (   ) (   )   
   ---   ---   
  ███ ███ ███   
  ███ ███ ███   
''';
    }
  }

  static void dispose() {
    _updateTimer?.cancel();
    _isInitialized = false;
  }
}

enum WeatherCondition {
  clear,
  cloudy,
  rainy,
  stormy,
  snowy,
  foggy,
}

class WeatherData {
  final WeatherCondition condition;
  final int temperature;
  final int humidity;
  final DateTime lastUpdated;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.lastUpdated,
  });
}
