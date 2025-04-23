//
//  ContentView.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import AppKit
import SwiftUI

struct ContentView: View {
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

            GameView(viewModel: viewModel)
                .frame(
                    width: CGFloat(viewModel.latestFrame.width),
                    height: CGFloat(viewModel.latestFrame.height)
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
        .focusable()
        .onKeyPress(phases: .down) { pressedKey in
            viewModel.handleKeyDown(key: pressedKey.key)
            return .handled
        }
        .onKeyPress(phases: .up) { pressedKey in
            viewModel.handleKeyUp(key: pressedKey.key)
            return .handled
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
