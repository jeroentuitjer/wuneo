# WUNEO

A Flutter app with weather, AI, and camera services.

## Features

- **Real Weather Data**: Get actual weather information for your current location
- **AI Vision Analysis**: Local image analysis using TensorFlow Lite
- **ASCII Art Animations**: Retro-style visualizations
- **Camera Integration**: Automatic photo capture and analysis
- **State Management**: Bloc/Cubit architecture

## Setup for Real Weather Data

To get real weather data instead of simulated data:

1. **Get a free API key from OpenWeatherMap:**
   - Go to [OpenWeatherMap](https://openweathermap.org/api)
   - Sign up for a free account
   - Get your API key

2. **Update the API key in the code:**
   - Open `lib/services/weather_service.dart`
   - Replace `YOUR_API_KEY_HERE` on line 15 with your actual API key:
   ```dart
   static const String _apiKey = 'your_actual_api_key_here';
   ```

3. **Location Permissions:**
   - The app will request location permission when it starts
   - Grant permission to get weather for your current location
   - If denied, the app will fall back to simulated weather

## Running the App

```bash
flutter pub get
flutter run
```

## Architecture

- **Services**: AI, Weather, Camera, Logger
- **State Management**: Cubit pattern with flutter_bloc
- **Widgets**: ASCII art animations and retro UI
- **Platforms**: iOS and Android support

## Weather Service

The weather service automatically:
- Requests location permission
- Gets your current coordinates
- Fetches real weather data from OpenWeatherMap API
- Falls back to simulated data if API is unavailable
- Updates every 5 minutes with real data
- Updates every 2 minutes with simulated data
