//
//  ContentView.swift
//  SwiftRetro
//
//  Created by Matt Hammond on 4/8/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel() // Create instance

    let corePath = Bundle.main.privateFrameworksURL!.appendingPathComponent("2048_libretro_ios.dylib").path
    var body: some View {
        VStack {
            Text("Core Status: \(viewModel.coreStatus)") // Display status
                .padding()

            // Placeholder for game view
            Rectangle()
                .fill(Color.black)
                .frame(width: 320, height: 240) // Example size

            HStack {
                 Button("Load Core & ROM") {
                     if !corePath.isEmpty {
                           viewModel.loadCoreAndGame(corePath: corePath, gamePath: nil)
                      } else {
                           viewModel.coreStatus = "Error: Core or ROM path missing in ContentView"
                           print("Error: Core or ROM path missing in ContentView")
                      }
                 }
                 Button("Unload") {
                      viewModel.unload()
                 }
            }
            .padding()
        }
        .onDisappear {
            viewModel.unload() // Unload when view disappears
        }
    }
}

#Preview {
    ContentView()
}
