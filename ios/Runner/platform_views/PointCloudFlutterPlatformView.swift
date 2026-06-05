import Flutter
import UIKit
import ARKit

/// A FlutterPlatformView that embeds the Metal point-cloud renderer.
///
/// Two modes:
///   "camera"      — shows a plain ARKit camera preview (no point cloud)
///   "pointcloud"  — shows the Metal point cloud renderer
///
/// Opens a per-instance MethodChannel for:
///   updatePointCloud(FlutterStandardTypedData) — push new point data
///   setTransform([String: Any])                — update view matrix
class PointCloudFlutterPlatformView: NSObject, FlutterPlatformView {
    private let metalView: PointCloudMetalView
    private let cameraPreviewView: CameraPreviewView?
    private let methodChannel: FlutterMethodChannel
    private let mode: String

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        sessionManager: ARSessionManager,
        mode: String
    ) {
        self.mode      = mode
        self.metalView = PointCloudMetalView(frame: frame)

        if mode == "camera" {
            self.cameraPreviewView = CameraPreviewView(
                frame: frame,
                sessionManager: sessionManager
            )
        } else {
            self.cameraPreviewView = nil
        }

        self.methodChannel = FlutterMethodChannel(
            name: "com.pointcloud.capture/metal_view_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        methodChannel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "updatePointCloud":
                if let typed = call.arguments as? FlutterStandardTypedData {
                    self.metalView.renderer.updatePointCloud(data: typed.data)
                }
                result(nil)

            case "setTransform":
                if let args = call.arguments as? [String: Any] {
                    self.metalView.renderer.setViewTransform(args)
                }
                result(nil)

            case "resetAccumulation":
                self.metalView.renderer.resetAccumulation()
                result(nil)

            case "setColorMode":
                if let mode = call.arguments as? Int {
                    self.metalView.renderer.setColorMode(Int32(mode))
                }
                result(nil)

            case "setPointSize":
                if let size = call.arguments as? Double {
                    self.metalView.renderer.setPointSize(Float(size))
                }
                result(nil)

            case "setBackground":
                if let dark = call.arguments as? Bool {
                    self.metalView.setBackground(dark: dark)
                }
                result(nil)

            case "snapshot":
                if let jpegData = self.metalView.snapshot() {
                    result(FlutterStandardTypedData(bytes: jpegData))
                } else {
                    result(nil)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func view() -> UIView {
        return mode == "camera" ? (cameraPreviewView ?? metalView) : metalView
    }
}

// MARK: - Camera preview (used in "camera" mode)

/// Renders the live AR camera feed via CIImage into a UIImageView at ≤15 Hz.
class CameraPreviewView: UIView {
    private let imageView = UIImageView()
    private let sessionManager: ARSessionManager
    private var listenerID: UUID?
    private var lastFrameTime: CFTimeInterval = 0

    init(frame: CGRect, sessionManager: ARSessionManager) {
        self.sessionManager = sessionManager
        super.init(frame: frame)
        backgroundColor = .black

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        listenerID = sessionManager.addFrameListener { [weak self] frame in
            self?.renderFrame(frame)
        }
    }

    deinit {
        if let id = listenerID { sessionManager.removeFrameListener(id) }
    }

    // ARKit delegates run on the main thread by default; no dispatch needed.
    private func renderFrame(_ frame: ARFrame) {
        let now = CACurrentMediaTime()
        guard now - lastFrameTime >= 1.0 / 15.0 else { return }
        lastFrameTime = now
        // ARKit capturedImage is landscape; .right rotates 90° clockwise → portrait.
        let ci = CIImage(cvPixelBuffer: frame.capturedImage).oriented(.right)
        imageView.image = UIImage(ciImage: ci)
    }

    required init?(coder: NSCoder) { fatalError() }
}
