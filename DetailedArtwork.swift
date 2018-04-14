//
//  AnnotationView.swift
//  Artworks_On_Campus_Assignment_2
//
//  Created by Alkis Petrou on 11/28/17.
//  Copyright © 2017 Alkis Petrou. All rights reserved.
//

import Foundation
import UIKit

public class DetailedArtwork: UIViewController {
   
    // ALL OUTLETS
    @IBOutlet weak var lblYOW: UILabel!
    @IBOutlet weak var lblArtist: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var artworkImage: UIImageView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    // WILL STORE THE ARRAY OF ARTWORKS
    var places = [Places]()
    // INDEX USED TO ACCESS THE CORRECT ARTWORK
    var index: Int?
    
    // CLOSE THE MODAL SCREEN AND RETURN TO MAP VIEW
    @IBAction func backToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override public func viewDidLoad() {
        // SET THE OUTLETS
        navBar.topItem?.title = places[index!].title!
        lblArtist.text = places[index!].artist!
        lblYOW.text = places[index!].yearOfWork!
        lblDescription.text = places[index!].information!
        
        // IF THERE IS AN IMAGE PRESENT DISPLAY IT
        if(places[index!].image != nil) {
            artworkImage.image = UIImage(data: places[index!].image! as Data)
        }
 
    }
}
