//
//  RetroFileExtension+CoreDataProperties.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/24/25.
//
//

import Foundation
import CoreData


extension RetroFileExtension {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RetroFileExtension> {
        return NSFetchRequest<RetroFileExtension>(entityName: "RetroFileExtension")
    }

    @NSManaged public var extensionString: String?
    @NSManaged public var system: RetroSystem?

}

extension RetroFileExtension : Identifiable {

}
