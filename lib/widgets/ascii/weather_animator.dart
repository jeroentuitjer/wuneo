import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../services/weather_service.dart';

class WeatherAnimator extends StatefulWidget {
  const WeatherAnimator({super.key});

  @override
  State<WeatherAnimator> createState() => _WeatherAnimatorState();
}

class _WeatherAnimatorState extends State<WeatherAnimator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _updateTimer;
  WeatherData? _currentWeather;
  String _weatherAscii = '';
  int _frameIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Optimized animation duration for smoother performance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize weather service if not already initialized
    _initializeWeatherService();

    // Reduced update frequency for better performance
    _updateTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      _updateWeatherDisplay();
    });

    // Initial weather update after a short delay to allow service to initialize
    Timer(const Duration(milliseconds: 500), () {
      _updateWeatherDisplay();
    });

    _animationController.repeat();
  }

  Future<void> _initializeWeatherService() async {
    if (!_isInitialized) {
      try {
        await WeatherService.initialize();
        setState(() {
          _isInitialized = true;
        });
      } catch (e) {
        print('Failed to initialize weather service: $e');
        setState(() {
          _isInitialized = true; // Mark as initialized even if failed
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer.cancel();
    super.dispose();
  }

  void _updateWeatherDisplay() {
    final weather = WeatherService.getCurrentWeather();
    if (weather != null) {
      setState(() {
        _currentWeather = weather;
        _weatherAscii = WeatherService.getWeatherAscii(weather.condition);
      });
    } else if (_isInitialized) {
      // If service is initialized but no weather data, trigger an update
      setState(() {
        _weatherAscii = '''
    \\  /     NO DATA
     \\/       
      /\\      
     /  \\     
    /    \\    
''';
      });
    }
  }

  String _getAnimatedWeatherAscii() {
    // Always show some weather ASCII, even if no data
    if (_currentWeather == null) {
      return '''
    \\  /     LOADING...
     \\/       
      /\\      
     /  \\     
    /    \\    
''';
    }

    final lines = _weatherAscii.split('\n');
    final animatedLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Simplified animation based on weather condition for better performance
      switch (_currentWeather!.condition) {
        case WeatherCondition.rainy:
        case WeatherCondition.stormy:
          // Simplified rain animation
          if (line.contains('|')) {
            final frame = _frameIndex % 3;
            line = line.replaceAll('|', frame == 0 ? '|' : ' ');
          }
          break;
        case WeatherCondition.snowy:
          // Simplified snow animation
          if (line.contains('*')) {
            final frame = _frameIndex % 4;
            line = line.replaceAll('*', frame == 0 ? '*' : ' ');
          }
          break;
        case WeatherCondition.foggy:
          // Simplified fog animation
          if (line.contains('█')) {
            final frame = _frameIndex % 3;
            line = line.replaceAll('█', frame == 0 ? '█' : '░');
          }
          break;
        case WeatherCondition.cloudy:
          // Simplified cloud animation
          if (line.contains('(') || line.contains(')')) {
            final frame = _frameIndex % 6;
            if (frame == 0) {
              line = line.replaceAll('(', '[').replaceAll(')', ']');
            } else if (frame == 3) {
              line = line.replaceAll('[', '(').replaceAll(']', ')');
            }
          }
          break;
        default:
          // No animation for clear weather
          break;
      }

      animatedLines.add(line);
    }

    return animatedLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Optimized frame calculation for smoother animation
        _frameIndex = (_animationController.value * 8).round();

        return Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[600]!,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEATHER STATION',
                  style: GoogleFonts.pressStart2p(
                    color: Colors.grey[400],
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Text(
                    _getAnimatedWeatherAscii(),
                    style: GoogleFonts.pressStart2p(
                      color: _getWeatherColor(),
                      fontSize: 8,
                      height: 1.0,
                    ),
                  ),
                ),
                if (_currentWeather != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'TEMP: ${_currentWeather!.temperature}°C | HUM: ${_currentWeather!.humidity}% | UPDATED: ${_formatTime(_currentWeather!.lastUpdated)}',
                    style: GoogleFonts.pressStart2p(
                      color: Colors.grey[500],
                      fontSize: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getWeatherColor() {
    if (_currentWeather == null) return Colors.grey[400]!;

    switch (_currentWeather!.condition) {
      case WeatherCondition.clear:
        return Colors.yellow;
      case WeatherCondition.cloudy:
        return Colors.grey[300]!;
      case WeatherCondition.rainy:
        return Colors.blue;
      case WeatherCondition.stormy:
        return Colors.purple;
      case WeatherCondition.snowy:
        return Colors.white;
      case WeatherCondition.foggy:
        return Colors.grey[400]!;
    }
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
