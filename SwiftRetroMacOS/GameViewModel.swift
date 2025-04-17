//
//  GameViewModel.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import AppKit  // For NSOpenPanel
import CoreVideo  // For CVDisplayLink if used
import Foundation
import SwiftUI

// macOS specific ViewModel
class GameViewModel: NSObject, ObservableObject, LibretroCoreDelegate {
    @Published var coreStatus: String = "Idle"
    @Published var coreIsLoaded: Bool = false  // Track core state for UI enabling
    @Published var isRunning = false

    private var core: LibretroCore?
    private var displayLink: CVDisplayLink?  // macOS uses CVDisplayLink

    // MARK: - Core/ROM Loading (macOS)

    func selectAndLoadCore() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Libretro Core (.dylib)"
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        //        openPanel.allowedContentTypes = [.dynamicLibrary] // UTI for dylib

        if openPanel.runModal() == .OK {
            if let coreUrl = openPanel.url {
                unload()  // Ensure previous core is unloaded
                // On macOS, dlopen is less restrictive, can load from anywhere usually
                // Make sure the core is compiled for macOS (arm64 or x86_64)
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
        // Add allowedContentTypes based on core requirements later
        // openPanel.allowedContentTypes = [...]
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
        self.core?.delegate = self  // Set delegate to THIS macOS ViewModel instance

        if self.core?.load() == true {
            coreStatus =
                "Core Loaded: \(corePath.split(separator: "/").last ?? "")"
            coreIsLoaded = true
            print("macOS: Core loaded successfully")
        } else {
            coreStatus = "Error: Failed to load core"
            coreIsLoaded = false
            print("macOS: Failed to load core")
            self.core = nil
        }
    }

    private func loadRom(romPath: String) {
        guard let core = self.core else { return }
        coreStatus = "Loading ROM..."
        if core.loadGame(romPath) {
            coreStatus =
                "Game Loaded: \(romPath.split(separator: "/").last ?? "")"
            print("macOS: Game loaded successfully")
        } else {
            coreStatus = "Error: Failed to load ROM"
            print("macOS: Failed to load ROM at \(romPath)")
        }
    }

    func canStart() -> Bool {
        return coreIsLoaded && core?.canStart() ?? false
    }

    func startCore() {
        guard let core = self.core else { return }
        if !core.canStart() { return }
        startRunLoop()
    }

    func unload() {
        stopRunLoop()
        core?.unloadGame()
        core?.unload()  // Calls the ObjC unload/cleanup
        core = nil
        coreIsLoaded = false
        coreStatus = "Idle"
        print("macOS: Core Unloaded")
    }

    // MARK: - Run Loop (macOS: CVDisplayLink or MTKViewDelegate)
    // --- Include CVDisplayLink implementation here if NOT using MTKViewDelegate ---
    // --- Otherwise, remove start/stop/runFrame and call core?.runFrame() from MTKViewDelegate ---
    func startRunLoop() { /* ... CVDisplayLink setup ... */
        coreStatus = "Running!"
        isRunning = true
    }
    @objc func runFrame() { core?.runFrame() }
    func stopRunLoop() { /* ... CVDisplayLink teardown ... */
        isRunning = false
    }
    deinit { stopRunLoop() }  // Ensure cleanup

    // MARK: - LibretroCoreDelegate Methods (macOS Implementations)
    // These methods will be called BY the shared ObjC bridge, but implemented
    // specifically for macOS here.

    func renderVideoFrame(
        _ data: UnsafeRawPointer,
        width: UInt32,
        height: UInt32,
        pitch: Int,
        format: retro_pixel_format
    ) {
        // macOS: Handle video frame - update data for MacGameRendererView (MTKView)
        // print("macOS Video: \(width)x\(height)")
        // You might copy the data or pass the pointer (carefully) to the renderer
    }

    func playAudioSamples(_ data: UnsafePointer<Int16>, frames: Int) {
        // macOS: Handle audio - feed samples to AVAudioEngine or other macOS audio API
        // print("macOS Audio: \(frames) frames")
    }

    func pollInput() {
        // macOS: Update internal state based on NSEvent, GameController, etc.
        // print("macOS Poll Input")
    }

    func getInputState(
        _ port: UInt32,
        device: UInt32,
        index: UInt32,
        id: UInt32
    ) -> Int16 {
        // macOS: Lookup state gathered during pollInput for the specific button/axis ID
        // print("macOS Get Input State")
        return 0  // Placeholder
    }
}
