//
//  GamePlayerModel.swift
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
    var retroPixelFormat: retro_pixel_format = RETRO_PIXEL_FORMAT_0RGB1555
}

class GamePlayerModel: NSObject, ObservableObject, LibretroCoreDelegate {
    @Published var coreStatus: String = "Idle"
    @Published var coreIsLoaded: Bool = false
    @Published var isRunning = false
    @Published var latestFrame: Frame = Frame()

    private var core: LibretroCore?
    private var pressedKeys: Set<KeyEquivalent> = []

    // MARK: - Core/ROM Loading

    func loadCore(coreToLoad: RetroCore) -> Bool {
        coreStatus = "Loading Core..."
        coreIsLoaded = false
        guard
            let corePath = coreToLoad.corePath?.path(),
            let loadedCore = LibretroCore(corePath: corePath),
            loadedCore.load()
        else {
            coreStatus = "Error: Failed to load core"
            print("Failed to load core \(coreToLoad)")
            return false
        }

        core = loadedCore
        core?.delegate = self
        coreIsLoaded = true
        coreStatus = "Core loaded"
        return true
    }

    func resolveGameUrl(game: RetroGame) -> URL? {
        do {
            var isStale = false
            let resolvedUrl = try URL(
                resolvingBookmarkData: game.gameBookmarkData!,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                print(
                    "Warning: Bookmark data is stale for \(game.gameTitle ?? "Untitled Game")."
                )
            }
            return resolvedUrl
        } catch {
            print(
                "Error resolving bookmark data for \(game.gameTitle ?? "Untitled Game"): \(error)"
            )
            // TODO: Prompt user to re-import game?
        }
        return nil
    }

    func loadGame(gameToLoad: RetroGame) -> Bool {
        coreStatus = "Loading game..."

        guard let core = self.core,
            let resolvedUrl = resolveGameUrl(game: gameToLoad),
            resolvedUrl.startAccessingSecurityScopedResource(),
            core.loadGame(resolvedUrl.path)
        else {
            coreStatus = "Error: Failed to load game"
            print(
                "Failed to load game \(gameToLoad))"
            )
            return false
        }
        resolvedUrl.stopAccessingSecurityScopedResource()

        coreStatus =
            "Game Loaded: \(gameToLoad.gameTitle ?? "Unknown Game")"
        print("Game Loaded: \(gameToLoad.gameTitle ?? "Unknown Game")")
        return true

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
        case RETRO_PIXEL_FORMAT_RGB565:
            targetFormat = .r16Uint
            bytesPerPixelInput = 2
        case RETRO_PIXEL_FORMAT_0RGB1555:
            targetFormat = .r16Uint
            bytesPerPixelInput = 2
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
        if pitch == outputRowBytes {
            // Frame data is contiguous - simple copy.
            let outputBuffer = Data(bytes: data, count: Int(height) * pitch)
            DispatchQueue.main.async {
                self.latestFrame = Frame(
                    buffer: outputBuffer,
                    width: Int(width),
                    height: Int(height),
                    metalPixelFormat: targetFormat,
                    retroPixelFormat: format
                )
            }
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
            DispatchQueue.main.async {
                self.latestFrame = Frame(
                    buffer: outputBuffer,
                    width: Int(width),
                    height: Int(height),
                    metalPixelFormat: targetFormat,
                    retroPixelFormat: format
                )
            }
        } else {
            print(
                "Error: Pitch (\(pitch)) is less than outputRowBytes (\(outputRowBytes))"
            )
            DispatchQueue.main.async {
                self.latestFrame = Frame()
                return

            }
        }
    }

    func playAudioSamples(_ data: UnsafePointer<Int16>, frames: Int) {
        //         print("Audio: \(frames) frames")
    }

    func handleKeyDown(key: KeyEquivalent) {
        pressedKeys.insert(key)
    }

    func handleKeyUp(key: KeyEquivalent) {
        pressedKeys.remove(key)
    }

    func pollInput() {

    }

    func getInputState(
        _ port: UInt32,
        device: UInt32,
        index: UInt32,
        id: UInt32
    ) -> Int16 {
        //        print("port: \(port)\ndevice: \(device)\nindex: \(index)\nid: \(id)")
        guard port == 0, device == RETRO_DEVICE_JOYPAD else { return 0 }

        switch id {
        case 8:  // RETRO_DEVICE_ID_JOYPAD_A:
            return pressedKeys.contains(KeyEquivalent("x")) ? 1 : 0
        case 0:  // RETRO_DEVICE_ID_JOYPAD_B:
            return pressedKeys.contains(KeyEquivalent("z")) ? 1 : 0
        case 3:  // RETRO_DEVICE_ID_JOYPAD_START:
            return pressedKeys.contains(KeyEquivalent.return) ? 1 : 0
        case 4:  // RETRO_DEVICE_ID_JOYPAD_UP:
            return pressedKeys.contains(KeyEquivalent.upArrow) ? 1 : 0
        case 5:  // RETRO_DEVICE_ID_JOYPAD_DOWN:
            return pressedKeys.contains(KeyEquivalent.downArrow) ? 1 : 0
        case 6:  // RETRO_DEVICE_ID_JOYPAD_LEFT:
            return pressedKeys.contains(KeyEquivalent.leftArrow) ? 1 : 0
        case 7:  // RETRO_DEVICE_ID_JOYPAD_RIGHT:
            return pressedKeys.contains(KeyEquivalent.rightArrow) ? 1 : 0
        default:
            return 0
        }
    }
}
