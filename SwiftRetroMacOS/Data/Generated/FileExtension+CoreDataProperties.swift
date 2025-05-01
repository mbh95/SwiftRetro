//
//  FileExtension+CoreDataProperties.swift
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/24/25.
//
//

import Foundation
import CoreData


extension FileExtension {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileExtension> {
        return NSFetchRequest<FileExtension>(entityName: "FileExtension")
    }

    @NSManaged public var extension: String?
    @NSManaged public var system: System?

}

extension FileExtension : Identifiable {

}
