//
//  PinAnnotation.swift
//  Artworks_On_Campus_Assignment_2
//
//  Created by Alkis Petrou on 11/26/17.
//  Copyright © 2017 Alkis Petrou. All rights reserved.
//

import MapKit

// USED TO STORE EACH PIN'S DATA
class PinAnnotation: NSObject, MKAnnotation {
    let title: String?
    let locationDesc: String
    let coordinate: CLLocationCoordinate2D
    let places: [Places]?
    
    // CONSTRUCTOR
    init(title: String, locationDesc: String, coordinate: CLLocationCoordinate2D, places: [Places]) {
        self.title = title
        self.locationDesc = locationDesc
        self.coordinate = coordinate
        self.places = places
        super.init()
    }
    
    // RETURN FOR LOCATION DESCRIPTION
    var subtitle: String? {
       return locationDesc
    }

}



