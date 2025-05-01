//
//  RetroSystem+CoreDataProperties.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/24/25.
//
//

import Foundation
import CoreData


extension RetroSystem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RetroSystem> {
        return NSFetchRequest<RetroSystem>(entityName: "RetroSystem")
    }

    @NSManaged public var systemId: UUID?
    @NSManaged public var systemName: String?
    @NSManaged public var cores: NSSet?
    @NSManaged public var fileExtensions: NSSet?
    @NSManaged public var games: NSSet?

}

// MARK: Generated accessors for cores
extension RetroSystem {

    @objc(addCoresObject:)
    @NSManaged public func addToCores(_ value: RetroCore)

    @objc(removeCoresObject:)
    @NSManaged public func removeFromCores(_ value: RetroCore)

    @objc(addCores:)
    @NSManaged public func addToCores(_ values: NSSet)

    @objc(removeCores:)
    @NSManaged public func removeFromCores(_ values: NSSet)

}

// MARK: Generated accessors for fileExtensions
extension RetroSystem {

    @objc(addFileExtensionsObject:)
    @NSManaged public func addToFileExtensions(_ value: RetroFileExtension)

    @objc(removeFileExtensionsObject:)
    @NSManaged public func removeFromFileExtensions(_ value: RetroFileExtension)

    @objc(addFileExtensions:)
    @NSManaged public func addToFileExtensions(_ values: NSSet)

    @objc(removeFileExtensions:)
    @NSManaged public func removeFromFileExtensions(_ values: NSSet)

}

// MARK: Generated accessors for games
extension RetroSystem {

    @objc(addGamesObject:)
    @NSManaged public func addToGames(_ value: RetroGame)

    @objc(removeGamesObject:)
    @NSManaged public func removeFromGames(_ value: RetroGame)

    @objc(addGames:)
    @NSManaged public func addToGames(_ values: NSSet)

    @objc(removeGames:)
    @NSManaged public func removeFromGames(_ values: NSSet)

}

extension RetroSystem : Identifiable {

}
