//
//  Places+CoreDataProperties.swift
//  Artworks_On_Campus_Assignment_2
//
//  Created by Alkis Petrou on 11/26/17.
//  Copyright © 2017 Alkis Petrou. All rights reserved.
//
//

import Foundation
import CoreData

extension Places {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Places> {
        return NSFetchRequest<Places>(entityName: "Places")
    }

    @NSManaged public var fileName: String?
    @NSManaged public var id: String?
    @NSManaged public var image: NSData?
    @NSManaged public var information: String?
    @NSManaged public var lastModified: String?
    @NSManaged public var lat: String?
    @NSManaged public var locationNotes: String?
    @NSManaged public var long: String?
    @NSManaged public var title: String?
    @NSManaged public var yearOfWork: String?
    @NSManaged public var artist: String?
}
