//
//  GameView.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/23/25.
//

import Foundation
import MetalKit
import SwiftUI

struct GameView: NSViewRepresentable {
    @ObservedObject var viewModel: GameViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: viewModel)
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.device = context.coordinator.renderer.device
        mtkView.enableSetNeedsDisplay = true  // Use delegate drawing, not internal timer
        mtkView.colorPixelFormat = .bgra8Unorm
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
        var parent: GameView
        var viewModel: GameViewModel
        var renderer: MetalRenderer

        init(_ parent: GameView, viewModel: GameViewModel) {
            self.parent = parent
            self.viewModel = viewModel
            self.renderer = MetalRenderer()
            super.init()

        }

        // Called when the view size changes (e.g., window resize)
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            print("Drawable size changed to: \(size)")
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
    }
}
