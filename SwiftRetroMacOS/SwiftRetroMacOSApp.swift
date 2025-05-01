//
//  SwiftRetroMacOSApp.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/9/25.
//

import SwiftUI

@main
struct SwiftRetroMacOSApp: App {

    @StateObject private var coreDataStack = CoreDataStack.shared

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
                    openImportPanel()
                }
            }
        }
    }

    func openImportPanel() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Game Files to Import"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true

        guard openPanel.runModal() == .OK else { return }

        for gameUrl in openPanel.urls {
            importGame(
                url: gameUrl,
                context: coreDataStack.persistentContainer.viewContext
            )
        }
        CoreDataStack.shared.save()
    }

    func importGame(url: URL, context: NSManagedObjectContext) {
        let fileExtension = url.pathExtension
        print(
            "Attempting to import game: \(url.lastPathComponent), Extension: \(fileExtension)"
        )

        // Find the system that can handle the file's extension.
        let fetchRequest: NSFetchRequest<RetroFileExtension> =
            RetroFileExtension.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "extensionString CONTAINS[c] %@",
            fileExtension
        )
        fetchRequest.fetchLimit = 1

        var foundSystem: RetroSystem?
        do {
            let results = try context.fetch(fetchRequest)
            foundSystem = results.first?.system
        } catch {
            print(
                "Failed to fetch FileExtension using provided context: \(error)"
            )
        }

        guard let system = foundSystem
        else {
            print("Could not find system for extension: \(fileExtension)")
            return
        }

        print(
            "Detected game is for system: \(system.systemName ?? "Unknown")"
        )

        let newGame = RetroGame(context: context)
        newGame.gameId = UUID()
        newGame.gameTitle = url.deletingPathExtension().lastPathComponent
        newGame.system = system

        do {
            let bookmarkData = try url.bookmarkData(
                options: .securityScopeAllowOnlyReadAccess,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            newGame.gameBookmarkData = bookmarkData
            
            print("Successfully created bookmark for: \(url.lastPathComponent)")
        } catch {
            print("Failed to create bookmark data for \(url.path): \(error)")
            context.delete(newGame)
            return
        }
        print(
            "Finished importing: \(newGame.gameTitle ?? "Unknown") for \(system.systemName ?? "Unknown")"
        )
    }
}
