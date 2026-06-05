import Flutter
import ARKit

/// Handles the `com.pointcloud.capture/ar_session` MethodChannel.
/// Supports: checkLiDARAvailability, startARSession, stopARSession, captureFrame, setFlash.
class ARSessionChannel: NSObject {
    let sessionManager: ARSessionManager

    init(messenger: FlutterBinaryMessenger) {
        self.sessionManager = ARSessionManager()
        super.init()

        let channel = FlutterMethodChannel(
            name: "com.pointcloud.capture/ar_session",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler(handleCall)
    }

    private func handleCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "checkLiDARAvailability":
            // True if the device supports sceneReconstruction (== has LiDAR)
            let available = ARWorldTrackingConfiguration
                .supportsSceneReconstruction(.mesh)
            result(available)

        case "startARSession":
            sessionManager.startSession { error in
                if let e = error {
                    result(FlutterError(code: "AR_START", message: e, details: nil))
                } else {
                    result(nil)
                }
            }

        case "stopARSession":
            sessionManager.stopSession()
            result(nil)

        case "captureFrame":
            sessionManager.captureCurrentFrame { data, error in
                if let e = error {
                    result(FlutterError(code: "CAPTURE", message: e, details: nil))
                } else {
                    result(data)
                }
            }

        case "setFlash":
            guard let args = call.arguments as? [String: Any],
                  let on = args["on"] as? Bool else {
                result(FlutterError(code: "ARGS", message: "Missing 'on' argument", details: nil))
                return
            }
            sessionManager.setTorch(on: on)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
