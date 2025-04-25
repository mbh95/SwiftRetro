//
//  CoreDataStack.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/23/25.
//

import CoreData
import Foundation

struct InitialCoreData: Decodable {
    let coreName: String
    let corePath: String

    func toRetroCore(context: NSManagedObjectContext) -> RetroCore {
        let core = RetroCore(context: context)
        core.coreId = UUID()
        core.coreName = coreName
        core.corePath = URL(filePath: corePath)
        return core
    }
}

struct InitialSystemData: Decodable {
    let systemName: String
    let fileExtensions: [String]
    let cores: [InitialCoreData]

    func toRetroSystem(context: NSManagedObjectContext) -> RetroSystem {
        let system = RetroSystem(context: context)
        system.systemId = UUID()
        system.systemName = systemName

        for extensionString in fileExtensions {
            let fileExtension = RetroFileExtension(context: context)
            fileExtension.extensionString = extensionString
            fileExtension.system = system
        }

        for coreData in cores {
            let core = coreData.toRetroCore(context: context)
            core.addToSystem(system)
        }
        return system
    }
}

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    private static let initialDataLoadedKey = "initialDataLoaded"

    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentContainer = {

        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "Model")

        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { _, error in
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError(
                    "Failed to load persistent stores: \(error.localizedDescription)"
                )
            }
        }
        return container
    }()
    
    lazy var context: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()

    lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()
    
    private init() {
        loadInitialDataIfNeeded()
    }
    
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save the context:", error.localizedDescription)
        }
    }
    
    func saveBackgroundContext() {
            guard backgroundContext.hasChanges else { return }
            do {
                try backgroundContext.save()
            } catch {
               print("Failed to save background context:", error.localizedDescription)
            }
        }
    
    func loadInitialDataIfNeeded() {
            let defaults = UserDefaults.standard
            guard !defaults.bool(forKey: CoreDataStack.initialDataLoadedKey) else {
                print("Initial data already loaded.")
                return
            }

            print("Loading initial data...")

            guard let url = Bundle.main.url(forResource: "InitialData", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let initialSystems = try? JSONDecoder().decode([InitialSystemData].self, from: data)
            else {
                print("Failed to load or decode InitialData.json")
                return
            }

            // Use a background context for potentially long-running import
            backgroundContext.perform { [weak self] in
                 guard let self = self else { return }
                for systemData in initialSystems {
                    let system = systemData.toRetroSystem(context: backgroundContext)
                    print("LOADED SYSTEM: \(system)")
                }
                self.saveBackgroundContext()
                defaults.set(true, forKey: CoreDataStack.initialDataLoadedKey)
                print("Finished loading initial data.")
            }
        }
    
    func findSystem(for fileExtension: String) -> RetroSystem? {
            let fetchRequest: NSFetchRequest<RetroFileExtension> = RetroFileExtension.fetchRequest()
            // Case-insensitive search for the extension
            fetchRequest.predicate = NSPredicate(format: "extension CONTAINS[c] %@", fileExtension)
            fetchRequest.fetchLimit = 1

            do {
                let results = try persistentContainer.viewContext.fetch(fetchRequest)
                return results.first?.system
            } catch {
                print("Failed to fetch FileExtension: \(error)")
                return nil
            }
        }
}
