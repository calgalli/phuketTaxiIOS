//
//  searchViewController.swift
//  phuketTaxiM
//
//  Created by cake on 5/1/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class searchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate  {

    
    struct locDetail {
        var name : String = String()
        var address : String = String()
        var location : CLLocation = CLLocation()
        var distance : Double = 0
        var placeID : String = String()
    }

    var locAll : [locDetail] = []
    
    
    var selectedRow : Int = 0
    
    var locItems : [String] = [String]()
    var names : [String] = [String]()
    var filteredTableData : [String] = ["Searching....."]
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    @IBOutlet weak var searchList: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
 
    
    var placesClient: GMSPlacesClient?
    var placePicker: GMSPlacePicker?
    
    var searchActive : Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.searchList.userInteractionEnabled = false
        searchBar.delegate = self
        
        var locT : locDetail = locDetail()
        locT.address = ""
        locT.name = ""
        
        locAll.append(locT)
        
        placesClient = GMSPlacesClient()
        
        // Reload the table
        //self.searchList.reloadData()
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
    
    //***************************** Table View handles **********************************
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //self.resultSearchController.active
        if (searchActive) {
            return self.locAll.count
        }
        else {
            return self.filteredTableData.count
        }
        
 
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        
        
        
        let cell = searchList.dequeueReusableCellWithIdentifier("searchResults", forIndexPath: indexPath) as? UITableViewCell
        
        if cell != nil {
        
        if (searchActive) {
            if locAll.count > 0 {
                cell!.detailTextLabel!.text = locAll[indexPath.row].name
                cell!.textLabel?.text = locAll[indexPath.row].address
            }
            return cell!
        } else {
            if filteredTableData.count > 0 {
                let taxiesID = filteredTableData[indexPath.row]

            
                //Retrieve data for the cell from the server
                cell!.detailTextLabel!.text = locAll[indexPath.row].name
                cell!.textLabel?.text = locAll[indexPath.row].address
            }
            
            return cell!
        }
        
        } else {
            return cell!
        }
        
        
 
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Publist MQTT message to the selected taxi
        var cell = searchList.dequeueReusableCellWithIdentifier("searchResults", forIndexPath: indexPath) 
        
        //self.selectedCell = cell
        
        let indexP = indexPath.row
        
        
        self.placesClient!.lookUpPlaceID(locAll[indexP].placeID, callback: { (place, error) -> Void in
            if error != nil {
                print("lookup place id query error: \(error!.localizedDescription)")
        
            } else {
        
                if let p = place {
                    let temp: CLLocation = CLLocation(latitude: p.coordinate.latitude, longitude: p.coordinate.longitude)
        
                   
                    
                    
                    if(self.delegate.setSourceAndDestinationRow == 0) {
                        print("From ......................")
                        
                        self.delegate.sourceLoc.name = p.name
                        self.delegate.sourceLoc.address = self.locAll[indexP].address
                        self.delegate.sourceLoc.distance = 0
                        self.delegate.sourceLoc.location = temp
                        
                        
                    } else {
                        
                        print("To ......................")
                        
                        self.delegate.destinationLoc.name = p.name
                        self.delegate.destinationLoc.address = self.locAll[indexP].address
                        self.delegate.destinationLoc.distance = 0
                        self.delegate.destinationLoc.location = temp
                        
                        
                    }
                    
                    self.delegate.globalFireOnce = false
        
                    //data.append(result)
                    
                    print("Place name \(p.name)")
                    print("Place address \(p.formattedAddress)")
                    print("Place placeID \(p.placeID)")
                    print("Place attributions \(p.attributions)")
                    
                  /*  let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewControllerWithIdentifier("ViewController") as! UIViewController
                    
                    self.delegate.window?.rootViewController = vc
                    self.delegate.window?.makeKeyAndVisible()*/
                    
                    self.performSegueWithIdentifier("backToViewController", sender: self)

                } else {
                    print("No place details for \(self.locAll[indexP].placeID)")
                }
        
            }
        })

        
        
        
    }
    
    func tableView(_tableView: UITableView,
        willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?{
            
            return indexPath;
    }
    
    
    //MARK: Search bar delegate 
    
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        
        var location = CLLocationCoordinate2D(
            latitude: 7.8900,
            longitude: 98.3983
        )
        
        var sLoc : locDetail = locDetail()
        
        let sydney = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        let northEast = CLLocationCoordinate2DMake(sydney.latitude + 1, sydney.longitude + 1)
        let southWest = CLLocationCoordinate2DMake(sydney.latitude - 1, sydney.longitude - 1)
        let bounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let filter = GMSAutocompleteFilter()
        filter.type = GMSPlacesAutocompleteTypeFilter.NoFilter
        self.locItems.removeAll(keepCapacity: false)
        self.locAll.removeAll(keepCapacity: false)
        
        var sText = searchBar.text
        
        if sText!.characters.count > 0 {
            self.searchList.userInteractionEnabled = true
            print("Searching for '\(sText)'")
            placesClient?.autocompleteQuery(sText!, bounds: bounds, filter: filter, callback: { (results, error) -> Void in
                if error != nil {
                    print("Autocomplete error \(error) for query '\(sText)'")
                    
                } else {
                    
                    print("Populating results for query '\(sText)'")
                    //var data : [GMSAutocompletePrediction] = [GMSAutocompletePrediction]()
                    for result in results! {
                        if let result = result as? GMSAutocompletePrediction {
                            
                            sLoc.placeID = result.placeID
                            sLoc.address = result.attributedFullText.string
                            
                            self.locAll.append(sLoc)
                        }
                        
                    }
                    self.searchList.reloadData()
                }
                
            })
        } else {
            // var data : [GMSAutocompletePrediction] = [GMSAutocompletePrediction]()
          //  if self.locAll.count > 0 {
          //      self.searchList.reloadData()
           // }
            //self.locAll.removeAll(keepCapacity: false)
            //self.filteredTableData.removeAll(keepCapacity: false)
            
            //self.searchList.reloadData()
            self.searchList.userInteractionEnabled = false
        }
    }
    
    
    @available(iOS 8.0, *)
    func presentSearchController(searchController: UISearchController){
        searchController.searchBar.showsCancelButton = false
    
    }
   
    
    
    //**************************** Sent data to taxiView ********************************************
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "searchToMain") {
            
            var indexP = self.searchList.indexPathForSelectedRow?.row
            
            let  destViewController : ViewController = segue.destinationViewController as! ViewController
            
        }
    }

    //MARK: Goto map search
    @IBAction func mapAction(sender: AnyObject) {
        searchBar.resignFirstResponder()
        
        let center = CLLocationCoordinate2DMake(self.delegate.myCurrentLocation.latitude, self.delegate.myCurrentLocation.longitude)
        let northEast = CLLocationCoordinate2DMake(center.latitude + 1, center.longitude + 1)
        let southWest = CLLocationCoordinate2DMake(center.latitude - 1, center.longitude - 1)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        placePicker = GMSPlacePicker(config: config)
        
        placePicker?.pickPlaceWithCallback({ (place: GMSPlace?, error: NSError?) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            
            
            if let place = place {
                // self.nameLabel.text = place.name
                // self.addressLabel.text = "\n".join(place.formattedAddress.componentsSeparatedByString(", "))
                
                let temp: CLLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                print("Fucking place 000000000000000")
                print(place)
                
                if(self.delegate.setSourceAndDestinationRow == 0) {
                    print("From ......................")
                    
                    self.delegate.sourceLoc.name = place.name
                    if place.formattedAddress != nil {
                        self.delegate.sourceLoc.address = place.formattedAddress
                    }
                    self.delegate.sourceLoc.distance = 0
                    self.delegate.sourceLoc.location = temp
                    
                    
                } else {
                    
                    print("To ......................")
                    
                    self.delegate.destinationLoc.name = place.name
                    if place.formattedAddress != nil {
                        self.delegate.destinationLoc.address = place.formattedAddress
                    }
                    self.delegate.destinationLoc.distance = 0
                    self.delegate.destinationLoc.location = temp
                    
                    
                }

                self.performSegueWithIdentifier("backToViewController", sender: self)
                

                
            } else {
                // self.nameLabel.text = "No place selected"
                // self.addressLabel.text = ""
            }
        })

    
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
