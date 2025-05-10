//
//  GamePlayerView.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/23/25.
//

import Foundation
import MetalKit
import SwiftUI

struct GamePlayerView: View {
    @EnvironmentObject var viewModel: GamePlayerModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            GamePlayerViewRepresentable()
                // Recreate the renderer every time a new game is launched
                .id(viewModel.gameSessionId)
                .focusable()
                .onKeyPress(phases: .down) { press in
                    viewModel.handleKeyDown(key: press.key)
                    return .handled
                }
                .onKeyPress(phases: .up) { press in
                    viewModel.handleKeyUp(key: press.key)
                    return .handled
                }
                .frame(
                    minWidth: CGFloat(viewModel.getBaseScreenWidth()),
                    minHeight: CGFloat(viewModel.getBaseScreenHeight())
                )
        }
        .onDisappear {
            print("Game window closing, unloading core.")
            viewModel.unload()
        }
    }
}
struct GamePlayerViewRepresentable: NSViewRepresentable {
    @EnvironmentObject var viewModel: GamePlayerModel
    var mtkView: MTKView?

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.device = context.coordinator.renderer.device
        mtkView.enableSetNeedsDisplay = true  // Use delegate drawing, not internal timer
        mtkView.colorPixelFormat = .bgra8Unorm
        // TODO: Figure out how to handle fractional framerates.
        mtkView.preferredFramesPerSecond = Int(round(viewModel.getTargetFps()))
        print("target fps is \(viewModel.getTargetFps())")
        print("set fps to \(mtkView.preferredFramesPerSecond)")
        mtkView.clearColor = MTLClearColor(
            red: 0.1,
            green: 0.1,
            blue: 0.1,
            alpha: 1.0
        )
        mtkView.isPaused = false

        return mtkView
    }

    // Update the view (if needed, e.g., resizing)
    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.needsDisplay = true
    }

    // MARK: - Coordinator (Handles Metal Logic & Delegate)
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: GamePlayerViewRepresentable
        var viewModel: GamePlayerModel
        var renderer: MetalRenderer

        init(_ parent: GamePlayerViewRepresentable, viewModel: GamePlayerModel)
        {
            self.parent = parent
            self.viewModel = viewModel
            self.renderer = MetalRenderer()
            super.init()

        }

        // Main drawing loop
        func draw(in view: MTKView) {
            guard viewModel.isRunning else {
                renderer.clearScreen(in: view)
                return
            }

            // Simulate the next frame
            viewModel.runFrame()

            renderer.draw(in: view, frame: viewModel.latestFrame)
        }

        // Called when the view size changes (e.g., window resize)
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            print("Drawable size changed to: \(size)")
        }
    }
}
