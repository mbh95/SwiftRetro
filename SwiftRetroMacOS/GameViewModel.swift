//
//  GameViewModel.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import AppKit  // For NSOpenPanel
import Foundation
import Metal
import SwiftUI

// macOS specific ViewModel
class GameViewModel: NSObject, ObservableObject, LibretroCoreDelegate {
    @Published var coreStatus: String = "Idle"
    @Published var coreIsLoaded: Bool = false  // Track core state for UI enabling
    @Published var isRunning = false
    @Published var latestFrameData: Data?
    @Published var frameWidth: UInt32 = 0
    @Published var frameHeight: UInt32 = 0
    @Published var metalPixelFormat: MTLPixelFormat = .invalid

    private var core: LibretroCore?

    // MARK: - Core/ROM Loading

    func selectAndLoadCore() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Libretro Core (.dylib)"
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK {
            if let coreUrl = openPanel.url {
                unload()
                loadCore(corePath: coreUrl.path)
            }
        }
    }

    func selectAndLoadRom() {
        guard core != nil else {
            coreStatus = "Load Core First!"
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.title = "Select ROM File"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK {
            if let romUrl = openPanel.url {
                loadRom(romPath: romUrl.path)
            }
        }
    }

    private func loadCore(corePath: String) {
        coreStatus = "Loading Core..."
        coreIsLoaded = false
        guard let loadedCore = LibretroCore(corePath: corePath) else {
            coreStatus = "Error: Failed to initialize core"
            print("Failed to initialize core at \(corePath)")
            return
        }
        self.core = loadedCore
        self.core?.delegate = self

        if self.core?.load() == true {
            coreStatus =
                "Core Loaded: \(corePath.split(separator: "/").last ?? "")"
            coreIsLoaded = true
            print("Core loaded successfully")
        } else {
            coreStatus = "Error: Failed to load core"
            coreIsLoaded = false
            print("Failed to load core")
            self.core = nil
        }
    }

    private func loadRom(romPath: String) {
        guard let core = self.core else { return }
        coreStatus = "Loading ROM..."
        if core.loadGame(romPath) {
            coreStatus =
                "Game Loaded: \(romPath.split(separator: "/").last ?? "")"
            print("Game loaded successfully")
        } else {
            coreStatus = "Error: Failed to load ROM"
            print("Failed to load ROM at \(romPath)")
        }
    }

    func canStart() -> Bool {
        guard let core = self.core else { return false }
        return coreIsLoaded && (core.supportNoGame || core.gameLoaded)
    }

    func startCore() {
        guard let core = self.core else { return }
        if !canStart() {
            return
        }
        if !core.gameLoaded && core.supportNoGame {
            print("Calling load_game(NULL) for contentless core.")
            core.loadGame()
        }
        startRunLoop()
    }

    func unload() {
        stopRunLoop()
        core?.unloadGame()
        core?.unload()  // Calls the ObjC unload/cleanup
        core = nil
        coreIsLoaded = false
        coreStatus = "Idle"
        print("Core Unloaded")
    }

    func startRunLoop() { /* ... CVDisplayLink setup ... */
        coreStatus = "Running!"
        isRunning = true
    }
    @objc func runFrame() { core?.runFrame() }
    func stopRunLoop() { /* ... CVDisplayLink teardown ... */
        isRunning = false
    }
    deinit { stopRunLoop() }  // Ensure cleanup

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
        case RETRO_PIXEL_FORMAT_0RGB1555:
            targetFormat = .r16Uint
            bytesPerPixelInput = 2
        case RETRO_PIXEL_FORMAT_XRGB8888:
            targetFormat = .bgra8Unorm
            bytesPerPixelInput = 4
        default:
            targetFormat = .invalid
            print("Warning: Unsupported pixel format \(format)")
            return
        }

        guard width > 0, height > 0, bytesPerPixelInput > 0 else {
            print(
                "Error: Invalid dimensions: (\(width), \(height))"
            )
            return
        }

        let outputRowBytes = Int(width) * bytesPerPixelInput

        var frameDataToStore: Data?
        if pitch == outputRowBytes {
            // Frame data is contiguous - simple copy.
            frameDataToStore = Data(bytes: data, count: Int(height) * pitch)
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
            frameDataToStore = outputBuffer
        } else {
            print(
                "Error: Pitch (\(pitch)) is less than outputRowBytes (\(outputRowBytes))"
            )
            frameDataToStore = nil
        }

        // Use DispatchQueue.main.async to ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.latestFrameData = frameDataToStore  // Store the (potentially processed) data
            self.frameWidth = width
            self.frameHeight = height
            self.metalPixelFormat = targetFormat
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
