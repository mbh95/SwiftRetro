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
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Games...") {
                    gameImporter.openImportPanel()
                }
            }
        }
    }

}
