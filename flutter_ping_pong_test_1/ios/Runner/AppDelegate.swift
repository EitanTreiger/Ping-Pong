import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var lidarController = LidarController()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
        let lidarChannel = FlutterMethodChannel(name: "lidar_channel",
                                                binaryMessenger: controller.binaryMessenger)
        lidarChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            switch call.method {
            case "startLidar":
                let success = self.lidarController.startRecording()
                result(success)
            case "stopLidar":
                self.lidarController.stopRecording { url in
                    if let url = url {
                        result(url.path)
                    } else {
                        result(FlutterError(code: "LIDAR_ERROR",
                                            message: "Failed to stop recording or get video URL.",
                                            details: nil))
                    }
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
