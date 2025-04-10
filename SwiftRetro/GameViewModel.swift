//
//  GameViewModel.swift
//  SwiftRetro
//
//  Created by Matt Hammond on 4/9/25.
//

import Foundation
import SwiftUI

class GameViewModel: NSObject, ObservableObject, LibretroCoreDelegate { // Conform to NSObject and delegate
    @Published var coreStatus: String = "Idle" // Example published property
    private var core: LibretroCore?
    private var displayLink: CADisplayLink? // For run loop

    func loadCoreAndGame(corePath: String, gamePath: String?) {
        coreStatus = "Loading Core..."
        guard let loadedCore = LibretroCore(corePath: corePath) else {
            coreStatus = "Failed to init core"
            print("Failed to init core at \(corePath)")
            return
        }
        self.core = loadedCore
        self.core?.delegate = self // Set delegate

        if self.core?.load() == true {
            coreStatus = "Core Loaded"
            print("Core loaded successfully")
            if let gamePath = gamePath {
                coreStatus = "Loading Game..."
                if self.core?.loadGame(gamePath) == true {
                     coreStatus = "Game Loaded"
                     print("Game loaded successfully")
                     startRunLoop()
                } else {
                     coreStatus = "Failed to load game"
                     print("Failed to load game at \(gamePath)")
                }
            } else {
                 // Handle loading without game if core supports it
                 startRunLoop()
            }
        } else {
            coreStatus = "Failed to load core"
            print("Failed to load core")
            self.core = nil // Clear out invalid core
        }
    }

    func unload() {
         stopRunLoop()
         core?.unloadGame()
         core?.unload()
         core = nil
         coreStatus = "Unloaded"
         print("Core Unloaded")
    }

    // MARK: - Run Loop
    func startRunLoop() {
        stopRunLoop() // Ensure previous one is stopped
        displayLink = CADisplayLink(target: self, selector: #selector(runFrame))
        // Add to a common run loop mode; adjust frame rate later if needed
         displayLink?.add(to: .main, forMode: .common)
         coreStatus = "Running"
         print("Starting Run Loop")
    }

    @objc func runFrame() {
        core?.runFrame()
    }

    func stopRunLoop() {
         displayLink?.invalidate()
         displayLink = nil
         if coreStatus == "Running" { coreStatus = "Paused?" } // Update status if needed
         print("Stopping Run Loop")
    }

    // MARK: - LibretroCoreDelegate Methods (Initial Stubs)
    func renderVideoFrame(_ data: UnsafeRawPointer, width: UInt32, height: UInt32, pitch: Int, format: retro_pixel_format) {
        // TODO: Implement actual rendering (Metal/OpenGL) later
        print("Swift Delegate: Received Video Frame \(width)x\(height), Pitch: \(pitch), Format: \(format.rawValue)")
        // For now, maybe just update a counter or image data placeholder
    }

    func playAudioSamples(_ data: UnsafePointer<Int16>, frames: Int) {
        // TODO: Implement actual audio playback (AVAudioEngine) later
        print("Swift Delegate: Received \(frames) Audio Frames")
    }

    func pollInput() {
        // TODO: Read actual input devices later
        // print("Swift Delegate: Poll Input Called")
    }

    func getInputState(_ port: UInt32, device: UInt32, index: UInt32, id: UInt32) -> Int16 {
        // TODO: Return actual input state later
        // print("Swift Delegate: Get Input State Called for Port \(port), Device \(device), Index \(index), ID \(id)")
        return 0 // Return "not pressed" for now
    }
}
