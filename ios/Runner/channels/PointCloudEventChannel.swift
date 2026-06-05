import Flutter
import ARKit

/// Streams point cloud frames over `com.pointcloud.capture/point_cloud_stream`.
///
/// Throttles to 15 Hz and uses a semaphore to drop frames if processing
/// of the previous frame is still in progress — prevents queue build-up.
class PointCloudEventChannel: NSObject, FlutterStreamHandler {
    private let sessionManager: ARSessionManager
    private var eventSink: FlutterEventSink?
    private let processingQueue = DispatchQueue(
        label: "com.pointcloud.processing",
        qos: .userInitiated
    )
    private let semaphore = DispatchSemaphore(value: 1)
    private var lastFrameTime: CFTimeInterval = 0
    private let targetInterval: CFTimeInterval = 1.0 / 15.0  // 15 Hz
    private var listenerID: UUID?

    init(messenger: FlutterBinaryMessenger, sessionManager: ARSessionManager) {
        self.sessionManager = sessionManager
        super.init()
        let channel = FlutterEventChannel(
            name: "com.pointcloud.capture/point_cloud_stream",
            binaryMessenger: messenger
        )
        channel.setStreamHandler(self)
    }

    // MARK: - FlutterStreamHandler

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        listenerID = sessionManager.addFrameListener { [weak self] frame in
            self?.handleFrame(frame)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        if let id = listenerID {
            sessionManager.removeFrameListener(id)
            listenerID = nil
        }
        return nil
    }

    // MARK: - Frame processing

    private func handleFrame(_ frame: ARFrame) {
        let now = CACurrentMediaTime()
        guard now - lastFrameTime >= targetInterval else { return }
        lastFrameTime = now

        // If the previous frame is still being processed, skip this one
        guard semaphore.wait(timeout: .now()) == .success else { return }

        processingQueue.async { [weak self] in
            guard let self else { return }
            defer { self.semaphore.signal() }

            guard let depth = frame.smoothedSceneDepth ?? frame.sceneDepth else {
                return
            }

            let data = DepthProcessor.processToData(
                depthMap: depth.depthMap,
                confidenceMap: depth.confidenceMap,
                cameraImage: frame.capturedImage,
                cameraIntrinsics: frame.camera.intrinsics,
                imageResolution: frame.camera.imageResolution
            )

            guard data.count > 4 else { return }  // at least one point

            DispatchQueue.main.async { [weak self] in
                self?.eventSink?(FlutterStandardTypedData(bytes: data))
            }
        }
    }
}
