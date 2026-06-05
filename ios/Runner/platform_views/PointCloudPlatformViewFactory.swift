import Flutter
import UIKit

/// Registers the Metal point-cloud view with Flutter's platform view registry.
class PointCloudPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let sessionManager: ARSessionManager

    init(messenger: FlutterBinaryMessenger, sessionManager: ARSessionManager) {
        self.messenger      = messenger
        self.sessionManager = sessionManager
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let mode = (args as? [String: Any])?["mode"] as? String ?? "pointcloud"
        return PointCloudFlutterPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            sessionManager: sessionManager,
            mode: mode
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
