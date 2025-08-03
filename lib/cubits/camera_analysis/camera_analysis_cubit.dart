import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/camera_service.dart';
import '../../services/ai_service.dart';
import 'dart:async'; // Added for Timer

// Events
abstract class CameraAnalysisEvent extends Equatable {
  const CameraAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class CameraImageCaptured extends CameraAnalysisEvent {
  final String imagePath;
  final DateTime timestamp;

  const CameraImageCaptured({
    required this.imagePath,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [imagePath, timestamp];
}

class AnalysisRequested extends CameraAnalysisEvent {
  const AnalysisRequested();
}

class AnimationVariablesUpdated extends CameraAnalysisEvent {
  final Map<String, double> variables;

  const AnimationVariablesUpdated({required this.variables});

  @override
  List<Object?> get props => [variables];
}

// States
abstract class CameraAnalysisState extends Equatable {
  const CameraAnalysisState();

  @override
  List<Object?> get props => [];
}

class CameraAnalysisInitial extends CameraAnalysisState {}

class CameraAnalysisLoading extends CameraAnalysisState {}

class CameraAnalysisSuccess extends CameraAnalysisState {
  final List<String> capturedImages;
  final AiAnalysisResult? lastAnalysis;
  final Map<String, double> animationVariables;
  final bool isProcessing;
  final bool personDetected;
  final DateTime? personDetectionStart;
  final double personProgress; // 0.0 to 1.0 over 60 minutes
  final int photosAnalyzed;
  final int totalPhotosCaptured;

  const CameraAnalysisSuccess({
    required this.capturedImages,
    this.lastAnalysis,
    required this.animationVariables,
    this.isProcessing = false,
    this.personDetected = false,
    this.personDetectionStart,
    this.personProgress = 0.0,
    this.photosAnalyzed = 0,
    this.totalPhotosCaptured = 0,
  });

  @override
  List<Object?> get props => [
        capturedImages,
        lastAnalysis,
        animationVariables,
        isProcessing,
        personDetected,
        personDetectionStart,
        personProgress,
        photosAnalyzed,
        totalPhotosCaptured,
      ];

  CameraAnalysisSuccess copyWith({
    List<String>? capturedImages,
    AiAnalysisResult? lastAnalysis,
    Map<String, double>? animationVariables,
    bool? isProcessing,
    bool? personDetected,
    DateTime? personDetectionStart,
    double? personProgress,
    int? photosAnalyzed,
    int? totalPhotosCaptured,
  }) {
    return CameraAnalysisSuccess(
      capturedImages: capturedImages ?? this.capturedImages,
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
      animationVariables: animationVariables ?? this.animationVariables,
      isProcessing: isProcessing ?? this.isProcessing,
      personDetected: personDetected ?? this.personDetected,
      personDetectionStart: personDetectionStart ?? this.personDetectionStart,
      personProgress: personProgress ?? this.personProgress,
      photosAnalyzed: photosAnalyzed ?? this.photosAnalyzed,
      totalPhotosCaptured: totalPhotosCaptured ?? this.totalPhotosCaptured,
    );
  }
}

class CameraAnalysisError extends CameraAnalysisState {
  final String message;

  const CameraAnalysisError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class CameraAnalysisCubit extends Cubit<CameraAnalysisState> {
  final CameraService _cameraService;
  Timer? _personProgressTimer;

  CameraAnalysisCubit({
    required CameraService cameraService,
  })  : _cameraService = cameraService,
        super(CameraAnalysisInitial()) {
    // Set up the callback to automatically process captured images
    _cameraService.setImageCaptureCallback(onImageCaptured);
  }

  void onImageCaptured(String imagePath) {
    final currentState = state;
    if (currentState is CameraAnalysisSuccess) {
      final updatedImages = List<String>.from(currentState.capturedImages)
        ..add(imagePath);

      // Keep only last 6 images
      if (updatedImages.length > 6) {
        updatedImages.removeAt(0);
      }

      emit(currentState.copyWith(
        capturedImages: updatedImages,
        totalPhotosCaptured: currentState.totalPhotosCaptured + 1,
      ));

      // Automatically analyze the new image
      _analyzeImage(imagePath);
    } else {
      emit(CameraAnalysisSuccess(
        capturedImages: [imagePath],
        animationVariables: _getDefaultAnimationVariables(),
        totalPhotosCaptured: 1,
      ));
      _analyzeImage(imagePath);
    }
  }

  void requestAnalysis() {
    final currentState = state;
    if (currentState is CameraAnalysisSuccess &&
        currentState.capturedImages.isNotEmpty) {
      _analyzeImage(currentState.capturedImages.last);
    }
  }

  void updateAnimationVariables(Map<String, double> variables) {
    final currentState = state;
    if (currentState is CameraAnalysisSuccess) {
      final updatedVariables =
          Map<String, double>.from(currentState.animationVariables);
      updatedVariables.addAll(variables);

      emit(currentState.copyWith(
        animationVariables: updatedVariables,
      ));
    }
  }

  void _startPersonProgressTimer() {
    _personProgressTimer?.cancel();
    _personProgressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = state;
      if (currentState is CameraAnalysisSuccess &&
          currentState.personDetected &&
          currentState.personDetectionStart != null) {
        final now = DateTime.now();
        final elapsed =
            now.difference(currentState.personDetectionStart!).inMinutes;
        final progress = (elapsed / 60.0).clamp(0.0, 1.0);

        emit(currentState.copyWith(personProgress: progress));

        // Stop timer when progress reaches 100%
        if (progress >= 1.0) {
          timer.cancel();
        }
      }
    });
  }

  void _stopPersonProgressTimer() {
    _personProgressTimer?.cancel();
  }

  Future<void> _analyzeImage(String imagePath) async {
    final currentState = state;
    if (currentState is! CameraAnalysisSuccess) return;

    emit(currentState.copyWith(isProcessing: true));

    try {
      final result = await AiService.analyzeImage(imagePath);

      // Check for person detection
      bool personDetected = false;
      for (final object in result.objects) {
        if (object.label.toLowerCase().contains('person') ||
            object.label.toLowerCase().contains('human')) {
          personDetected = true;
          break;
        }
      }

      // Handle person detection
      DateTime? personDetectionStart = currentState.personDetectionStart;
      double personProgress = currentState.personProgress;

      if (personDetected && !currentState.personDetected) {
        // Person just detected - start progress
        personDetectionStart = DateTime.now();
        personProgress = 0.0;
        _startPersonProgressTimer();
      } else if (!personDetected && currentState.personDetected) {
        // Person no longer detected - stop progress and reset
        _stopPersonProgressTimer();
        personDetectionStart = null;
        personProgress = 0.0;
      } else if (personDetected && currentState.personDetected) {
        // Person still detected - keep current progress
        personProgress = currentState.personProgress;
      } else {
        // No person detected - ensure progress is reset
        personProgress = 0.0;
      }

      // Update animation variables based on analysis
      final newVariables = _calculateAnimationVariables(result);

      emit(currentState.copyWith(
        lastAnalysis: result,
        animationVariables: newVariables,
        isProcessing: false,
        personDetected: personDetected,
        personDetectionStart: personDetectionStart,
        personProgress: personProgress,
        photosAnalyzed: currentState.photosAnalyzed + 1,
      ));
    } catch (e) {
      emit(CameraAnalysisError(message: e.toString()));
    }
  }

  Map<String, double> _getDefaultAnimationVariables() {
    return {
      'speed': 1.0,
      'intensity': 0.5,
      'complexity': 0.3,
      'brightness': 0.7,
      'contrast': 0.5,
      'waveFrequency': 1.0,
      'noiseLevel': 0.2,
      'patternDensity': 0.4,
    };
  }

  Map<String, double> _calculateAnimationVariables(AiAnalysisResult analysis) {
    final variables = _getDefaultAnimationVariables();

    // Adjust based on detected objects
    for (final object in analysis.objects) {
      final confidence = object.confidence / 100.0;
      final label = object.label.toLowerCase();

      if (label.contains('person')) {
        variables['speed'] = 0.8 + (confidence * 0.4);
        variables['intensity'] = 0.6 + (confidence * 0.3);
        variables['patternDensity'] = 0.5 + (confidence * 0.4);
      } else if (label.contains('car') || label.contains('vehicle')) {
        variables['speed'] = 1.2 + (confidence * 0.6);
        variables['waveFrequency'] = 1.5 + (confidence * 0.5);
        variables['noiseLevel'] = 0.3 + (confidence * 0.4);
      } else if (label.contains('building') || label.contains('house')) {
        variables['complexity'] = 0.7 + (confidence * 0.3);
        variables['contrast'] = 0.8 + (confidence * 0.2);
        variables['patternDensity'] = 0.8 + (confidence * 0.2);
      }
    }

    // Adjust based on overall confidence
    final overallConfidence = analysis.confidence / 100.0;
    variables['brightness'] = 0.5 + (overallConfidence * 0.5);
    variables['intensity'] =
        variables['intensity']! * (0.5 + overallConfidence * 0.5);

    // Ensure values stay within bounds
    for (final key in variables.keys) {
      variables[key] = variables[key]!.clamp(0.0, 1.0);
    }

    return variables;
  }

  @override
  Future<void> close() {
    _stopPersonProgressTimer();
    return super.close();
  }
}
