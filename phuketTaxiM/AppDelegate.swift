//
//  AppDelegate.swift
//  phuketTaxiM
//
//  Created by cake on 3/15/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit
import CoreData
import MapKit

let mySpecialNotificationKey = "com.cake.specialNotificationKey5"
let updateLocationKey = "com.cake.updateLocation"
let taxiResponseNotificationKey = "com.cake.taxiResponseNotificationKey"
let mqttConnectedNotificationKey =  "mqttConnectedNotificationKey"

let gCustomerResponseTopic : String = "customerResponse"
let gTaxiResponseTopic : String = "taxiResponse"
var userID: String = "11111111111"
let mainHost : String = "128.199.97.22";
var didLogin : Bool = false
var onTheWay : Bool = false
let googleAPIkey : String = "AIzaSyCV9W9HIjs5ny_Z-RyBYNdf6nJHkB3L5qU"
let googleWebAPIkey : String = "AIzaSyCkkgvHEbB9Q0k4ICWzZBJNd_wV5GEYNzc"
let omisePublicKey : String = "pkey_test_50zicu2el50z0t59id6"
var selectedTaxiTopic : String = String()

let pathToImage : String = "/images/custommers/"
@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate, MQTTSessionManagerDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate {

    var window: UIWindow?
 
    var globalFireOnce : Bool = true
    
    struct taxiLocation {
        var id : String = String()
        var lat : Double = 0
        var lon : Double = 0
    }

    var listTaxi = Dictionary<String, taxiLocation>()
    
    var taxiResponsePayload : String = ""
    
    //let mqtt : MQTTPipe = MQTTPipe()
     var mqttManager : MQTTSessionManager?
    var mqttComplete = false
    
    var myCurrentLocation = CLLocationCoordinate2D(
        latitude: 0,
        longitude: 0
    )
    
    
    
    struct locDetail {
        var name : String = String()
        var address : String = String()
        var location : CLLocation = CLLocation()
        var distance : Double = 0
    }
    
    var locFromTo = [String:locDetail]()
    
    var destinationLoc : locDetail = locDetail(name: "", address: " ", location: CLLocation(), distance: 0)
    var sourceLoc : locDetail = locDetail(name: "", address: " ", location: CLLocation(), distance: 0)
    

    
    var selectedTaxiLat : Double = 0.0
    var selectedTaxiLon : Double = 0.0
    var selectedTaxiId : String = ""

    let prefs = NSUserDefaults.standardUserDefaults()
    
    
    var setSourceAndDestinationRow : Int = 0
    var mqttIsClosed = false
    var zoomLevel : Float = 13.0
    
    
    var fare : String = ""
    var isCash : String = ""
    
    
    var cardName = "JOHN DOE" //required
   // var cardCity = "Bangkok" //required
  //  var cardOostalCode = "10320" //required
    var cardNumber = "4242424242424242" //required
    var cardExpirationMonth = "11" //required
    var cardExpirationYear = "2016" //required
    var cardSecurityCode = "123" //required
    var cardEmail : String = ""
    var nationality : String = ""
    
    var userImage : UIImage?
    var imageID : String = ""

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startMqtt", name: mqttConnectedNotificationKey, object: nil)
        
        GMSServices.provideAPIKey(googleAPIkey)
        UIApplication.sharedApplication().idleTimerDisabled = true
       
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
      
       /* if((prefs.objectForKey("firstRun")) == nil){
            prefs.setObject("Yes", forKey: "firstRun")
            //userID = NSUUID().UUIDString
            //prefs.setObject(userID, forKey: "userID")
            
            let vc = storyboard.instantiateViewControllerWithIdentifier("registerViewController") as! UIViewController
            
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
        
            
            
        } else {*/
            //userID = prefs.objectForKey("userID") as! String
        
        if((prefs.objectForKey("haveLogin")) != nil){
            
            if(prefs.objectForKey("haveLogin") as! String == "yes"){
                let email = prefs.objectForKey("username") as! String
                let password1 = prefs.objectForKey("password") as! String
                login(email, password: password1)
            } else {
                let vc = storyboard.instantiateViewControllerWithIdentifier("loginViewController") 
                
                self.window?.rootViewController = vc
                self.window?.makeKeyAndVisible()
            
            }
            
        } else {
            let vc = storyboard.instantiateViewControllerWithIdentifier("loginViewController") 
            
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
            
            print("run leaw")
        }
        
       // }
        
     
        
        
        
        //mqtt.sendMessage("request/"+self.clientID, message: self.clientID)
        
      /*  let SIG_IGN = CFunctionPointer<((Int32) -> Void)>(COpaquePointer(bitPattern: 1))
  
        let swiftCallback : @convention(c) (CGFloat, CGFloat) -> CGFloat = {
            (x, y) -> CGFloat in
            return x + y
        }
        
        CFunctionPointer<(UnsafeMutablePointer<Void>, Float) -> Int>.self*/
        
       /* typealias CFunction = @convention(c) <((Int32) -> Void)>(COpaquePointer(bitPattern: 1))
        let SIG_IGN = CFunction.self

        signal(SIGPIPE, SIG_IGN)*/
  
        return true
    }

    
    
    func login(email: String, password: String){
     
        
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/customerLogin");
        let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
        request1.HTTPMethod = "POST";
        let requestString = "email="+email+"&" + "password="+password
        let data = (requestString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        request1.HTTPBody =  data
        
        
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
        let task = session.dataTaskWithRequest(request1){
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            // You can print out response object
            print("response = \(response)")
            
            if let httpResponse = response as? NSHTTPURLResponse {
                //if httpResponse.statusCode == 200 {
                
                
                let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("******************************** Response from Server **********************")
                // You can print out response object
                //println("response = \(response)")
                print("responseString = \(responseString)")
                
                let json = JSON(data: data!)
                
                if(json.count > 0){
                    userID = json[0]["passportID"].string!
                    
                    
                    self.cardName = json[0]["name"].string! //required
                    //self.cardCity = json[0]["city"].string!  //required
                    //self.cardOostalCode = json[0]["postalCode"].string!  //required
                    self.cardNumber = json[0]["creditNumber"].string!  //required
                    self.cardExpirationMonth = json[0]["expireMounth"].string!  //required
                    self.cardExpirationYear = json[0]["expireYear"].string!  //required
                    self.cardSecurityCode = json[0]["CVC"].string!  //required
                    self.cardEmail = json[0]["email"].string!
                    
                    self.prefs.setObject(userID, forKey: "userID")
                    self.nationality = json[0]["nationality"].string!
                    print("Naitonality = \(self.nationality)")
                    
                    
                    
                    //self.delegate.mqtt.start("id"+userID)
                    
                    print(userID)
                    
                    //self.delegate.initMQTT()
                    print("Did login =============================== true ===")
                    didLogin = true
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(mqttConnectedNotificationKey, object: self)
                    
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    
                    while(self.mqttComplete == false){
                        
                        NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
                    }
                    
                    
                    if((self.prefs.objectForKey("username")) == nil){
                        self.prefs.setObject(email, forKey: "username")
                        self.prefs.setObject(password, forKey: "password")
                        self.prefs.setObject("yes", forKey: "haveLogin")
                        
                    }
                    
                    self.imageID = json[0]["id"].string!
                    
                    let url = "http://" + mainHost + pathToImage + self.imageID + ".png"
                    print(url)
                    
                    if let checkedUrl = NSURL(string: url) {
                        self.downloadImage(checkedUrl)
                    }

                    
                    
                } else {
                    dispatch_async(dispatch_get_main_queue()) { // 2
                        let cancelAlertView: UIAlertView = UIAlertView(title: "Login fail", message: "ข้อมูลไม่ถูกต้อง", delegate: self, cancelButtonTitle: "OK");
                        cancelAlertView.show()
                    }
                }
                
                
                
                
                
                
                
                
                
                /*} else {
                dispatch_async(dispatch_get_main_queue()) { // 2
                var cancelAlertView: UIAlertView = UIAlertView(title: "Login fail", message: "ข้อมูลไม่ถูกต้อง", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.show()
                }
                }*/
                
                
            }
            
            
            
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
            
            
            
            
        }
        
        task.resume()

    }
    
    func getDataFromUrl(urL:NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(urL) { (data, response, error) in
            completion(data: data)
            }.resume()
    }

    
    func downloadImage(url:NSURL){
       // print("Started downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
        getDataFromUrl(url) { data in
            dispatch_async(dispatch_get_main_queue()) {
         //       print("Finished downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
                self.userImage = UIImage(data: data!)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                let vc = storyboard.instantiateViewControllerWithIdentifier("ViewController") 
                
                self.window?.rootViewController = vc
                self.window?.makeKeyAndVisible()

            }
        }
    }

    
    /*
    func initMQTT1(){
        var block : @objc_block (MQTTMessage!) -> Void = {
            (message : MQTTMessage!) -> Void in
    
            if(message.topic == "available/id"+userID) {
                println(message.payloadString())
                self.insertTaxies(message.payloadString())
            } else if (message.topic == "updateTaxiLocation/id" + userID){
                println("****************** Update location ***********************")
                self.updateTaxiLocation(message.payloadString())
                println(message.payloadString())
            } else if (message.topic == "removeTaxi/id" + userID){
                self.removeTaxi(message.payloadString())
            } else if (message.topic.hasPrefix(gTaxiResponseTopic)) {
    
                self.taxiResponsePayload = message.payloadString()
                NSNotificationCenter.defaultCenter().postNotificationName(taxiResponseNotificationKey, object: self)
                
            } else {
                println("Somethingelse")
            }
        }
        
        var hh : MQTTMessageHandler = block
        
        
        //println("request/"+clientID)
        
        mqtt.subscribeTopic("available/test")
        mqtt.subscribeTopic("available/id" + userID)
        mqtt.subscribeTopic("updateTaxiLocation/id" + userID)
        mqtt.subscribeTopic("removeTaxi/id" + userID)
        mqtt.mqttInstance.messageHandler = hh

        
    }*/
    
    


    //MARK: Mqtt delegate
    
    func handleMessage(data: NSData!, onTopic topic: String!, retained: Bool) {
        
        let payload : String = NSString(data:data, encoding:NSUTF8StringEncoding) as! String
        if(topic == "available/id"+userID) {
            print(payload)
            self.insertTaxies(payload)
        } else if (topic == "updateTaxiLocation/id" + userID){
            print("****************** Update location ***********************")
            self.updateTaxiLocation(payload)
            print(payload)
        } else if (topic == "removeTaxi/id" + userID){
            self.removeTaxi(payload)
        } else if (topic.hasPrefix(gTaxiResponseTopic)) {
            
            self.taxiResponsePayload = payload
            NSNotificationCenter.defaultCenter().postNotificationName(taxiResponseNotificationKey, object: self)
            
        } else {
            print("Somethingelse")
        }
    }
    
 

    func initMQTT(){
        
        mqttManager!.subscribeToTopic("available/test")
        mqttManager!.subscribeToTopic("available/id" + userID)
        mqttManager!.subscribeToTopic("updateTaxiLocation/id" + userID)
        mqttManager!.subscribeToTopic("removeTaxi/id" + userID)
        
    }
    
    func startMqtt(){
        print("=================== Try to connect to MQTT")
        
        mqttManager = MQTTSessionManager()
        
        let id = "id"+userID
        print("xxxxxxxxxxxxxxxx Taxi id = \(id)")
        
        mqttManager!.delegate = self
        mqttManager!.addObserver(self, forKeyPath: "state", options: [NSKeyValueObservingOptions.Initial, NSKeyValueObservingOptions.New], context: nil)
        let willMessage = userID.dataUsingEncoding(NSUTF8StringEncoding)
        mqttManager!.connectTo(mainHost, port: 1883, tls: false, keepalive: 60, clean: true, auth: false, user: nil, pass: nil, willTopic: "taxiDriver/will", will: willMessage, willQos: MQTTQosLevel.AtMostOnce, willRetainFlag: false, withClientId: "id"+userID)
        
        
        
        
        // mqttManager.disconnect()
        // mqttManager.connectToLast()
        
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        print("=================== Trying to connect to MQTT")
        switch self.mqttManager!.state {
        case MQTTSessionManagerState.Closed:
            print("============== CLosed =================")
            mqttIsClosed = true
            break
        case MQTTSessionManagerState.Closing:
            print("============== Closing =================")
            break
        case MQTTSessionManagerState.Connected:
            print("============== MQTT connected =================")
            
            initMQTT()
            mqttIsClosed = false
            //Ask manager for all avaliable taxies
            mqttManager!.sendMessage("request/id"+userID, message: "id"+userID)
            
           
            
            //startTimer()
            
            break
        case MQTTSessionManagerState.Connecting:
            print("============== Connecting =================")
            break
        case MQTTSessionManagerState.Error:
            print("============== ERROR =================")
            print("")
            break
        case MQTTSessionManagerState.Starting:
            print("============== STarting =================")
            break
        default:
            print("============== Confused =================")
            break
        }
        
    }
    
    
    
    func removeTaxi(taxiId : String){
        listTaxi.removeValueForKey(taxiId)
        NSNotificationCenter.defaultCenter().postNotificationName(updateLocationKey, object: self)
    }
    
    func updateTaxiLocation(newLoc : String){
        let data: NSData = newLoc.dataUsingEncoding(NSUTF8StringEncoding)!
        var error: NSError?
        
        // convert NSData to 'AnyObject'
        
        
        let json = JSON(data: data)
        var b:taxiLocation = taxiLocation()
        
        
        b.id = json["id"].string!
        b.lat = json["lat"].double!
        b.lon = json["lon"].double!
        
        print(NSString(format:"id = %s lat = %f lon = %f", b.id, b.lat, b.lon))

        listTaxi[b.id] = b
        NSNotificationCenter.defaultCenter().postNotificationName(updateLocationKey, object: self)

    }
    
    func insertTaxies(allTaxies : String) {
    
        // convert String to NSData
        let data: NSData = allTaxies.dataUsingEncoding(NSUTF8StringEncoding)!
        var error: NSError?
    
        // convert NSData to 'AnyObject'
    
    
        let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))) as! NSDictionary
    
        print("Error: \(error)")
    
    
        for (key, value) in json {
            let avalFlag = (value["aval"] as AnyObject? as? Int) ?? 0
            if(avalFlag == 1){
                var b:taxiLocation = taxiLocation()
    
                b.id = (key as AnyObject? as? String) ?? ""
                b.lat = (value["lat"] as AnyObject? as? Double) ?? 0
                b.lon = (value["lon"] as AnyObject? as? Double) ?? 0
    
                listTaxi[b.id] = b
                print(key)

            }
    
        }
        
        
        
        var mm = Dictionary<String, String>()
        //var json2 : JSON
        
        let idString =  "id"+userID
        
        mm["id"] = idString
        mm["From"] = "Here"
        mm["to"] = "There"
        mm["lat"] = String(format:"%f",  0.0)
        mm["lon"] = String(format:"%f", 0.0)
        mm["requestFlag"] = String(format:"%d", 0)
        
        
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(mm,
            options: [])
        
        let jsonString =  NSString(data: jsonData!, encoding:NSUTF8StringEncoding)
        
        
        for (key, x) in listTaxi {
            
            let topic = "cli/" + x.id
            mqttManager!.sendMessage(topic, message: jsonString as! String)
            print("************************ Broadcast to all taxies ********************************")
            print(jsonString as! String)
            print(topic)
            print("************************ Broadcast to all taxies ********************************")
            
        }
        
        self.mqttComplete = true
        
        NSNotificationCenter.defaultCenter().postNotificationName(mySpecialNotificationKey, object: self)

        
    }
    
    func removeFromTaxi(){
        for (key, value) in listTaxi {
            if(key != selectedTaxiId){
                let removeCustomer : String = "removeContomer/" + key
                mqttManager!.sendMessage(removeCustomer, message: "id"+userID)
            }
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        if(didLogin == true){
            removeFromTaxi()
            listTaxi.removeAll(keepCapacity: false)
        }
        mqttManager?.disconnect()

    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
       /* if(didLogin == true){
        removeFromTaxi()
        listTaxi.removeAll(keepCapacity: false)
        }*/

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // mqtt.sendMessage("request/"+self.clientID, message: self.clientID)
        if(didLogin == true){
            mqttManager!.reconnect()
            
            print("try to reconnect")
            while(self.mqttManager!.state != MQTTSessionManagerState.Connected){
                print("reconnecting")
                 NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
            }
            
            
            initMQTT()
            if onTheWay == true {
                mqttManager!.subscribeToTopic(selectedTaxiTopic)
            }
            

            mqttManager!.sendMessage("request/id"+userID, message: "id"+userID)
        }

        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print("*********************** Quiting ************************")

        
        /*
        
        if(didLogin == true){
            /* self.mqttManager!.disconnect()
            while(self.mqttIsClosed == false) {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
            //removeFromManager()
            }*/
            
            
            
            println("try to reconnect from pong Resign from Active")
            while(self.mqttIsClosed == true){
                NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 2))
                self.mqttManager!.reconnect()
            }
            
            removeFromTaxi()
            
            
        }
*/
        
        
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "aa.phuketTaxiM" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("phuketTaxiM", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("phuketTaxiM.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
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
    
    


}

