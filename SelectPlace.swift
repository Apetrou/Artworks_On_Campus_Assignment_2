//
//  SelectPlace.swift
//  Artworks_On_Campus_Assignment_2
//
//  Created by Alkis Petrou on 11/29/17.
//  Copyright © 2017 Alkis Petrou. All rights reserved.
//

import Foundation
import UIKit

public class SelectPlace: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // WILL STORE THE ARRAY OF ARTWORKS
    var placesArr = [Places]()
    // INDEX USED TO ACCESS CORRECT ARTWORK
    var index: Int?
    
    // CLOSE THE MODAL WHEN GOING BACK TO MAP
    @IBAction func backToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // HOW MANY ARTWORKS
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placesArr.count
    }
    
    // RETURN A CELL WITH THE ARTWORK TITLE
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "artworkCell")
        cell.textLabel?.text = placesArr[indexPath.row].title!
        // SET THE SUBTITLE
        cell.detailTextLabel?.text = placesArr[indexPath.row].locationNotes!
        cell.accessoryType = .disclosureIndicator

        return cell
    }
    
    // WHEN WE SELECT AN ARTOWRK PERFORM A SEGUE TO THE DETAILED VIEW
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        index = indexPath.row 
        performSegue(withIdentifier: "SelectArtWorkToArtwork", sender: placesArr)
    }
    
    // SET THE INDEX AND PLACES ARRAY IN THE DETAILED VIEW WHEN PERFORMING THE SEGUE
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "SelectArtWorkToArtwork") {
            let newViewController = segue.destination as! DetailedArtwork
            newViewController.index = index
            newViewController.places = sender as! [Places]
        }
    }
    
}
 
