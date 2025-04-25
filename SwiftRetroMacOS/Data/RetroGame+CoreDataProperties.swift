//
//  RetroGame+CoreDataProperties.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/24/25.
//
//

import Foundation
import CoreData


extension RetroGame {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RetroGame> {
        return NSFetchRequest<RetroGame>(entityName: "RetroGame")
    }

    @NSManaged public var gameId: UUID?
    @NSManaged public var gamePath: URL?
    @NSManaged public var gameTitle: String?
    @NSManaged public var coreOverride: RetroCore?
    @NSManaged public var system: RetroSystem?

}

extension RetroGame : Identifiable {

}
