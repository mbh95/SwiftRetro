//
//  ContentView.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import AppKit
import CoreGraphics
import MetalKit
import SwiftUI

struct ContentView: View {
    // Keep the ViewModel specific to this macOS view hierarchy
    @StateObject private var viewModel = GameViewModel()

    func selectAndLoadCore() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Libretro Core (.dylib)"
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false

        guard openPanel.runModal() == .OK,
            let coreUrl = openPanel.url
        else {
            return
        }

        viewModel.loadCore(corePath: coreUrl.path)
    }

    func selectAndLoadGame() {
        guard viewModel.coreIsLoaded else {
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.title = "Select Game File"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        guard openPanel.runModal() == .OK,
            let gameUrl = openPanel.url
        else {
            return
        }

        viewModel.loadGame(gamePath: gameUrl.path)
    }

    var body: some View {
        VStack {
            Text("SwiftRetro for macOS")
                .font(.headline)

            Text("Core Status: \(viewModel.coreStatus)")
                .padding(.bottom)

            GameRendererView(viewModel: viewModel)
                .frame(
                    width: CGFloat(viewModel.latestFrameData?.frameWidth ?? 0),
                    height: CGFloat(viewModel.latestFrameData?.frameHeight ?? 0)
                )
                .border(Color.gray)  // So we can see its bounds

            HStack(spacing: 20) {
                Button("Load Core") {
                    selectAndLoadCore()
                }

                Button("Load ROM") {
                    selectAndLoadGame()
                }
                .disabled(viewModel.coreIsLoaded == false)  // Example: Disable if no core loaded

                Button("Unload") {
                    viewModel.unload()
                }
                .disabled(viewModel.coreIsLoaded == false)  // Example: Disable if no core loaded

                Button("Start") {
                    viewModel.startCore()
                }
                .disabled(viewModel.canStart() == false)
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 600)  // Set a reasonable minimum window size
        .onDisappear {
            // Ensure cleanup when the window closes
            viewModel.unload()
        }
        // Add keyboard/mouse event handling modifiers here if needed
        // .onKeyPress(...)
    }
}

struct GameRendererView: NSViewRepresentable {
    @ObservedObject var viewModel: GameViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.device = context.coordinator.device
        mtkView.enableSetNeedsDisplay = true  // Use delegate drawing, not internal timer
        mtkView.isPaused = false

        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(
            red: 0.1,
            green: 0.1,
            blue: 0.1,
            alpha: 1.0
        )

        context.coordinator.setupMetal()
        context.coordinator.setupTexture(
            width: Int(viewModel.latestFrameData?.frameWidth ?? 0),
            height: Int(viewModel.latestFrameData?.frameHeight ?? 0),
            format: viewModel.latestFrameData?.metalPixelFormat ?? .invalid
        )

        return mtkView
    }

    // Update the view (if needed, e.g., resizing)
    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.setupTexture(
            width: Int(viewModel.latestFrameData?.frameWidth ?? 0),
            height: Int(viewModel.latestFrameData?.frameHeight ?? 0),
            format: viewModel.latestFrameData?.metalPixelFormat ?? .invalid
        )
        nsView.needsDisplay = true
    }

    // MARK: - Coordinator (Handles Metal Logic & Delegate)
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: GameRendererView
        var viewModel: GameViewModel  // Access viewModel directly
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var texture: MTLTexture?
        var vertices: MTLBuffer!
        var texCoords: MTLBuffer!

        init(_ parent: GameRendererView, viewModel: GameViewModel) {
            self.parent = parent
            self.viewModel = viewModel
            super.init()
            setupMetal()
        }

        func setupMetal() {
            guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
                fatalError("Metal is not supported on this device")
            }
            device = defaultDevice
            commandQueue = device.makeCommandQueue()
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

            setupPipelineAndVertices(textureFormat: format)
        }

        // Setup vertex/texCoord buffers and pipeline state
        func setupPipelineAndVertices(textureFormat: MTLPixelFormat) {
            guard textureFormat != .invalid else {
                print(
                    "Coordinator: Cannot setup pipeline with invalid texture format."
                )
                pipelineState = nil
                return
            }
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

            // Shaders
            let library = device.makeDefaultLibrary()!  // Assumes shaders are in default library
            let vertexFunction = library.makeFunction(name: "vertexShader")
            let fragmentFunction = library.makeFunction(name: "fragmentShader")

            // Pipeline state
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            do {
                pipelineState = try device.makeRenderPipelineState(
                    descriptor: pipelineDescriptor
                )
            } catch {
                fatalError("Failed to create pipeline state: \(error)")
            }
        }

        // Called when the view size changes (e.g., window resize)
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            print("Drawable size changed to: \(size)")
        }

        // Main drawing loop
        func draw(in view: MTKView) {
            guard viewModel.isRunning else {
                clearScreen(in: view)
                return
            }

            // Simulate the next frame
            viewModel.runFrame()

            // Fetch and validate the frame data
            guard let currentTexture = texture,
                let frameData = viewModel.latestFrameData,  // Use the data from ViewModel
                currentTexture.width == frameData.frameWidth,  // Ensure texture matches data
                currentTexture.height == frameData.frameHeight,
                currentTexture.pixelFormat == frameData.metalPixelFormat,  // Ensure formats match
                frameData.frameWidth > 0, frameData.frameHeight > 0
            else {
                clearScreen(in: view)
                return
            }

            // Update texture
            let bytesPerPixel = currentTexture.pixelFormat.bytesPerPixel()
            guard bytesPerPixel > 0 else {
                print(
                    "Error: Invalid bytes per pixel for format \(currentTexture.pixelFormat)"
                )
                clearScreen(in: view)
                return
            }
            let bytesPerRow = currentTexture.width * bytesPerPixel
            let region = MTLRegionMake2D(
                0,
                0,
                currentTexture.width,
                currentTexture.height
            )
            frameData.buffer.withUnsafeBytes {
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

            // Render
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                let renderPassDescriptor = view.currentRenderPassDescriptor,  // Get descriptor for drawing target
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(
                    descriptor: renderPassDescriptor
                ),
                let currentDrawable = view.currentDrawable,  // The final target to present
                let pipeState = pipelineState
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
            renderEncoder.setFragmentTexture(currentTexture, index: 0)

            // Draw the 6 vertices (2 triangles)
            renderEncoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: 6
            )

            renderEncoder.endEncoding()  // Finish encoding

            // Send commands to the GPU
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
        }

        // Helper to clear screen if no frame available
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
}

extension MTLPixelFormat {
    func bytesPerPixel() -> Int {
        switch self {
        case .bgra8Unorm, .rgba8Unorm, .rgba8Sint, .bgra8Unorm_srgb,
            .rgba8Unorm_srgb:
            return 4
        case .r16Uint, .bgr5A1Unorm, .a1bgr5Unorm, .abgr4Unorm:
            return 2
        default:
            print("Warning: bytesPerPixel not defined for format \(self)")
            return 0
        }
    }
}

struct MacContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
