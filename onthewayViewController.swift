//
//  onthewayViewController.swift
//  phuketTaxiM
//
//  Created by cake on 4/18/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class onthewayViewController: UIViewController, UITextFieldDelegate, UIWebViewDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, UIAlertViewDelegate  {

    //@IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var distanceETA: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var driverName: UILabel!
    @IBOutlet weak var licensePlateNumber: UILabel!
    @IBOutlet weak var carType: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var myWebView: UIWebView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var chatBoxViewHeight: NSLayoutConstraint!
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    struct chatMessage {
        var type : String = String()
        var message : String = String()
    }

    var chatMessages = [chatMessage]()
    
    
    var taxiLat : Double = 0.0
    var taxiLon : Double = 0.0
    
    var kbHeight: CGFloat!
    
    var imageFileName: String = ""
    
    let _queue = dispatch_queue_create("SwiftChat Background Queue", DISPATCH_QUEUE_CONCURRENT)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onTheWay = true
        self.messageTextField.delegate = self
        
        taxiLat = self.delegate.selectedTaxiLat
        taxiLon = self.delegate.selectedTaxiLon
        
        updateMapAnnotations()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnTaxiResponse", name: taxiResponseNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTaxilocationOnTheMap", name: updateLocationKey, object: nil)
        
        
        //=============== Google Map ========================
        
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(delegate.myCurrentLocation.latitude, longitude: delegate.myCurrentLocation.longitude, zoom: self.delegate.zoomLevel)
        //var mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        
        
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        mapView.addObserver(self, forKeyPath: "camera.zoom", options: .New, context: nil)
        
    
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.myLocationEnabled = true
        })
        
        self.mapView.settings.scrollGestures = true
        self.mapView.settings.zoomGestures = true
        
        
              
        self.mapView.camera = camera
        
        //=============== Google Map ========================

        
        var htmlString:String! = ""
        
        
        let testHTML = NSBundle.mainBundle().pathForResource("base", ofType: "html")
        let contents = try? NSString(contentsOfFile: testHTML!, encoding: NSUTF8StringEncoding)
        let baseUrl = NSURL(fileURLWithPath: testHTML!) //for load css file
        
        htmlString = contents as! String + "<body><div class=\"commentArea\">"
        
        
        htmlString = htmlString + "</div></body>"
        
        myWebView.loadHTMLString(htmlString as String, baseURL: baseUrl)

        
        var err : NSError?
        var allParams = Dictionary<String, String>()
        allParams["id"] = self.delegate.selectedTaxiId
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/getDriverData");
        let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
        request1.HTTPMethod = "POST";
        
        do {
            request1.HTTPBody = try NSJSONSerialization.dataWithJSONObject(allParams, options: [])
        } catch let error as NSError {
            err = error
            request1.HTTPBody = nil
        }
        request1.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request1.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
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
                    self.licensePlateNumber.text = json[0]["licensePlateNumber"].string!
                    self.driverName.text = json[0]["firstName"].string! +  " " + json[0]["lastname"].string!
                    self.carType.text = json[0]["carModel"].string!
                    
                    
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
                
                
                self.imageFileName = json[0]["idNumber"].string! + ".png"
                
                //filename = imageFileName
                print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% filename = \(self.imageFileName)")
                
                
                
                let myUrl = NSURL(string: "https://"+mainHost + ":1880/getDriverImage");
                let request2 = NSMutableURLRequest(URL:myUrl!);
                request2.HTTPMethod = "POST";
                
                // Compose a query string
                
                
                let params = ["filename": self.imageFileName] as Dictionary<String, String>
                
                
                do {
                    request2.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
                } catch let error as NSError {
                    err = error
                    request2.HTTPBody = nil
                } catch {
                    fatalError()
                }
                request2.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request2.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let configuration2 = NSURLSessionConfiguration.defaultSessionConfiguration()
                let session2 = NSURLSession(configuration: configuration2, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
                
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
                    
                    let decodedimage = UIImage(data: decodedData!)
                    //var decodedimage = UIImage(named: "taxiIcon.png")
                    
                    //println(decodedimage)
                    //yourImageView.image = decodedimage as UIImage
                    dispatch_async(dispatch_get_main_queue()) {
                        //cell.driverImage = UIImageView(frame:CGRectMake(0, 0, 100, 70))
                        
                        self.imageView.image = decodedimage
                        
                        //self.imageView.image = self.imageResize(decodedimage!, sizeChange: self.imageView.intrinsicContentSize())
                        print("&&&&&&&&&&&&&&&&&&&&& Done decoded &&&&&&&&&&&&&&&&&&&&&&")
                        self.imageView.contentMode  = UIViewContentMode.ScaleAspectFill;
                        
                        self.imageView.autoresizingMask =
                            ( [UIViewAutoresizing.FlexibleBottomMargin, UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleLeftMargin, UIViewAutoresizing.FlexibleRightMargin, UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleWidth] );
                        
                        self.imageView.layer.cornerRadius = 8.0
                        self.imageView.clipsToBounds = true
                        
                    }
                    
                    
                    
                }
                
                task2.resume()
                
                
            }
        }
        
        task.resume()
        // Do any additional setup after loading the view.
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
            
            
    }
    }

    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func actOnTaxiResponse (){
        print("********************************* Taxi response ******************************")
        print(delegate.taxiResponsePayload)
        
        let data: NSData = delegate.taxiResponsePayload.dataUsingEncoding(NSUTF8StringEncoding)!
        var error: NSError?
        
        // convert NSData to 'AnyObject'
        
        
        let json = JSON(data: data)
        
        print(json)
        
        if(json["type"] == "locationUpdate"){
            taxiLat = json["lat"].doubleValue
            taxiLon = json["lon"].doubleValue
            
            let fromLoc : CLLocation = self.delegate.sourceLoc.location
            
            //var fLat = self.delegate.myCurrentLocation.latitude
            //var fLon = self.delegate.myCurrentLocation.longitude
            
            let fLat = fromLoc.coordinate.latitude
            let fLon = fromLoc.coordinate.longitude

           
            
            
            var urlString = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(taxiLat),\(taxiLon)&destinations=\(fLat),\(fLon)&mode=driving&key=\(googleWebAPIkey)"
           
            
            urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            print(urlString)
            
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
            var ETA = ""
            var dd = ""
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let placesTask = session.dataTaskWithURL(NSURL(string: urlString)!) {data, response, error in
                print("inside.")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                let json = JSON(data: data!)
                if json["rows"].count > 0 {
                    if json["rows"][0]["elements"].count > 0 {
                        ETA = json["rows"][0]["elements"][0]["duration"]["text"].string!
                        dd = json["rows"][0]["elements"][0]["distance"]["text"].string!
                        
                        
                        
                        
                    
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.distanceETA.text = "Distance : " + dd + ",  ETA : " + ETA
                            
                        }
                        
                      
                    }
                }
                
                /*if let json = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:nil) as? NSDictionary {
                println(json["rows"])
                }*/
                
            }
            
            placesTask.resume()
            
            
            updateMapAnnotations()
        
        } else if(json["type"] == "chat"){
            print("************ Message =", terminator: "")
            let mm = json["message"].string!
            print(json["message"])
            chatMessages.append(chatMessage(type: "in", message: mm))
            dispatch_async(dispatch_get_main_queue()) {
              
                self.displayChatMessage()
            }
            print(chatMessages)
        } else if(json["type"] == "done"){
            
            delegate.mqttManager!.unsubscribeTopic(gTaxiResponseTopic+"/" + self.delegate.selectedTaxiId)
            
            self.delegate.fare = json["message"].string!
            self.delegate.isCash = json["cash"].string!
            performSegueWithIdentifier("onTheWayToPayment", sender: nil)
            /*dispatch_async(dispatch_get_main_queue()) { // 2
                var cancelAlertView: UIAlertView = UIAlertView(title: "Transacction end", message: "Have a nice day", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.show()
            }*/
        } else if(json["type"] == "picup"){
            cancelButton.hidden = true
            cancelButton.userInteractionEnabled = false
        } else if(json["type"] == "onthewayCancel"){
            
           // mapView.removeObserver(self, forKeyPath: "myLocation")
           // mapView.removeObserver(self, forKeyPath: "camera.zoom")
            dispatch_async(dispatch_get_main_queue()) { // 2
            let cancelAlertView: UIAlertView = UIAlertView(title: "Driver cancel", message: "Sorry, the taxi can't go to pick you for some reasons, please try another taxi", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.tag = 1
                cancelAlertView.show()
            }
        } else if(json["type"] == "CashDone"){
            dispatch_async(dispatch_get_main_queue()) { // 2
                let cancelAlertView: UIAlertView = UIAlertView(title: "Cash payment", message: "Sorry, the taxi can't go to pick you for some reasons, please try another taxi", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.tag = 2
                cancelAlertView.show()
            }
        }
        
        
        
        
       
        
        
        
    }
    
    
    
 
    
    
    func updateTaxilocationOnTheMap(){
        
        updateMapAnnotations()
        
    }
    
    
    
    func updateMapAnnotations(){
        
        
        
        self.mapView.clear()
        
        
        
            
            
        let position = CLLocationCoordinate2DMake(self.taxiLat, self.taxiLon)
        let marker = GMSMarker(position: position)
        marker.map = mapView
        marker.icon = UIImage(named: "taxiIcon.png")
        
        let slat = self.delegate.sourceLoc.location.coordinate.latitude
        let slon = self.delegate.sourceLoc.location.coordinate.longitude
        
        let position2 = CLLocationCoordinate2DMake(slat, slon)
        let marker2 = GMSMarker(position: position2)
        marker2.map = mapView
        marker2.icon = UIImage(named: "custommerIcon.png")
            
            
            
            
      
        
        dispatch_async(dispatch_get_main_queue()) { // 2
            
            
            
       
            
        }
        
    }
    
    
    @IBAction func cancelAction(sender: AnyObject) {
        let removeCustomer : String = "removeContomer/" + self.delegate.selectedTaxiId
        self.delegate.mqttManager!.sendMessage(removeCustomer, message: "id"+userID)
        self.delegate.selectedTaxiId = ""
        self.delegate.selectedTaxiLat = 0.0
        self.delegate.selectedTaxiLon = 0.0
        
        var data = Dictionary<String, String>()
        data["id"] = "id" + userID
        data["type"] = "cancel"
        let jsonObj = JSON(data)
        
        print(jsonObj)
        
        let topic1 : String = gCustomerResponseTopic+"/id"+userID
        
        delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")

        
        delegate.mqttManager!.unsubscribeTopic(gTaxiResponseTopic+"/" + self.delegate.selectedTaxiId)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()

    }

    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize =  (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                
                self.kbHeight = keyboardSize.height
                
                print("Keyboard height = \(self.kbHeight)")
              
                self.animateTextField(true)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        self.animateTextField(false)
        UIView.animateWithDuration(0.5, animations: {
            self.chatBoxViewHeight.constant = 40
        })
        
    }
    
    func animateTextField(up: Bool) {
        // var movement = (up ? -kbHeight : kbHeight)
        
       UIView.animateWithDuration(0.5, animations: {
            self.chatBoxViewHeight.constant = self.kbHeight + 40
        })
    }

    
    @IBAction func sendAction(sender: AnyObject) {
        self.messageTextField.endEditing(true)
        
        
        if(self.messageTextField.text!.isEmpty == false){
            
            
            var data = Dictionary<String, String>()
            data["id"] = "id" + userID
            data["type"] = "chat"
            data["message"] = messageTextField.text
            let jsonObj = JSON(data)
        
            print(jsonObj)
        
            let topic1 : String = gCustomerResponseTopic+"/id"+userID
            
            self.chatMessages.append(chatMessage(type: "out", message: self.messageTextField.text!))
        
            
            
            self.delegate.mqttManager!.sendMessage(topic1, message: "\(jsonObj)")
           
                
            dispatch_async(dispatch_get_main_queue()) {
                
                
                 self.displayChatMessage()
                 self.messageTextField.text = ""
                
            
            }
                
            
            
           
        }
        
        print(chatMessages)
        
    }
    
    // MARK: Text Field delegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.5, animations: {
            self.chatBoxViewHeight.constant = 40
            self.view.layoutIfNeeded()
            }, completion: nil)
        
        
    }
    
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }

    
    
    
    // MARK: Displat chat messages in web view
    
    func displayChatMessage(){
        
        var htmlString:String! = ""
   
        
        let testHTML = NSBundle.mainBundle().pathForResource("base", ofType: "html")
        let contents = try? NSString(contentsOfFile: testHTML!, encoding: NSUTF8StringEncoding)
        let baseUrl = NSURL(fileURLWithPath: testHTML!) //for load css file
        
        htmlString = contents as! String + "<body><div class=\"commentArea\">"
        for x in chatMessages{
            if x.type == "in" {
          
            
                htmlString = htmlString + "<div class=\"bubbledLeft\">"
                htmlString = htmlString + x.message
                htmlString = htmlString + "</div>"
              
                
            } else {
           
                htmlString = htmlString + "<div class=\"bubbledRight\">"
                htmlString = htmlString + x.message
                htmlString = htmlString + "</div>"
            }
        }
        
        
        
        htmlString = htmlString + "</div> </body>"
        let xhtmlString = NSString(format: "<span style=\"font-family: %@; font-size: %i\">%@</span>",
        "Helvetica Neue",
        20,
        htmlString)
       
        print(htmlString)
     
        
      
        
        
        myWebView.loadHTMLString(xhtmlString as String, baseURL: baseUrl)
        
  
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let bottomOffset = CGPointMake(0, self.myWebView.scrollView.contentSize.height - self.myWebView.scrollView.bounds.size.height)
        self.myWebView.scrollView.setContentOffset(bottomOffset, animated: false)
        
      
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
    
    //MARK: Alert view delegate
    func alertView(View: UIAlertView, clickedButtonAtIndex buttonIndex: Int){
        
        /*switch buttonIndex{
            
        case 0:*/
      //  if View.tag == 1 {
       // mapView.addObserver(self, forKeyPath: "camera.zoom", options: .New, context: nil)
        
            //mapView.removeObserver(self, forKeyPath: "camera.zoom")
            delegate.mqttManager!.unsubscribeTopic(gTaxiResponseTopic+"/" + self.delegate.selectedTaxiId)
        
            performSegueWithIdentifier("onthewayToViewcontroller", sender: nil)
        
            
      /*  } else if View.tag == 2 {
            delegate.mqttManager!.unsubscribeTopic(gTaxiResponseTopic+"/" + self.delegate.selectedTaxiId)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("ViewController") as! UIViewController
            
            self.delegate.window?.rootViewController = vc
            self.delegate.window?.makeKeyAndVisible()

        }*/
        
     

            
      /*      break;
        default:
            
            break;
            //Some code here..
            
        }*/
    }

    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
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
