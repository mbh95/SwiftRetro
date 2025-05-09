//
//  GamePlayerWindowView.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 5/4/25.
//

import SwiftUI

struct GamePlayerWindowView: View {
    // Get the shared model from the environment
    @EnvironmentObject var viewModel: GamePlayerModel
    // Optional: Environment action to close the window programmatically
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            // Only show the player view if the game is actually running
//            if viewModel.isRunning && viewModel.latestFrame.buffer != nil {
                 GamePlayerView(viewModel: viewModel)
                    // Attempt to set frame based on game content, might need adjustments
                    .frame(
                         width: CGFloat(viewModel.latestFrame.width > 0 ? viewModel.latestFrame.width : 320),
                         height: CGFloat(viewModel.latestFrame.height > 0 ? viewModel.latestFrame.height : 240)
                    )
                    .aspectRatio(contentMode: .fit) // Maintain aspect ratio when resizing
                    .edgesIgnoringSafeArea(.all) // Allow game view to fill window if desired
//            } else {
//                // Placeholder when no game is running or frame data isn't ready
//                Text("Loading Game...")
//                    .frame(width: 320, height: 240) // Provide a default size placeholder
//                    .onAppear {
//                        // Optional: Automatically close if game stops?
//                        // Needs careful logic to avoid closing prematurely.
//                        // if !viewModel.isRunning { dismiss() }
//                    }
//            }
        }
        // Ensure this window can receive keyboard events
        .focusable()
        .onKeyPress(phases: .down) { keyPress in
            viewModel.handleKeyDown(key: keyPress.key)
            return .handled
        }
        .onKeyPress(phases: .up) { keyPress in
            viewModel.handleKeyUp(key: keyPress.key)
            return .handled
        }
        .onDisappear {
            // Decide if closing the window should unload the game
            // viewModel.unload() // Uncomment if closing window should stop the game
        }
    }
}
