import Flutter
import UIKit
import Vision
import CoreML

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for AI service
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "ai_service", binaryMessenger: controller.binaryMessenger)
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call, result: result)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initializeVision":
      initializeVision(result: result)
    case "analyzeImage":
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      analyzeImage(imagePath: imagePath, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func initializeVision(result: @escaping FlutterResult) {
    // Check if Vision framework is available
    if #available(iOS 11.0, *) {
      result(true)
    } else {
      result(FlutterError(code: "VISION_NOT_AVAILABLE", message: "Vision framework requires iOS 11+", details: nil))
    }
  }
  
  private func analyzeImage(imagePath: String, result: @escaping FlutterResult) {
    // Temporary fallback for testing on real device
    let mockObjects: [[String: Any]] = [
      [
        "label": "Person",
        "confidence": 0.95,
        "boundingBox": [0.1, 0.1, 0.8, 0.8]
      ],
      [
        "label": "Object",
        "confidence": 0.87,
        "boundingBox": [0.2, 0.2, 0.6, 0.6]
      ]
    ]
    
    let response: [String: Any] = [
      "objects": mockObjects,
      "confidence": 0.91
    ]
    
    result(response)
  }
}
