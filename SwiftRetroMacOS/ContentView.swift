//
//  ContentView.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import SwiftUI
import MetalKit

struct ContentView: View {
    // Keep the ViewModel specific to this macOS view hierarchy
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        VStack {
            Text("SwiftRetro for macOS")
                .font(.headline)

            Text("Core Status: \(viewModel.coreStatus)")
                .padding(.bottom)

            // Placeholder for the actual game rendering view (e.g., Metal view)
            // This would be an NSViewRepresentable wrapping MTKView
            GameRendererView(viewModel: viewModel)
                .frame(width: 640, height: 480) // Example size
                .border(Color.gray) // So we can see its bounds

            HStack(spacing: 20) {
                Button("Load Core") {
                    viewModel.selectAndLoadCore() // Uses NSOpenPanel
                }

                Button("Load ROM") {
                    viewModel.selectAndLoadRom() // Uses NSOpenPanel
                }
                .disabled(viewModel.coreIsLoaded == false) // Example: Disable if no core loaded

                Button("Unload") {
                    viewModel.unload()
                }
                .disabled(viewModel.coreIsLoaded == false) // Example: Disable if no core loaded
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 600) // Set a reasonable minimum window size
        .onDisappear {
            // Ensure cleanup when the window closes
            viewModel.unload()
        }
        // Add keyboard/mouse event handling modifiers here if needed
        // .onKeyPress(...)
    }
}

// Example macOS View Representable for the renderer
struct GameRendererView: NSViewRepresentable {
    @ObservedObject var viewModel: GameViewModel

    func makeNSView(context: Context) -> MTKView { // Or your custom NSView subclass
        // Setup MTKView for macOS
        let mtkView = MTKView()
        // Configure Metal device, pixel formats etc.
        // Set the delegate to the Coordinator if using MTKViewDelegate pattern
        // mtkView.delegate = context.coordinator
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update view if needed
    }

    // Add Coordinator class here if using MTKViewDelegate for rendering/run loop
}


struct MacContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
