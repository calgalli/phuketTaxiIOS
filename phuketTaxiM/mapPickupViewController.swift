//
//  mapPickupViewController.swift
//  phuketTaxiM
//
//  Created by cake on 5/23/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import QuartzCore


class mapPickupViewController: UIViewController,  MKMapViewDelegate {

    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var dropPinLabel: UILabel!
    //@IBOutlet weak var mapView: MKMapView!
    var placePicker: GMSPlacePicker?
    @IBOutlet weak var chooseBtn: UIButton!
    var tt : Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "action:")
        longPress.minimumPressDuration = 1.0
        dropPinLabel.layer.masksToBounds = true
        dropPinLabel.layer.cornerRadius = 20.0;
    
        //chooseBtn.userInteractionEnabled = false
        //self.chooseBtn.enabled = false
       
        
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(delegate.myCurrentLocation.latitude, longitude: delegate.myCurrentLocation.longitude, zoom: 13.0)
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.myLocationEnabled = true
        })
        
        self.mapView.settings.scrollGestures = true
        self.mapView.settings.zoomGestures = true
        
        self.mapView.camera = camera

   
    

        
        
        // Do any additional setup after loading the view.
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // firstLocationUpdate = true
        
        //println("**************************************  Google ***************************************")
        
        
        
    }


    func action(gestureRecognizer:UIGestureRecognizer) {
      
      
       // var locationP = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
      /*
        CLGeocoder().reverseGeocodeLocation(locationP, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                println("Reverse geocoder failed with error" + error.localizedDescription)
                return
            }
            
            
            if placemarks.count > 0 {
                let pm = placemarks[0] as! CLPlacemark
                
                
                var tempN: String = ""
                
                var addd = pm.addressDictionary["FormattedAddressLines"] as! [String]
                
                
                
                for val in addd {
                    tempN = tempN + val + ", "
                }
                
                
                if(self.delegate.setSourceAndDestinationRow == 0) {
                    println("From ......................")
                    
                    self.delegate.sourceLoc.name = "Pick up"
                    self.delegate.sourceLoc.address = tempN
                    self.delegate.sourceLoc.distance = 0
                    self.delegate.sourceLoc.location = locationP
                    
                    
                } else {
                    
                    println("To ......................")
                    
                    self.delegate.destinationLoc.name = "Pick up"
                    self.delegate.destinationLoc.address = tempN
                    self.delegate.destinationLoc.distance = 0
                    self.delegate.destinationLoc.location = locationP
                    
                    
                }

                
                
                println("E################################### Enter fireOnce ##############################")
                
               self.chooseBtn.userInteractionEnabled = true
                self.chooseBtn.enabled = true
                
                //println(pm)
                //TODO ====== Crash when no fields ===========
                //self.pickUpField.text = pm.thoroughfare+", "+pm.locality
                
                
                // dispatch_async(dispatch_get_main_queue()) { // 2
                
            
                // }
            } else {
                println("Problem with the data received from geocoder")
            }
        })
        
*/
        
    }
    
    @IBAction func chooseAction(sender: AnyObject) {
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
            } else {
                // self.nameLabel.text = "No place selected"
                // self.addressLabel.text = ""
            }
        })
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func searchAction(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("searchViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()

        
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
