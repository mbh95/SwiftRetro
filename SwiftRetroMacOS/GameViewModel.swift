//
//  GameViewModel.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import Foundation
import Metal
import SwiftUI

struct Frame {
    var buffer: Data?
    var width: Int = 0
    var height: Int = 0
    var metalPixelFormat: MTLPixelFormat = .invalid
}

class GameViewModel: NSObject, ObservableObject, LibretroCoreDelegate {
    @Published var coreStatus: String = "Idle"
    @Published var coreIsLoaded: Bool = false
    @Published var isRunning = false
    @Published var latestFrame: Frame = Frame()

    private var core: LibretroCore?

    // MARK: - Core/ROM Loading

    func loadCore(corePath: String) {
        coreStatus = "Loading Core..."
        coreIsLoaded = false
        guard let loadedCore = LibretroCore(corePath: corePath),
            loadedCore.load()
        else {
            coreStatus = "Error: Failed to load core"
            print("Failed to load core at \(corePath)")
            return
        }

        core = loadedCore
        core?.delegate = self
        coreIsLoaded = true
        coreStatus = "Core loaded"
    }

    func loadGame(gamePath: String) {
        coreStatus = "Loading game..."
        guard let core = self.core,
            core.loadGame(gamePath)
        else {
            coreStatus = "Error: Failed to load game"
            print("Failed to load game at \(gamePath)")
            return
        }

        coreStatus =
            "Game Loaded: \(gamePath.split(separator: "/").last ?? "")"
        print("Game loaded successfully")
    }

    func canStart() -> Bool {
        guard let core = self.core else { return false }
        return !isRunning && coreIsLoaded
            && (core.supportNoGame || core.gameLoaded)
    }

    func startCore() {
        guard let core = self.core, canStart() else { return }
        if !core.gameLoaded && core.supportNoGame {
            print("Calling load_game(NULL) for contentless core.")
            core.loadGame()
        }
        coreStatus = "Running!"
        isRunning = true
    }

    func unload() {
        isRunning = false
        coreStatus = "Idle"
        latestFrame = Frame()
        guard let loadedCore = self.core, coreIsLoaded else { return }
        loadedCore.unloadGame()
        loadedCore.unload()
        self.core = nil
        coreIsLoaded = false

        print("Core Unloaded")
    }

    @objc func runFrame() { core?.runFrame() }

    deinit { unload() }  // Ensure cleanup

    // MARK: - LibretroCoreDelegate Methods
    func renderVideoFrame(
        _ data: UnsafeRawPointer,
        width: UInt32,
        height: UInt32,
        pitch: Int,
        format: retro_pixel_format
    ) {
        var bytesPerPixelInput: Int
        var targetFormat: MTLPixelFormat = .invalid

        switch format {
        case RETRO_PIXEL_FORMAT_XRGB8888:
            targetFormat = .bgra8Unorm
            bytesPerPixelInput = 4
        default:
            targetFormat = .invalid
            print("Warning: Unsupported pixel format \(format)")
            return
        }

        guard width > 0, height > 0 else {
            print("Error: Invalid dimensions: (\(width)x\(height))")
            return
        }

        let outputRowBytes = Int(width) * bytesPerPixelInput

        var outputBuffer: Data?
        if pitch == outputRowBytes {
            // Frame data is contiguous - simple copy.
            outputBuffer = Data(bytes: data, count: Int(height) * pitch)
        } else if pitch > outputRowBytes {
            // Frame data is non-contiguous - copy row by row.
            var outputBuffer = Data(capacity: Int(height) * outputRowBytes)
            for y in 0..<Int(height) {
                let inputRowPointer = data.advanced(by: y * pitch)
                outputBuffer.append(
                    UnsafeBufferPointer(
                        start: inputRowPointer.assumingMemoryBound(
                            to: UInt8.self
                        ),
                        count: outputRowBytes
                    )
                )
            }
        } else {
            print(
                "Error: Pitch (\(pitch)) is less than outputRowBytes (\(outputRowBytes))"
            )
            outputBuffer = nil
        }

        // Use DispatchQueue.main.async to ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            guard let finalOutputBuffer = outputBuffer else {
                self.latestFrame = Frame()
                return
            }
            self.latestFrame = Frame(
                buffer: finalOutputBuffer,
                width: Int(width),
                height: Int(height),
                metalPixelFormat: targetFormat
            )
        }
    }

    func playAudioSamples(_ data: UnsafePointer<Int16>, frames: Int) {
        //         print("Audio: \(frames) frames")
    }

    func pollInput() {
        //         print("Poll Input")
    }

    func getInputState(
        _ port: UInt32,
        device: UInt32,
        index: UInt32,
        id: UInt32
    ) -> Int16 {
        return 0
    }
}
