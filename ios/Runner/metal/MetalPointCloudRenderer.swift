import MetalKit
import simd

/// MTKViewDelegate that renders a colored point cloud using Metal.
/// Points are accumulated across frames — call resetAccumulation() to clear.
class MetalPointCloudRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!
    private var depthState: MTLDepthStencilState!

    // CPU-side accumulation buffer.  Grows up to maxAccumulatedPoints × 6 floats.
    private var accumulatedFloats: [Float] = []
    private let maxAccumulatedPoints = 200_000

    private var vertexBuffer: MTLBuffer?
    private var pointCount: Int = 0
    private let bufferLock = NSLock()

    // View transform — updated by Flutter gestures
    private var rotationX: Float = 0
    private var rotationY: Float = 0
    private var zoom: Float = 1.0
    private var panX: Float = 0
    private var panY: Float = 0
    private var colorMode: Int32 = 0  // 0=camera RGB, 1=depth rainbow
    private var pointSize: Float = 4.0

    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        accumulatedFloats.reserveCapacity(maxAccumulatedPoints * 6)
        super.init()
        buildPipeline()
    }

    // MARK: - Setup

    private func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("No default Metal library — ensure Shaders.metal is in Compile Sources")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = library.makeFunction(name: "point_cloud_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "point_cloud_fragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat      = .depth32Float

        pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)

        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled  = true
        depthState = device.makeDepthStencilState(descriptor: depthDesc)!
    }

    // MARK: - Data updates (called from Flutter platform channel)

    func updatePointCloud(data: Data) {
        guard data.count >= 4 else { return }

        // FlutterStandardTypedData may provide a non-4-byte-aligned Data base
        // address. loadUnaligned reads Int32 safely regardless of alignment.
        let newCount = Int(data.withUnsafeBytes {
            $0.loadUnaligned(fromByteOffset: 0, as: Int32.self)
        })
        guard newCount > 0 else { return }

        let byteOffset = 4
        let floatCount = newCount * 6
        guard data.count - byteOffset == floatCount * 4 else { return }

        bufferLock.lock()
        defer { bufferLock.unlock() }

        let currentPoints = accumulatedFloats.count / 6
        let canAdd = min(newCount, maxAccumulatedPoints - currentPoints)
        guard canAdd > 0 else { return }

        let addFloatCount = canAdd * 6
        // Copy via memcpy into a freshly-allocated [Float] (guaranteed aligned),
        // then append — avoids bindMemory on a potentially unaligned pointer.
        var newFloats = [Float](repeating: 0, count: addFloatCount)
        newFloats.withUnsafeMutableBytes { dst in
            data.withUnsafeBytes { src in
                guard let s = src.baseAddress, let d = dst.baseAddress else { return }
                d.copyMemory(from: s.advanced(by: byteOffset), byteCount: addFloatCount * 4)
            }
        }
        accumulatedFloats.append(contentsOf: newFloats)

        pointCount = accumulatedFloats.count / 6
        vertexBuffer = device.makeBuffer(
            bytes: accumulatedFloats,
            length: accumulatedFloats.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
    }

    /// Clears all accumulated points.  Called when the user double-taps to reset.
    func resetAccumulation() {
        bufferLock.lock()
        accumulatedFloats.removeAll(keepingCapacity: true)
        vertexBuffer = nil
        pointCount   = 0
        bufferLock.unlock()
    }

    func setColorMode(_ mode: Int32) {
        colorMode = mode
    }

    func setPointSize(_ size: Float) {
        pointSize = min(max(size, 1.0), 20.0)
    }

    func setViewTransform(_ args: [String: Any]) {
        rotationX = (args["rotX"] as? Double).map { Float($0) } ?? rotationX
        rotationY = (args["rotY"] as? Double).map { Float($0) } ?? rotationY
        zoom      = (args["zoom"] as? Double).map { Float($0) } ?? zoom
        panX      = (args["panX"] as? Double).map { Float($0) } ?? panX
        panY      = (args["panY"] as? Double).map { Float($0) } ?? panY
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable       = view.currentDrawable,
              let renderPassDesc = view.currentRenderPassDescriptor,
              let commandBuffer  = commandQueue.makeCommandBuffer(),
              let encoder        = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc)
        else { return }

        bufferLock.lock()
        let vb    = vertexBuffer
        let count = pointCount
        bufferLock.unlock()

        if let vb, count > 0 {
            encoder.setRenderPipelineState(pipelineState)
            encoder.setDepthStencilState(depthState)
            var uniforms = buildUniforms(drawableSize: view.drawableSize)
            encoder.setVertexBuffer(vb, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: count)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - MVP construction

    private func buildUniforms(drawableSize: CGSize) -> Uniforms {
        let aspect = Float(drawableSize.width / max(drawableSize.height, 1))
        let proj   = simd_float4x4.perspective(fovYRadians: .pi / 3, aspect: aspect, near: 0.05, far: 100)
        // Points live at z ≈ –0.1 to –8 (camera space, ARKit –Z forward).
        // zoom > 1 (pinch-out gesture) → camera closer → apparent zoom-in.
        let eyeDist: Float = 4.0 / max(zoom, 0.05)
        let eye    = simd_float4x4.translation(0, 0, -eyeDist)
        let pan    = simd_float4x4.translation(panX, panY, 0)
        let rotX   = simd_float4x4.rotationX(rotationX)
        let rotY   = simd_float4x4.rotationY(rotationY)
        let mvp    = proj * eye * pan * rotY * rotX
        return Uniforms(mvp: mvp, pointSize: pointSize, colorMode: colorMode)
    }
}
