import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var arSessionChannel: ARSessionChannel?
    private var pointCloudEventChannel: PointCloudEventChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Called by Flutter once the engine is ready — safe place to register channels
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PointCloudPlugin") else {
            return
        }
        let messenger = registrar.messenger()

        // 1. AR session MethodChannel
        arSessionChannel = ARSessionChannel(messenger: messenger)

        guard let channel = arSessionChannel else { return }

        // 2. Point cloud EventChannel
        pointCloudEventChannel = PointCloudEventChannel(
            messenger: messenger,
            sessionManager: channel.sessionManager
        )

        // 3. Metal PlatformView factory
        registrar.register(
            PointCloudPlatformViewFactory(
                messenger: messenger,
                sessionManager: channel.sessionManager
            ),
            withId: "com.pointcloud.capture/metal_view"
        )
    }
}
