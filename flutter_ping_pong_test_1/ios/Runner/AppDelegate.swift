import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var cbridgeinterface = CBridgeInterface()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
      if let controller = window?.rootViewController as? FlutterViewController {
          let CChannel = FlutterMethodChannel(name: "ccode_channel",
                                                  binaryMessenger: controller.binaryMessenger)
          CChannel.setMethodCallHandler({
              [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
              guard let self = self else { return }
              switch call.method {
                case "addNumbers":
                  if let args = call.arguments as? [String: Any],
                     let a_arg = args["a"] as? Int,
                     let b_arg = args["b"] as? Int {
                      let success = self.cbridgeinterface.calcPlus(a: a_arg, b: b_arg);
                      result(success)
                  } else {
                      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments not valid", details: nil))
                  }
                default:
                    result(FlutterMethodNotImplemented)
              }
          })
      }
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
