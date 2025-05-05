//
//  MetalRenderer.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/23/25.
//

import MetalKit

class MetalRenderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var texture: MTLTexture?
    private var vertices: MTLBuffer?
    private var texCoords: MTLBuffer?
    private var pixelFormat: retro_pixel_format = RETRO_PIXEL_FORMAT_0RGB1555

    init() {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        self.commandQueue = commandQueue
        setupBuffers()
    }

    func setupTexture(width: Int, height: Int, format: MTLPixelFormat) {
        guard width > 0, height > 0, format != .invalid else {
            print(
                "Coordinator: Invalid dimensions/format for texture setup (\(width)x\(height), \(format))."
            )
            texture = nil  // Invalidate texture
            return
        }

        // Check if texture already exists with the same properties.
        if let existingTexture = texture,
            existingTexture.width == width,
            existingTexture.height == height,
            existingTexture.pixelFormat == format
        {
            // Texture is suitable, no need to recreate.
            return
        }

        print(
            "Coordinator: Creating texture \(width)x\(height), format: \(format)"
        )
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead]

        guard
            let newTexture = device.makeTexture(
                descriptor: textureDescriptor
            )
        else {
            print("Error: Failed to create texture.")
            texture = nil
            return
        }
        texture = newTexture
    }

    // Setup vertex/texCoord buffers and pipeline state
    func setupBuffers() {
        // Simple Quad Vertices (covers -1 to 1 in normalized device coords)
        let vertexData: [Float] = [
            // Triangle 1
            -1.0, -1.0, 0.0, 1.0,  // Bottom Left
            1.0, -1.0, 0.0, 1.0,  // Bottom Right
            -1.0, 1.0, 0.0, 1.0,  // Top Left
            // Triangle 2
            1.0, -1.0, 0.0, 1.0,  // Bottom Right
            1.0, 1.0, 0.0, 1.0,  // Top Right
            -1.0, 1.0, 0.0, 1.0,  // Top Left
        ]
        vertices = device.makeBuffer(
            bytes: vertexData,
            length: vertexData.count * MemoryLayout<Float>.size,
            options: []
        )

        // Simple Quad Texture Coordinates (maps texture corners to quad corners)
        let texCoordData: [Float] = [
            // Triangle 1
            0.0, 1.0,  // Bottom Left
            1.0, 1.0,  // Bottom Right
            0.0, 0.0,  // Top Left
            // Triangle 2
            1.0, 1.0,  // Bottom Right
            1.0, 0.0,  // Top Right
            0.0, 0.0,  // Top Left
        ]
        texCoords = device.makeBuffer(
            bytes: texCoordData,
            length: texCoordData.count * MemoryLayout<Float>.size,
            options: []
        )
    }

    func setupPipeline(format: retro_pixel_format) {
        guard format != RETRO_PIXEL_FORMAT_UNKNOWN,
            pipelineState == nil || pixelFormat != format
        else {
            return
        }
        // Switch the to the new format
        print("Switching to pipeline for format \(format)")
        pixelFormat = format

        // Shaders
        let library = device.makeDefaultLibrary()!  // Assumes shaders are in default library
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        switch pixelFormat {
        case RETRO_PIXEL_FORMAT_0RGB1555:
            pipelineDescriptor.fragmentFunction = library.makeFunction(
                name: "fragmentShader_0RGB1555"
            )
        case RETRO_PIXEL_FORMAT_XRGB8888:
            pipelineDescriptor.fragmentFunction = library.makeFunction(
                name: "fragmentShader_XRGB8888"
            )
        case RETRO_PIXEL_FORMAT_RGB565:
            pipelineDescriptor.fragmentFunction = library.makeFunction(
                name: "fragmentShader_RGB565"
            )

        default:
            fatalError("Unsupported pixel format \(pixelFormat)")
        }

        do {
            pipelineState = try device.makeRenderPipelineState(
                descriptor: pipelineDescriptor
            )
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    func updateTexture(frame: Frame) {
        // Recreate the drawing texture if needed
        setupTexture(
            width: frame.width,
            height: frame.height,
            format: frame.metalPixelFormat
        )

        guard let currentTexture = texture,
            let frameBuffer = frame.buffer
        else {
            return
        }

        // Update texture
        let bytesPerPixel = currentTexture.pixelFormat.bytesPerPixel()
        let bytesPerRow = currentTexture.width * bytesPerPixel
        let region = MTLRegionMake2D(
            0,
            0,
            currentTexture.width,
            currentTexture.height
        )
        frameBuffer.withUnsafeBytes {
            (bufferPointer: UnsafeRawBufferPointer) in
            guard let baseAddress = bufferPointer.baseAddress else {
                print("Error: Could not get base address of frame data.")
                return
            }
            if bufferPointer.count >= bytesPerRow * currentTexture.height {
                currentTexture.replace(
                    region: region,
                    mipmapLevel: 0,
                    withBytes: baseAddress,
                    bytesPerRow: bytesPerRow
                )
            } else {
                print(
                    "Error: Frame data size (\(bufferPointer.count)) is less than required texture size (\(bytesPerRow * currentTexture.height))."
                )
            }
        }

    }

    func draw(in view: MTKView, frame: Frame) {
        // Validate the latest frame data
        guard frame.buffer != nil,
            frame.width > 0,
            frame.height > 0
        else {
            clearScreen(in: view)
            return
        }

        updateTexture(frame: frame)
        setupPipeline(format: frame.retroPixelFormat)

        // Render
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,  // Get descriptor for drawing target
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor
            ),
            let currentDrawable = view.currentDrawable,  // The final target to present
            let pipeState = pipelineState,
            let vertices = vertices,
            let texCoords = texCoords,
            let texture = texture
        else {  // Use the stored pipeline state
            print(
                "Draw: Failed to get command buffer, render pass descriptor, or encoder."
            )
            return
        }

        // Drawing commands
        renderEncoder.setRenderPipelineState(pipeState)
        renderEncoder.setVertexBuffer(vertices, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(texCoords, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(texture, index: 0)

        // Draw the 6 vertices (2 triangles)
        renderEncoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: 6
        )

        renderEncoder.endEncoding()

        // Send commands to the GPU
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

    func clearScreen(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor
            ),
            let currentDrawable = view.currentDrawable
        else {
            return
        }
        renderEncoder.endEncoding()
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}
