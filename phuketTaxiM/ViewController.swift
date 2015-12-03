//
//  ViewController.swift
//  phuketTaxiM
//
//  Created by cake on 3/15/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation



class ViewController: UIViewController, CLLocationManagerDelegate,  UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate,  NSURLSessionDelegate, NSURLSessionTaskDelegate  {

    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var reuqestTaxiButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var chooseTaxiView: UIView!
    @IBOutlet weak var callTaxiButton: UIButton!
    @IBOutlet weak var avartarImage: UIImageView!
    //@IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var taxiTableView: UITableView!
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var callTaxi: UIButton!
    @IBOutlet weak var requestButton: UIButton!
    
    @IBOutlet weak var distanceToDestinationLabel: UILabel!
    
    var myLocation = CLLocationCoordinate2D(
        latitude: 0,
        longitude: 0
    )
    
    var fireOnce : Bool = true
    
     
    var locationManager: CLLocationManager?
    
    
    
    var distanceFromDestination : String = ""
    
    
    var tableMenu : [String] = ["From", "To"]
    
    var allTaxies:Array<String> = []
    var selectedTaxiId : String = ""
    
    var timer = NSTimer()
    var startTime = NSTimeInterval()
    
    var countDown : Int = 60
    var tableSelectionEnable : Bool = true
    
    var selectedCell : customTableViewCell = customTableViewCell()
    
    var from : String = ""
    var goto : String = ""
    var note : String = ""
    var distanceTo : String = ""
    
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        onTheWay = false
        print("E################################### View didLoad ##############################")
        
        locationManager = CLLocationManager()
        locationManager?.delegate  = self;
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        
        //update when the different distance is greater than 10 meters
        locationManager?.distanceFilter = 50.0;
        
        if CLLocationManager.locationServicesEnabled() {
            if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("8") == true){
                
                if (locationManager?.respondsToSelector("requestWhenInUseAuthorization") != nil) {
                    if #available(iOS 8.0, *) {
                        locationManager?.requestWhenInUseAuthorization()
                    } else {
                        // Fallback on earlier versions
                    }
                    //locationManager?.startUpdatingLocation()
                }
                //else {
                //locationManager?.startUpdatingLocation()
                //}
            }
        }
        
        locationManager?.startUpdatingLocation()

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnReceiveMessageNotification", name: mySpecialNotificationKey, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTaxilocationOnTheMap", name: updateLocationKey, object: nil)
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnTaxiResponse", name: taxiResponseNotificationKey, object: nil)
        
  
        
        /*cancelButton.userInteractionEnabled = false
        dispatch_async(dispatch_get_main_queue()) {
            self.cancelButton.alpha = 0.5
        }
        */
        
        // Do any additional setup after loading the view, typically from a nib.
        
        
 /*       let possibleOldImagePath = NSUserDefaults.standardUserDefaults().objectForKey("path") as! String?
        if let oldImagePath = possibleOldImagePath {
            let oldFullPath = self.documentsPathForFileName(oldImagePath)
            let oldImageData = NSData(contentsOfFile: oldFullPath)
            // here is your saved image:
            //let oldImage = UIImage(data: oldImageData!)
            
            avartarImage.image = UIImage(data: oldImageData!)
            avartarImage.layer.cornerRadius = 8.0
            avartarImage.clipsToBounds = true
            
        }*/
        
        
       /* avartarImage.autoresizingMask =
            ( UIViewAutoresizing.FlexibleBottomMargin
                | UIViewAutoresizing.FlexibleHeight
                | UIViewAutoresizing.FlexibleLeftMargin
                | UIViewAutoresizing.FlexibleRightMargin
                | UIViewAutoresizing.FlexibleTopMargin
                | UIViewAutoresizing.FlexibleWidth );*/
        
              //avartarImage.contentMode = UIViewContentMode.ScaleAspectFill
        
       
        avartarImage.image = self.delegate.userImage
        avartarImage.contentMode = UIViewContentMode.ScaleAspectFill
        avartarImage.layer.cornerRadius = 25
        avartarImage.clipsToBounds = true
        

        
        
        self.delegate.locFromTo["From"] = self.delegate.sourceLoc
        self.delegate.locFromTo["To"] = self.delegate.destinationLoc
        
        chooseTaxiView.hidden = true
        chooseTaxiView.userInteractionEnabled = false
        backButton.hidden = true
        backButton.userInteractionEnabled = false
        
        
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(delegate.myCurrentLocation.latitude, longitude: delegate.myCurrentLocation.longitude, zoom: self.delegate.zoomLevel )
        //var mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
     
       // mapView.settings.myLocationButton = true
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        mapView.addObserver(self, forKeyPath: "camera.zoom", options: .New, context: nil)
        
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.myLocationEnabled = true
        })
        
        self.mapView.settings.scrollGestures = true
        self.mapView.settings.zoomGestures = true
        
        self.mapView.camera = camera
        
     //   self.mapView.clear()
        
        dispatch_async(dispatch_get_main_queue()) {
        if self.delegate.destinationLoc.name == "" {
            self.reuqestTaxiButton.userInteractionEnabled = false
            self.reuqestTaxiButton.enabled = false
            self.reuqestTaxiButton.hidden = true
        } else {
            self.reuqestTaxiButton.userInteractionEnabled = true
            self.reuqestTaxiButton.enabled = true
            self.reuqestTaxiButton.hidden = false
        }
        }
        
        
        
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // firstLocationUpdate = true
        
        
        if keyPath == "camera.zoom" {
            self.delegate.zoomLevel = self.mapView.camera.zoom;
            
        } else {

        
        //println("**************************************  Google ***************************************")
        let location = change?[NSKeyValueChangeNewKey] as! CLLocation
       
            let clocation = CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            self.delegate.myCurrentLocation = clocation
            
            
        self.delegate.myCurrentLocation.latitude = location.coordinate.latitude
        self.delegate.myCurrentLocation.longitude = location.coordinate.longitude

        updateMapAnnotations()
        
        
        if self.delegate.globalFireOnce == true {
            
            
            mapView.camera = GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: self.mapView.camera.zoom)
            
            var currentPosition = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            
            
            var maxDistance : Double = 0.0
            
            
            for (key, x) in self.delegate.listTaxi {
                var position = CLLocationCoordinate2DMake(x.lat, x.lon)
                
                var dd = GMSGeometryDistance(position, currentPosition)
                if dd > maxDistance {
                    maxDistance = dd;
                }
                
                
                
            } // End block
            
            //println(self.mapView.annotations)
            //println(annotationList)
            
            print("max distance = \(maxDistance)")
            
            
            let bounds = translateCoordinate(currentPosition, metersLat: maxDistance*1.1 , metersLong: maxDistance*1.1)
            
            
            
            let update = GMSCameraUpdate.fitBounds(bounds, withPadding: 15.0)    // padding set to 5.0
            
            mapView.moveCamera(update)

            self.delegate.zoomLevel = self.mapView.camera.zoom;

            
            
            let geocoder = GMSGeocoder()
            
            // 2
            geocoder.reverseGeocodeCoordinate(location.coordinate) { response , error in
                if let address = response?.firstResult() {
                    
                    // 3
                    let lines = address.lines as! [String]
                    //self.addressLabel.text = join("\n", lines)
                    
                    let tempN = lines.joinWithSeparator("\n")
                    print(tempN)
                    self.tableMenu[0] = self.tableMenu[0] + ":" + tempN
                    
                    print("E################################### Enter fireOnce ##############################")
                    
                    self.delegate.locFromTo["From"]?.address = tempN
                    
                    self.delegate.sourceLoc.address = tempN
                    
                    self.delegate.locFromTo["From"]?.name = "Current location"
                    
                    self.delegate.sourceLoc.name = "Current location"
                    self.delegate.sourceLoc.location = location
                    
                    //println(pm)
                    //TODO ====== Crash when no fields ===========
                    //self.pickUpField.text = pm.thoroughfare+", "+pm.locality
                    
                    
                    // dispatch_async(dispatch_get_main_queue()) { // 2
                    
                    self.menuTableView.reloadData()
                    self.delegate.globalFireOnce  = false
                }
                
                // 4
                UIView.animateWithDuration(0.25) {
                    self.view.layoutIfNeeded()
                }
            }
       }
        }
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    
    
    
    
    func updateMapAnnotations(){
        
      
        
        //println("Notify from messageing")
        
    
        
        self.mapView.clear()
        
        
        let currentPosition = CLLocationCoordinate2DMake(self.delegate.myCurrentLocation.latitude, self.delegate.myCurrentLocation.longitude)
        let marker = GMSMarker(position: currentPosition)
        marker.map = self.mapView
        marker.icon = UIImage(named: "custommerIcon.png")
        
     
        
        for (key, x) in self.delegate.listTaxi {
           // println(NSString(format:"%@ %f %f", x.id, x.lat, x.lon))
            let position = CLLocationCoordinate2DMake(x.lat, x.lon)
            let marker = GMSMarker(position: position)
            marker.map = mapView
            marker.icon = UIImage(named: "taxiIcon.png")
            
           
            
        } // End block
        
        //println(self.mapView.annotations)
        //println(annotationList)
        
        
    
        
      
        
    }
    
    func translateCoordinate(coordinate: CLLocationCoordinate2D, metersLat: Double,metersLong: Double) -> (GMSCoordinateBounds) {
        var tempCoord = coordinate
        var tempCoord2 = coordinate
        
        let tempRegion = MKCoordinateRegionMakeWithDistance(coordinate, metersLat, metersLong)
        let tempSpan = tempRegion.span
        
        tempCoord.latitude = coordinate.latitude + tempSpan.latitudeDelta
        tempCoord.longitude = coordinate.longitude + tempSpan.longitudeDelta
        
        tempCoord2.latitude = coordinate.latitude - tempSpan.latitudeDelta
        tempCoord2.longitude = coordinate.longitude - tempSpan.longitudeDelta
        
        let bounds = GMSCoordinateBounds(coordinate: tempCoord2 , coordinate: tempCoord)
        
        
        return bounds
    }
    
    //MARK: Nofification center callback
    
    func updateTaxilocationOnTheMap(){

        updateMapAnnotations()

    }
    
    
    func actOnTaxiResponse (){
        print("********************************* Taxi response ******************************")
        print(delegate.taxiResponsePayload)
        
        let data: NSData = delegate.taxiResponsePayload.dataUsingEncoding(NSUTF8StringEncoding)!
        var error: NSError?
        
        // convert NSData to 'AnyObject'
        
        
        let json = JSON(data: data)
        
        
        
        if(json["id"].string! == selectedTaxiId){
            
            if(json["type"] == "ack"){
                if(json["value"] == "REJECT"){
                    self.tableSelectionEnable = true
                    self.selectedCell.userInteractionEnabled = true
                    self.countDown = 60
                    //self.selectedCell.selectionStyle = UITableViewCellSelectionStyle.Default
                    let removeCustomer : String = "removeContomer/" + self.selectedTaxiId
                    delegate.mqttManager!.sendMessage(removeCustomer, message: "id"+userID)
                    
                    delegate.listTaxi.removeValueForKey(self.selectedTaxiId)
                    allTaxies.removeAll(keepCapacity: false)
                    
                    
                    for (key, value)  in delegate.listTaxi {
                        self.allTaxies.append(value.id)
                    }
                    
                    print("number of taxies: ")
                    print(delegate.listTaxi.count)
                    
                    timer.invalidate()
                    
                    dispatch_async(dispatch_get_main_queue()) { // 2
                        self.taxiTableView.reloadData()
                        
                    }
                    print("Taxi said Reject")
                    delegate.mqttManager!.unsubscribeTopic(gTaxiResponseTopic+"/" + selectedTaxiId)
                    selectedTaxiTopic = ""
                    dispatch_async(dispatch_get_main_queue()) {
                        self.backButton.hidden = false
                        self.backButton.userInteractionEnabled = true
                    }
                    
                    
                } else {
                    timer.invalidate()
                    print("Taxi said OK")
                    
                    
                    //======== Dotnt forget to unsubscript taxi topic after transaction is completed ====================
                    
                    self.delegate.selectedTaxiId = json["id"].stringValue
                    self.delegate.selectedTaxiLat = json["lat"].doubleValue
                    self.delegate.selectedTaxiLon = json["lon"].doubleValue
                    
                    var data = Dictionary<String, String>()
                    data["id"] = "id" + userID
                    data["type"] = "costumerLocation"
                    
                    //data["lat"] = String(format:"%f",self.delegate.myCurrentLocation.latitude)
                    //data["lon"] = String(format:"%f",self.delegate.myCurrentLocation.longitude)
                    
                    data["lat"] = String(format:"%f", self.delegate.sourceLoc.location.coordinate.latitude)
                    data["lon"] = String(format:"%f", self.delegate.sourceLoc.location.coordinate.longitude)
                    
                    let jsonObj = JSON(data)
                    
                    print(jsonObj)
                    
                    let topic1 : String = gCustomerResponseTopic+"/id"+userID
                    
                   // delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
                    delegate.mqttManager!.sendMessageSpecial(topic1, message: "\(jsonObj)")
                    delegate.removeFromTaxi()
                    dispatch_async(dispatch_get_main_queue()) {
                        self.performSegueWithIdentifier("mainToOnTheWay", sender: self)
                    }
                    
                   /* let storyboard1 = UIStoryboard(name: "Main", bundle: nil)
                    //let vc : AnyObject! = storyboard.instantiateViewControllerWithIdentifier("onTheView")
                    let vc = storyboard1.instantiateViewControllerWithIdentifier("onTheView") as! onthewayViewController
                    
                    self.delegate.window?.rootViewController = vc
                    self.delegate.window?.makeKeyAndVisible()
                    //showViewController(vc as! UIViewController, sender: vc)
                    //dispatch_async(dispatch_get_main_queue()) {
                        
                    //}*/
                }
            }
            
        }
        
        
    }

    
    func actOnReceiveMessageNotification() {
        
        updateMapAnnotations()
        
        if( requestButton.userInteractionEnabled == false){
            
            requestButton.userInteractionEnabled = true
            
        }
        
        dispatch_async(dispatch_get_main_queue()) { // 2
            
            self.requestButton.alpha = 1.0
        }
       // println(mapView.annotations)
        
        
       // println("New message")
    }
    
    //MARK: Button handlers
    
    @IBAction func backAction(sender: AnyObject) {
        
        allTaxies.removeAll(keepCapacity: false)
        dispatch_async(dispatch_get_main_queue()) {
            self.backButton.hidden = true
            self.backButton.userInteractionEnabled = false
            
            self.chooseTaxiView.hidden = true
            self.chooseTaxiView.userInteractionEnabled = false
            self.distanceToDestinationLabel.text =  self.distanceTo
            self.menuTableView.userInteractionEnabled = true
          
            
        }

        
    }
    
    @IBAction func profileAction(sender: AnyObject) {
        performSegueWithIdentifier("viewcontrollerToProfile", sender: nil)
        
    }
    
    
    @IBAction func request(sender: UIButton) {
        
       
        
        from = self.delegate.sourceLoc.name
        note = " "
        goto = self.delegate.destinationLoc.name
        
        
        var fromLoc : CLLocation = self.delegate.sourceLoc.location
        var toLoc : CLLocation = self.delegate.destinationLoc.location
        
        
        var urlString = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(fromLoc.coordinate.latitude),\(fromLoc.coordinate.longitude)&destinations=\(toLoc.coordinate.latitude),\(toLoc.coordinate.longitude)&mode=driving&key=\(googleWebAPIkey)"
        //AIzaSyCkkgvHEbB9Q0k4ICWzZBJNd_wV5GEYNzc
        
        
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        print(urlString)
        
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        var ETA = ""
        var dd = ""
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var placesTask = session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
            print("inside.")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            let json = JSON(data: data!)
            if json["rows"].count > 0 {
                if json["rows"][0]["elements"].count > 0 {
                    ETA = json["rows"][0]["elements"][0]["duration"]["text"].string!
                    dd = json["rows"][0]["elements"][0]["distance"]["text"].string!
                    
                    
                    self.distanceTo = "Distance : " + dd + ",  ETA : " + ETA
                    
                    //destViewController.myCurrentLocation = myLocation
                    
                    //TO DO : Sort taxi by rating before sending to display
                    
                    for (key, value)  in self.delegate.listTaxi {
                        self.allTaxies.append(value.id)
                    }
                    // pass data to next view
                    
                    
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.backButton.hidden = false
                        self.backButton.userInteractionEnabled = true
                        self.requestButton.hidden = true
                        self.requestButton.userInteractionEnabled = false
                        //==   self.mapView.hidden = true
                        //==   self.mapView.userInteractionEnabled = false
                        // self.cancelButton.alpha = 1.0
                        //  self.requestView.hidden = false
                        self.chooseTaxiView.hidden = false
                        self.chooseTaxiView.userInteractionEnabled = true
                        self.distanceToDestinationLabel.text =  self.distanceTo
                        self.menuTableView.userInteractionEnabled = false
                        self.taxiTableView.reloadData()
                        
                    }

                    
                    
                    print(json)
                }
            }
            
            /*if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? NSDictionary {
                println(json["rows"])
            }*/
            
        }
        
        placesTask.resume()
        
    }
    
    
    @IBAction func cancelRequest(sender: UIButton) {
        self.delegate.removeFromTaxi()
        
        //cancelButton.userInteractionEnabled = false
        requestButton.userInteractionEnabled = true
        dispatch_async(dispatch_get_main_queue()) {
           // self.cancelButton.alpha = 0.5
            self.requestButton.alpha = 1.0
        }
        
    }
    
    //MARK: Handle location update 
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //manager.stopUpdatingLocation()
        let location = locations[0] 
        //let geoCoder = CLGeocoder()
        
        let coorString = String(format: "%f:%f", location.coordinate.latitude, location.coordinate.longitude)
        
        var jsonLoc : String = String(format: "{\"")
        
        jsonLoc += "id" + userID
        jsonLoc += "\":{\"lat\":"
        jsonLoc += String(format: "\"%f\"", location.coordinate.latitude)
        jsonLoc += ","
        jsonLoc += "\"lon\":"
        jsonLoc += String(format: "\"%f\"", location.coordinate.longitude)
        jsonLoc += "}}"
        //let pubTopic : String = "userLocation."+userId
        // amq.publishMessage(pubTopic, message : jsonLoc)
        
        let clocation = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        
        myLocation = clocation
        
        if fireOnce {
         
           // self.delegate.mqttManager!.sendMessage("request/id"+userID, message: "id"+userID)
            fireOnce = false
        }

        
        
        
        self.delegate.myCurrentLocation = myLocation
        
 
        
        
    }
    
    //MARK: Segue Sent data to taxiView
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
       /* if (segue.identifier == "toListTaxi") {
           let  destViewController : requestFormViewController = segue.destinationViewController as! requestFormViewController
            destViewController.from = self.delegate.sourceLoc.name
            destViewController.note = " "
            destViewController.goto = self.delegate.destinationLoc.name
            
           // println(self.delegate.sourceLoc.location)
           // println(self.delegate.destinationLoc.location)
            
            var km  = self.delegate.sourceLoc.location.distanceFromLocation(self.delegate.destinationLoc.location)/1000.0
            
            var b:String = String(format:"%4.2f", km)
            
            destViewController.distanceTo = "Distance to destination : " + b + "Km"
            
            //destViewController.myCurrentLocation = myLocation
            
            //TO DO : Sort taxi by rating before sending to display
            
            for (key, value)  in delegate.listTaxi {
                destViewController.allTaxies.append(value.id)
            }
            // pass data to next view
            println("Segue  :  From main view")
        }*/
    }
    //*************************** get stored images path  ******************************************
    
    func documentsPathForFileName(name: String) -> String {
       /* let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true);
        let path = paths[0] ;
        let fullPath = path.stringByAppendingPathComponent(name)*/
        
        
        let manager = NSFileManager.defaultManager()
        let URLs = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let fullPath = URLs[0].URLByAppendingPathComponent(name)

        
        return fullPath.path!
    }
    
    //MARK: Table View handles
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == menuTableView){
            return tableMenu.count
        } else {
            return allTaxies.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if(tableView == menuTableView){
            var cell = menuTableView.dequeueReusableCellWithIdentifier("menuItems", forIndexPath: indexPath) 
            
            let taxiesID = tableMenu[indexPath.row]
            
            //Retrieve data for the cell from the server
            
            var add : String
            var nnn : String
            if(indexPath.row  == 0){
                add = self.delegate.sourceLoc.address // self.locFromTo["From"]!.address
                nnn = "From : " + self.delegate.sourceLoc.name //self.locFromTo["From"]!.name
            } else {
                add = self.delegate.destinationLoc.address   //locFromTo["To"]!.address
                nnn = "To : " + self.delegate.destinationLoc.name //locFromTo["To"]!.name
            }
            
            
            cell.textLabel!.text = nnn
            
            print("*********************** FROM TO *************************")
            print(add)
            cell.detailTextLabel!.text = "Address : " + add
            
            
            
            return cell
        } else {
            
            var cell = taxiTableView.dequeueReusableCellWithIdentifier("taxiListView", forIndexPath: indexPath) as! customTableViewCell
            var err: NSError?
            let taxiesID = allTaxies[indexPath.row]
            var imageFileName : String = ""
            
            //Retrieve data for the cell from the server
            
            
            
            var t_lat : CLLocationDegrees = self.delegate.listTaxi[taxiesID]!.lat
            var t_lon : CLLocationDegrees = self.delegate.listTaxi[taxiesID]!.lon
            
            //      self.delegate.listTaxi[taxiesID]?.lat as! CLLocationDegrees
            
            var mll: CLLocation = CLLocation(latitude: self.delegate.myCurrentLocation.latitude, longitude: self.delegate.myCurrentLocation.longitude)
            
            var tcl: CLLocation = CLLocation(latitude: t_lat, longitude: t_lon)
            
            var km : CLLocationDistance = mll.distanceFromLocation(tcl)/1000.0
            
            var allParams = Dictionary<String, String>()
            allParams["id"] = taxiesID
            let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/getDriverData");
            let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
            request1.HTTPMethod = "POST";
            
            do {
                request1.HTTPBody = try NSJSONSerialization.dataWithJSONObject(allParams, options: [])
            } catch var error as NSError {
                err = error
                request1.HTTPBody = nil
            }
            request1.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request1.addValue("application/json", forHTTPHeaderField: "Accept")
            
            
            var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
            
            let task = session.dataTaskWithRequest(request1){
                data, response, error in
                
                if error != nil
                {
                    print("error=\(error)")
                    return
                }
                
                
                
                // Print out response body
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("******************************** Response from Server **********************")
                // You can print out response object
                //println("response = \(response)")
                print("responseString = \(responseString)")
                
                let json = JSON(data: data!)
                
                if(json.count > 0){
                    
                    
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.rating.text = String(format:"Distance %4.2f km", km)
                        cell.counter.text = "60"
                        cell.driverRegistrationNumber.text = json[0]["licensePlateNumber"].string!
                        cell.name.text = json[0]["firstName"].string! +  " " + json[0]["lastname"].string!
                        cell.carType.text = json[0]["carModel"].string!
                        
                        
                        
                    }

                    
                    
                    //cell.driverImage = UIImageView(frame:CGRectMake(0, 0, 100, 70))
                    
                    /*   cell.driverImage.image = self.imageResize(UIImage(named: "tom.jpg")!,sizeChange: cell.driverImage.intrinsicContentSize())
                    cell.driverImage.contentMode  = UIViewContentMode.ScaleAspectFill;
                    
                    cell.driverImage.autoresizingMask =
                    ( UIViewAutoresizing.FlexibleBottomMargin
                    | UIViewAutoresizing.FlexibleHeight
                    | UIViewAutoresizing.FlexibleLeftMargin
                    | UIViewAutoresizing.FlexibleRightMargin
                    | UIViewAutoresizing.FlexibleTopMargin
                    | UIViewAutoresizing.FlexibleWidth );*/
                    
                    
                    imageFileName = json[0]["idNumber"].string! + ".png"
                    
                    //filename = imageFileName
                    print("filename = \(imageFileName)")
                    
                    
                    print("filename = \(imageFileName)")
                    
                    let myUrl = NSURL(string: "https://"+mainHost + ":1880/getDriverImage");
                    let request2 = NSMutableURLRequest(URL:myUrl!);
                    request2.HTTPMethod = "POST";
                    
                    // Compose a query string
                    
                    
                    
                    
                    
                    var params = ["filename": imageFileName] as Dictionary<String, String>
                    
                    
                    do {
                        request2.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
                    } catch var error as NSError {
                        err = error
                        request2.HTTPBody = nil
                    } catch {
                        fatalError()
                    }
                    request2.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request2.addValue("application/json", forHTTPHeaderField: "Accept")
                    
                    var configuration2 = NSURLSessionConfiguration.defaultSessionConfiguration()
                    var session2 = NSURLSession(configuration: configuration2, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
                    
                    let task2 = session2.dataTaskWithRequest(request2){
                        data, response, error in
                        
                        if error != nil
                        {
                            print("error=\(error)")
                            return
                        }
                        
                        // You can print out response object
                        //println("response = \(response)")
                        
                        // Print out response body
                        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)! as String
                        //println("responseString = \(responseString)")
                       
                        let decodedData = NSData(base64EncodedString: responseString, options: NSDataBase64DecodingOptions(rawValue: 0))
                        
                        var decodedimage = UIImage(data: decodedData!)
                        
                        //println(decodedimage)
                        //yourImageView.image = decodedimage as UIImage
                        dispatch_async(dispatch_get_main_queue()) {
                            //cell.driverImage = UIImageView(frame:CGRectMake(0, 0, 100, 70))
                            cell.driverImage.image = decodedimage
                            
                            //cell.driverImage.image = self.imageResize(decodedimage!, sizeChange: cell.driverImage.intrinsicContentSize())
                             print("Done decoded")
                            cell.driverImage.contentMode  = UIViewContentMode.ScaleAspectFill;
                            
                            cell.driverImage.autoresizingMask =
                                ( [UIViewAutoresizing.FlexibleBottomMargin, UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleLeftMargin, UIViewAutoresizing.FlexibleRightMargin, UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleWidth] );
                            
                            cell.driverImage.layer.cornerRadius = 8.0
                            cell.driverImage.clipsToBounds = true
                            
                        }
                        
                        
                        
                    }
                    
                    task2.resume()
                    
                    
                }
            }
            
          
            task.resume()
            
           return cell

            
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView == menuTableView){
            //Publist MQTT message to the selected taxi
            var cell = menuTableView.dequeueReusableCellWithIdentifier("menuItems", forIndexPath: indexPath) 
            self.delegate.setSourceAndDestinationRow = indexPath.row
            //self.selectedCell = cell
        }else{
            var imageFileName : String = ""
            var err:NSError?
            //Publist MQTT message to the selected taxi
            let cell = taxiTableView.cellForRowAtIndexPath(indexPath) as! customTableViewCell

            
            self.selectedCell = cell
            
            let taxiesID = allTaxies[indexPath.row]
            let topic: String = "cli/" + taxiesID
            print(topic)
            
            //"cli/" + "id"+taxiId
            
            
            var mm = Dictionary<String, String>()
            //var json2 : JSON
            
            let idString =  "id"+userID
            
            mm["id"] = idString
            mm["From"] = from
            mm["fromAddress"] = self.delegate.sourceLoc.address
            mm["to"] = goto
            mm["toAddress"] = self.delegate.destinationLoc.address
            mm["note"] = note
            // mm["lat"] = String(format:"%f", delegate.myCurrentLocation.latitude)
            // mm["lon"] = String(format:"%f", delegate.myCurrentLocation.longitude)
            
            mm["lat"] = String(format:"%f", self.delegate.sourceLoc.location.coordinate.latitude)
            mm["lon"] = String(format:"%f", self.delegate.sourceLoc.location.coordinate.longitude)
            let now = NSDate()
            
            mm["currentTime"] = String(format:"%f", now.timeIntervalSince1970)
            
            
            mm["nationality"] = self.delegate.nationality
            print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&")
            print(self.delegate.nationality)
            mm["requestFlag"] = String(format:"%d", 1)
            
            
            let jsonData = try? NSJSONSerialization.dataWithJSONObject(mm,
                options: [])
            
            let jsonString =  NSString(data: jsonData!, encoding:NSUTF8StringEncoding)
            
            self.delegate.mqttManager!.sendMessage(topic, message: jsonString as String!)
            
           // println("topic = \(topic)")
           // println("data = \(jsonString as String!)")
            
            self.selectedTaxiId = taxiesID
            self.delegate.selectedTaxiId = self.selectedTaxiId
      
            
            //cell.name?.text = String(format:"Taxi %d", indexPath.row)
            
            //cell.counter?.text = "60"
            
            let t_lat : CLLocationDegrees = self.delegate.listTaxi[taxiesID]!.lat
            let t_lon : CLLocationDegrees = self.delegate.listTaxi[taxiesID]!.lon
            
            
            let mll: CLLocation = CLLocation(latitude: self.delegate.myCurrentLocation.latitude, longitude: self.delegate.myCurrentLocation.longitude)
            
            let tcl: CLLocation = CLLocation(latitude: t_lat, longitude: t_lon)
            
            var km : CLLocationDistance = mll.distanceFromLocation(tcl)/1000.0
            
            dispatch_async(dispatch_get_main_queue()) {
                self.backButton.hidden = true
                self.backButton.userInteractionEnabled = false
            }
            
            self.tableSelectionEnable = false
            cell.userInteractionEnabled = false
            
             //============= Open MQTT channel to the selected Taxi ===========================
            delegate.mqttManager!.subscribeToTopic(gTaxiResponseTopic+"/" + selectedTaxiId)
            selectedTaxiTopic = gTaxiResponseTopic+"/" + selectedTaxiId
            //============= Send lat lon location to the selected Taxi
            
            
            
           timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)
            
        }
        
    }

    
    func tableView(_tableView: UITableView,
        willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?{
            if(_tableView == menuTableView){
                    
                return indexPath;
            } else {
                // rows in section 0 should not be selectable
                if(self.tableSelectionEnable == false) {
                    if ( indexPath.section == 0 ) {
                        return nil;
                    }
                }
                return indexPath;
                
            }

            
            
    }

    
    
    
    //MARK: Mapview delegate 
   func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
     
        
        //if !(annotation is CustomPointAnnotation) {
        //    return nil
        //}
        
        print("Map view delegate is called ***************************")

        
        //if !(annotation is MKPointAnnotation){
        //    return nil
        //}
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            let reuseId = "test"
            
            var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            if anView == nil {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                //anView.canShowCallout = true
                anView!.image = UIImage(named:"custommerIcon.png")
            }
            else {
                anView!.annotation = annotation
            }
            
            //Set annotation-specific properties **AFTER**
            //the view is dequeued or created...
            
            //let cpa = annotation as! CustomPointAnnotation
            //anView.image = UIImage(named:cpa.imageName)
            
            
            
            print("Map view delegate is called end ***************************")
            
            return anView

           
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //anView.canShowCallout = true
            anView!.image = UIImage(named:"taxiIcon.png")
        }
        else {
            anView!.annotation = annotation
        }
        
        //Set annotation-specific properties **AFTER**
        //the view is dequeued or created...
        
        //let cpa = annotation as! CustomPointAnnotation
        //anView.image = UIImage(named:cpa.imageName)
        
        
        
        print("Map view delegate is called end ***************************")
        
        return anView
    }
    
    
    
    //MARK: text field delegate
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    
    
    func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(version: NSString) -> Bool {
        return UIDevice.currentDevice().systemVersion.compare(version as String,
            options: NSStringCompareOptions.NumericSearch) != NSComparisonResult.OrderedAscending
    }

    //MARK: timer stuff
    func updateTime() {
        
        self.countDown--
        
        if(self.countDown > 0){
            
            
            self.selectedCell.counter.text = "\(countDown)"
            
            
        } else {
            self.tableSelectionEnable = true
            self.selectedCell.userInteractionEnabled = true
            self.countDown = 60
            //self.selectedCell.selectionStyle = UITableViewCellSelectionStyle.Default
            let removeCustomer : String = "removeContomer/" + self.selectedTaxiId
            delegate.mqttManager!.sendMessage(removeCustomer, message: "id"+userID)
            
            delegate.listTaxi.removeValueForKey(self.selectedTaxiId)
            allTaxies.removeAll(keepCapacity: false)
            
            
            for (key, value)  in delegate.listTaxi {
                self.allTaxies.append(value.id)
            }
            
            print("number of taxies: ")
            print(delegate.listTaxi.count)
            
            timer.invalidate()
            
            dispatch_async(dispatch_get_main_queue()) { // 2
                self.taxiTableView.reloadData()
                self.backButton.hidden = false
                self.backButton.userInteractionEnabled = true
                
            }
            
           
            
            delegate.mqttManager!.unsubscribeTopic(gTaxiResponseTopic+"/" + selectedTaxiId)
            
            selectedTaxiTopic = ""
            
        }
        
        
        
        
        //   displayTimeLabel.text = "\(strMinutes):\(strSeconds):\(strFraction)"
    }

    
    // MARK: URL session delegate
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler:(NSURLSessionAuthChallengeDisposition,
        NSURLCredential?) -> Void) {
            completionHandler(
                NSURLSessionAuthChallengeDisposition.UseCredential,
                NSURLCredential(forTrust:
                    challenge.protectionSpace.serverTrust!))
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        let newRequest : NSURLRequest? = request
        print(newRequest?.description);
        completionHandler(newRequest)
    }
    //Progress bar
    func URLSession(session: NSURLSession,
        task: NSURLSessionTask,
        bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64){
            
            
    }

    
    

    

    
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    

}






