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
                .environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
        }
    }
}
