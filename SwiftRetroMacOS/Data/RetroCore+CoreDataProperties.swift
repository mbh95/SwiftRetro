//
//  RetroCore+CoreDataProperties.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/24/25.
//
//

import Foundation
import CoreData


extension RetroCore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RetroCore> {
        return NSFetchRequest<RetroCore>(entityName: "RetroCore")
    }

    @NSManaged public var corePath: URL?
    @NSManaged public var coreId: UUID?
    @NSManaged public var coreName: String?
    @NSManaged public var system: NSSet?

}

// MARK: Generated accessors for system
extension RetroCore {

    @objc(addSystemObject:)
    @NSManaged public func addToSystem(_ value: RetroSystem)

    @objc(removeSystemObject:)
    @NSManaged public func removeFromSystem(_ value: RetroSystem)

    @objc(addSystem:)
    @NSManaged public func addToSystem(_ values: NSSet)

    @objc(removeSystem:)
    @NSManaged public func removeFromSystem(_ values: NSSet)

}

extension RetroCore : Identifiable {

}
