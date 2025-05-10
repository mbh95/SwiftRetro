//
//  SwiftRetroMacOS.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import SwiftUI

@main
struct SwiftRetroMacOSApp: App {

    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var gamePlayerModel = GamePlayerModel()

    private var gameImporter: GameImporter = GameImporter(
        context: CoreDataStack.shared.context
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.managedObjectContext,
                    coreDataStack.persistentContainer.viewContext
                )
                .environmentObject(gamePlayerModel)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Games...") {
                    gameImporter.openImportPanel()
                }
            }
        }
        Window("Game", id: "game-window") {
            GamePlayerView()
                .environmentObject(gamePlayerModel)
        }.windowResizability(.contentSize)
            
    }

}
