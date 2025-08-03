import 'dart:async';
import 'dart:math';

class WeatherService {
  static bool _isInitialized = false;
  static Timer? _updateTimer;
  static WeatherData? _currentWeather;

  static Future<void> initialize() async {
    try {
      // For now, we'll use simulated weather data
      // In the future, we can add real weather API integration
      print('Weather Service initialized in simulated mode');
      _isInitialized = true;

      // Update weather every 5 minutes
      _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _updateWeather();
      });

      // Initial weather update
      _updateWeather();
    } catch (e) {
      print('Failed to initialize Weather Service: $e');
      _isInitialized = false;
    }
  }

  static void _updateWeather() {
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

    print('Weather updated: ${condition.name} at $temperature°C');
  }

  static WeatherData? getCurrentWeather() {
    if (!_isInitialized) {
      print('Weather Service not initialized. Call initialize() first.');
      return null;
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
     \\/       ☀️
      /\\      
     /  \\     
    /    \\    
''';
      case WeatherCondition.cloudy:
        return '''
   ___   ___   CLOUDY
  (   ) (   )   ☁️
   ---   ---   
''';
      case WeatherCondition.rainy:
        return '''
   ___   ___   RAINY
  (   ) (   )   🌧️
   ---   ---   
    |   |   |   
    |   |   |   
''';
      case WeatherCondition.stormy:
        return '''
   ___   ___   STORMY
  (   ) (   )   ⚡
   ---   ---   
    |   |   |   
    |   |   |   
  ⚡ ⚡ ⚡ ⚡ ⚡
''';
      case WeatherCondition.snowy:
        return '''
   ___   ___   SNOWY
  (   ) (   )   ❄️
   ---   ---   
    *   *   *   
    *   *   *   
''';
      case WeatherCondition.foggy:
        return '''
   ___   ___   FOGGY
  (   ) (   )   🌫️
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
