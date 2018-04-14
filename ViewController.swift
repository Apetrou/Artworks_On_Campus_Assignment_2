//
//  ViewController.swift
//  Artworks_On_Campus_Assignment_2
//
//  Created by Alkis Petrou on 11/26/17.
//  Copyright © 2017 Alkis Petrou. All rights reserved.
//

// IMPORT ALL LIBRARIES
import UIKit
import MapKit
import CoreData
import CoreLocation

// THIS CLASS WILL REPRESENT EACH ANNOTATION GROUP
class PlacesGrouped {
    var distanceFromCurrent: Double
    var arrayOfPlaces: [Places]
    
    init(distanceFromCurrent: Double, arrayOfPlaces: [Places]) {
        self.distanceFromCurrent = distanceFromCurrent
        self.arrayOfPlaces = arrayOfPlaces
    }
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // JSON URL USED TO RETREIVE ART LOCATION DATA
    let jsonURL = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks"
    // URL USED TO RETREIVE IMAGE FOR LOCATION
    let imageURL = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/"
    
    //CORE DATA SETUP
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    // MAP OUTLET
    @IBOutlet weak var map: MKMapView!
    // TABLE OUTLET
    @IBOutlet weak var groupedArtworksTable: UITableView!
    
    // LOC MANAGER
    var locationManager = CLLocationManager()
    
    // GLOBAL CLASS VARIABLES
    var placesArrayGrouped = [PlacesGrouped]()
    var placesArray = [Places]()
    var userLocation: CLLocation!
    
    // WILL HOLD LOADING SCREEN
    var sv: UIView? = nil
    
    // FLAG TO CHECK IF ARTOWORKS HAVE CHANGED FROM UPDATE
    var didChangeData: Bool? = false
    
    // ONLY WANT TO UPDATE ONCE AT THE START
    var didPerformUpdate: Bool? = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SETUP LOCATION MANAGER AND START UPDATING LOCATION
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // LOAD THE CONTEXT
        context = appDelegate.persistentContainer.viewContext
    }
    
    // LOCATION MANAGER WILL HANDLE NOTIFICATIONS WHEN THEY ARRIVE AND PROCEED WITH THE APPLICATION
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // CENTER USERS LOCATION
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        let region = MKCoordinateRegion(center: location, span: span)
        self.map.setRegion(region, animated: true)
    
        // WE ONLY WANT TO EXECUTE THIS CODE ONCE AT THE START OF THE APPLICATION
        if(didPerformUpdate == false) {
    
            // CREATING A NSURL
            let url = NSURL(string: jsonURL)
            
            // CHECK IF LOCATIONS ALREADY CACHED IF THEY ARE POPULATE THE MAP
            if(retreivePlacesAsArray() > 0) {
                populateMap()
            } else {
                // ELSE ADD THE LOADING SCREEN AND WAIT FOR ARTWORKS TO DOWNLOAD
                // DISPLAY LOADING SCREEN
                sv = UIViewController.displaySpinner(onView: self.view)
            }
            
            // CHECK FOR UPDATES
            // WAIT UNTIL COMPLETION SENT BACK
            updateData( requestUrl: url! ) { data in
                if let data = data {
                    if(data == true) {
                        // ONCE COMPLETE REMOVE LOADING SCREEN AND POPULATE MAP FROM THE MAIN THREAD
                        if (self.sv != nil) {
                            UIViewController.removeSpinner(spinner: self.sv!)
                        }
                        // IF THE DATA HAS BEEN CHANGED AND THERE ARE LOCATIONS CACHED THEN RELOAD THE MAP FROM MAIN THREAD
                        if(self.retreivePlacesAsArray() > 0 && self.didChangeData == true) {
                            DispatchQueue.main.async() {
                                self.populateMap()
                            }
                        }
                    } else {
                         self.alert(message: "A server error has occured, please restart the app.", title: "Update Failed!")
                    }
                }
            }
            // FLAG TO REFRESH MAP
            self.didPerformUpdate = true
        }
        
    }
    
    // HOW MANY GROUPS IN TABLE
    func numberOfSections(in tableView: UITableView) -> Int {
        if placesArrayGrouped.count > 0 {
            print("section number " + String(placesArrayGrouped.count))
            return placesArrayGrouped.count
        } else {
            return 0
        }
    }
    
    // NUMBER OF ROWS IN TABLE SECTION OR GROUP
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(placesArrayGrouped.count > 0) {
            let group = placesArrayGrouped[section]
            return group.arrayOfPlaces.count
        } else {
            return 0
        }
    }
    
    // RETURN EACH CELL IN THE TABLE
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell;
        if(placesArrayGrouped.count > 0) {
            let group = placesArrayGrouped[indexPath.section]
            cell.textLabel?.text = group.arrayOfPlaces[indexPath.row].title
            cell.detailTextLabel?.text = group.arrayOfPlaces[indexPath.row].locationNotes
        }
        return cell
    }
    
    // FUNCTION RESPONSIBLE FOR DOWNLOADING DATA FROM JSON URL AND UPDATING IF NECESSARY
    func updateData (requestUrl: NSURL,completion: @escaping (_ result: Bool?)->Void){
    
        // FETCH DATA FROM URL IN A SEPERATE THREAD
        URLSession.shared.dataTask(with: (requestUrl as URL)) { data,response,error in
            
            // IF THERE IS A PROBLEM WITH THE URL RETURN FALSE
            if data == nil {
                completion(false)
            } else {
                if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                    if let artLocationArray = jsonObj!.value(forKey: "artworks") as? NSArray {
                        // LOOP THROUGH EACH ARTWORK IN THE URL
                        for loc in artLocationArray {
            
                            // CONVERT TO DICTIONAIRY
                            if let locDict = loc as? NSDictionary {
                                
                                // CHECK IF PLACE EXISTS
                                if locDict.value(forKey: "title") != nil {

                                    // DECLARE CONSTANTS
                                    let fileName = locDict.value(forKey: "fileName") as? String
                                    let id = locDict.value(forKey: "id") as? String
                                    let information = locDict.value(forKey: "Information") as? String
                                    let lastModified = locDict.value(forKey: "lastModified") as? String
                                    let lat = locDict.value(forKey: "lat") as? String
                                    let long = locDict.value(forKey: "long") as? String
                                    let title = locDict.value(forKey: "title") as? String
                                    let yearOfWork = locDict.value(forKey: "yearOfWork") as? String
                                    let locationNotes = locDict.value(forKey: "locationNotes") as? String
                                    let artist = locDict.value(forKey: "artist") as? String
                                    var image: NSData? = nil
                                    
                                    // CHECK IF THE ARTWORK ALREADY EXISTS IN CORE DATA
                                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
                                    fetchRequest.predicate = NSPredicate(format: "id == %@", id!)
                                    
                                    do {
                                        let results = try self.context!.fetch(fetchRequest)
                                        let obj = results.first as? Places
                                        
                                        // IF THE ARTWORK EXISTS
                                        if (obj != nil) {
                                
                                            // CHECK IF THEY ARE IDENTICAL
                                            if(obj?.title == title! && obj?.yearOfWork == yearOfWork! && obj?.information == information! && obj?.lat == lat! && obj?.long == long! && obj?.locationNotes == locationNotes! && obj?.fileName == fileName! && obj?.lastModified == lastModified! && obj?.artist == artist!) {
                                                // IF THEY ARE THE SAME DO NOTHING
                                            } else {
                                                // CHECK EACH VALUE AND UPDATE IT IF ITS DIFFERENT
                                                if(obj?.title != title!) {
                                                    obj?.setValue(title!, forKey: "title")
                                                }
                                                if(obj?.yearOfWork != yearOfWork!) {
                                                    obj?.setValue(title!, forKey: "yearOfWork")
                                                }
                                                if(obj?.information != information!) {
                                                    obj?.setValue(information!, forKey: "information")
                                                }
                                                if(obj?.lat != lat!) {
                                                    obj?.setValue(lat!, forKey: "lat")
                                                }
                                                if(obj?.long != long!) {
                                                    obj?.setValue(long!, forKey: "long")
                                                }
                                                if(obj?.locationNotes != locationNotes!) {
                                                    obj?.setValue(locationNotes!, forKey: "locationNotes")
                                                }
                                                if(obj?.lastModified != lastModified!) {
                                                    obj?.setValue(lastModified!, forKey: "lastModified")
                                                }
                                                if(obj?.artist != artist!) {
                                                    obj?.setValue(artist!, forKey: "artist")
                                                }
                                                if(obj?.fileName != fileName!) {
                                                    obj?.setValue(fileName!, forKey: "fileName")
                                                    // CALL THE IMAGE THREAD AND UPON COMPLETION SET THE NEW IMAGE
                                                    self.downloadImage( fileName: fileName! ) { data in
                                                        if let data = data {
                                                            image = data
                                                            if image != nil {
                                                                obj?.setValue(image!, forKey: "image")
                                                            }
                                                        }
                                                    }
                                                }
                                                // SET THE UPDATE FLAG
                                                self.didChangeData = true
                                                
                                                // SAVE THE CURRENT CONTEXT
                                                do {
                                                    try self.context?.save()
                                                }   catch {
                                                    print("error : \(error)")
                                                }
                                            }
                                            
                                        } else {
                                            // NEW ARTWORKS CREATE NEW CORE DATA OBJECT AND SAVE IT
                                            self.didChangeData = true
                                            let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: self.context!) as! Places
                                            newPlace.fileName = locDict.value(forKey: "fileName") as? String
                                            newPlace.id = locDict.value(forKey: "id") as? String
                                            newPlace.information = locDict.value(forKey: "Information") as? String
                                            newPlace.lastModified = locDict.value(forKey: "lastModified") as? String
                                            newPlace.lat = locDict.value(forKey: "lat") as? String
                                            newPlace.long = locDict.value(forKey: "long") as? String
                                            newPlace.title = locDict.value(forKey: "title") as? String
                                            newPlace.yearOfWork = locDict.value(forKey: "yearOfWork") as? String
                                            newPlace.locationNotes = locDict.value(forKey: "locationNotes") as? String
                                            newPlace.artist = locDict.value(forKey: "artist") as? String
                                            // DOWNLOAD THE IMAGE
                                            self.downloadImage( fileName: fileName! ) { data in
                                                if let data = data {
                                                    image = data
                                                    if image != nil {
                                                        newPlace.image = image
                                                    }
                                                }
                                            }
                                            
                                            do {
                                                try self.context!.save()
                                            } catch {
                                                print("error : \(error)")
                                            }
                                            
                                        }
                                    } catch {
                                        let fetchError = error as NSError
                                        print("error fetching results")
                                        print(fetchError)
                                    }
                                    
                                } else {
                                    completion(false)
                                }
                            }
                        }
                    }
                }
            }
            // RETURN
            completion(true)
        }.resume()
    }
    
    // FUNCTION WILL DOWNLOAD IMAGE IN SEPERATE THREAD AND SIGNAL AND RETURN WHEN IMAGE DOWNLOADED
    func downloadImage(fileName: String, completion: @escaping (NSData?) -> ()) {
        
        let semaphore = DispatchSemaphore(value: 0)
        let filename = fileName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let imageURLString = self.imageURL + filename
        // CREATE THE IMAGE URL
        let imageURL = URL(string: imageURLString)
        let session = URLSession(configuration: .default)
        
        // DEFINE A DOWNLOAD TASK. THE DOWNLOAD TASK WILL DOWNLOAD THE CONTENTS OF THE URL AS A DATA OBJECT
        let downloadPicTask = session.dataTask(with: imageURL!) { (data, response, error) in
            // DOWNLOAD FINISHED
            if let e = error {
                print("Error downloading photo: \(e)")
                completion(nil)
            } else {
                // NO ERRORS FOUND
                if let res = response as? HTTPURLResponse {
                    print("Downloaded photo with response code \(res.statusCode)")
                    if let imageData = data {
                        let image = imageData as NSData
                        completion(image)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
                
            }
            // SIGNAL COMPLETION
            semaphore.signal()
        }
        downloadPicTask.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }

    // FUNCTION CALLED TO POPULATE MAP MARKERS USING PLACES GROUP ARRAY
    func populateMap() {
        // REMOVE ALL ANNOTATIONS ACTS AS MAP REFRESH
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        
        // NOW LOOP THROUGH THE GROUPS AND INSERT ONE MAP ANNOTATION FOR EACH GROUP
        for place in placesArrayGrouped {
            // THIS WILL HOLD ALL THE LOCATIONS PER GROUP
            let placeArr = place.arrayOfPlaces
    
            if let tempLat = placeArr[0].lat {
                if let tempLong = placeArr[0].long {
                    if let latitude = Double(tempLat) {
                        if let longitude = Double(tempLong) {
                            // CREATE THE COORDINATES USING THE LATITUDE AND LOGITUDE
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            // FOR GROUP WITH SINGLE ARTWORK
                            if(placeArr.count == 1) {
                                let pinAnnotation = PinAnnotation(title: placeArr[0].title!, locationDesc: placeArr[0].locationNotes!, coordinate: coordinate, places: placeArr)
                                self.map.addAnnotation(pinAnnotation)
                            } else {
                            // FOR GROUP WITH MULTIPLE ARTWORKS
                                let pinAnnotation = PinAnnotation(title: "Group", locationDesc: "Click the info button to view all artworks.", coordinate: coordinate, places: placeArr)
                                self.map.addAnnotation(pinAnnotation)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // FUNCTION WILL RETREIVE CACHED DATA
    func retreivePlacesAsArray()->Int {
        // CLEAR THE ARRAYS
        placesArray.removeAll()
        placesArrayGrouped.removeAll()
        
        // FETCH REQUEST FROM CORE DATA
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.returnsObjectsAsFaults = false
    
        do {
            // FETCH THE REQUEST
            let results = try self.context!.fetch(fetchRequest)
            
            // IF WE HAVE ANY RESULTS
            if (results.count > 0) {
                // POPULATE PLACES ARRAY
                placesArray = results as! [Places]
            } else {
                // NO PLACES
                print("no cached artworks")
            }
        } catch {
            let fetchError = error as NSError
            print("error fetching results")
            print(fetchError)
        }
        
        // IF THERE ARE LOCATIONS IN CORE DATA (CACHED)
        if(placesArray.count > 0) {
        
            // GET USERS CURRENT LATITUDE AND LONGITUDE
            let latitude = locationManager.location?.coordinate.latitude
            let longitude = locationManager.location?.coordinate.longitude
            // CREATE COORDINATES USING THEIR LATITUDE AND LONGITUDE
            let userLocation = CLLocation(latitude: latitude!,longitude: longitude!)
            
            // TEMPORARY STORED
            var tempArr = [Places]()
            var ignoreArr = [Places]()
            
            // LOOP THROUGH PLACES AND GROUP TOGETHER THOSE WITH SAME COORDINATES
            // THIS WILL INDICATE THAT THEY ARE IN THE SAME BUILDING
            for var i in (0..<placesArray.count) {
                tempArr.removeAll()
                let current = placesArray[i]
                
                if ignoreArr.contains(current) {
                    // IF WE HAVE ALREADY DEALT WITH THIS PLACE THEN GO TO NEXT LOOP
                    continue
                }
                // ADD IT TO IGNORE LIST AND TO THE TEMPORARY STORE
                ignoreArr.append(current)
                tempArr.append(current)
                
                // LOOP THROUGH THE REST OF LOCATIONS AND IF THEY ARE IN THE SAME LOCATION ADD THE
                // NEW LOCATION TO TEMP STORE AND IGNORE ARRAY
                for var j in ((i+1)..<placesArray.count) {
                    if(current.lat == placesArray[j].lat && current.long == placesArray[j].long) {
                        tempArr.append(placesArray[j])
                        ignoreArr.append(placesArray[j])
                    }
                    j += 1
                }
                
                if let tempLat = current.lat {
                    if let tempLong = current.long {
                        if let latitude = Double(tempLat) {
                            if let longitude = Double(tempLong) {
                                let location = CLLocation(latitude: latitude, longitude: longitude)
                                let distanceFromCurrentLoc = location.distance(from: userLocation)
                                // INSTANCIATE NEW GROUP OBJECT AND ADD IT TO THE ARRAY
                                let group = PlacesGrouped(distanceFromCurrent: distanceFromCurrentLoc, arrayOfPlaces: tempArr)
                                placesArrayGrouped.append(group)
                            }
                        }
                    }
                }
                
                // INCREMENT COUNTER
                i += 1
            }
            
            // SORT THE GROUPS ARRAY BY DISTANCE FROM OUR CURRENT LOCATION
            placesArrayGrouped = placesArrayGrouped.sorted(by: { $0.distanceFromCurrent < $1.distanceFromCurrent })
            
            // REFRESH THE TABLE FROM MAIN THREAD
            DispatchQueue.main.async {
                self.groupedArtworksTable.reloadData()
            }
            
        }
        // RETURN THE NUMBER OF GROUPS
        return placesArrayGrouped.count
    }
    
    // WILL DETERMINE WHICH SEGUE IS BEING CALLED
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "DetailedArtworkSegue") {
            // IF VIEWING ONE ARTWORK WE WILL PASS THE FIRST INDEX
            let newViewController = segue.destination as! DetailedArtwork
            newViewController.index = 0
            newViewController.places = sender as! [Places]
        } else if (segue.identifier == "SelectArtworkSegue") {
            // OTHERWISE PASS ALL THE LOCATIONS ON THE ANNOTATION FOR THE USER TO SELECT
            let newViewController = segue.destination as! SelectPlace
            newViewController.placesArr = sender as! [Places]
        }
    }
    
    // THIS FUNCTION WILL HANDLE THE MAP ANNOTATION ASWELL AS THE CALLOUT
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        if annotation is PinAnnotation {
            let identifier = "marker"
            var view: MKMarkerAnnotationView
            
            // TO IMPROVE PERFORMANCE
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKMarkerAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                // ATTACH AN INFO BUTTON
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            return view
        } else {
            return nil
        }
    }

    // THIS FUNCTION WILL HANDLE THE CLICK EVENT ON THE INFO BUTTON ON THE ANNOTATION POPUP
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! PinAnnotation
        
        // IF IT IS A SINGLE ARTWORK SIMPLY DISPLAY ITS DETAILED VIEW
        if location.places?.count == 1 {
            performSegue(withIdentifier: "DetailedArtworkSegue", sender: location.places!)
        } else {
            // ELSE DISPLAY TABLE WITH LIST OF ARTWORKS
            performSegue(withIdentifier: "SelectArtworkSegue", sender: location.places!)
        }
    
    }
    
}

// HERE WE WILL EXTEND THE CLASS FOR CLARITY AND SETUP THE METHODS FOR THE LOADING SCREEN AND THE ALERT MESSAGE
extension UIViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
    
    // ALERT FUNCTION
    func alert(message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
}


