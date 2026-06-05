import CoreImage
import MetalKit

/// A MetalKit view pre-configured for point cloud rendering.
class PointCloudMetalView: MTKView {
    let renderer: MetalPointCloudRenderer

    init(frame: CGRect) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        renderer = MetalPointCloudRenderer(device: device)
        super.init(frame: frame, device: device)
        configure()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func configure() {
        delegate                    = renderer
        colorPixelFormat            = .bgra8Unorm
        depthStencilPixelFormat     = .depth32Float
        clearColor                  = MTLClearColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1)
        preferredFramesPerSecond    = 60
        enableSetNeedsDisplay       = false
        isPaused                    = false
        autoResizeDrawable          = true
        framebufferOnly             = false
    }

    func setBackground(dark: Bool) {
        if dark {
            clearColor = MTLClearColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1)
        } else {
            clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }

    /// Renders the current frame into an off-screen texture and returns JPEG data.
    func snapshot() -> Data? {
        guard let texture = currentDrawable?.texture,
              !framebufferOnly else { return nil }
        let ciImage = CIImage(mtlTexture: texture, options: nil)
        guard let ci = ciImage else { return nil }
        let context = CIContext()
        let rect = CGRect(x: 0, y: 0,
                          width: CGFloat(texture.width),
                          height: CGFloat(texture.height))
        guard let cgImage = context.createCGImage(ci, from: rect) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
    }
}
