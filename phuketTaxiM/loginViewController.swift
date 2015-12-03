//
//  loginViewController.swift
//  phuketTaxiM
//
//  Created by cake on 5/3/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class loginViewController: UIViewController , UITextFieldDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate {

    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var emailT: UITextField!
    @IBOutlet weak var passwordT: UITextField!
    let prefs = NSUserDefaults.standardUserDefaults()
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerButton.layer.cornerRadius = 30 //registerButton.layer.frame.height / 2
        registerButton.layer.borderColor = UIColor.whiteColor().CGColor
        registerButton.layer.borderWidth = 2
        registerButton.layer.backgroundColor = UIColor.clearColor().CGColor
        registerButton.layer.masksToBounds = true;
        
        signInButton.layer.cornerRadius = 30 //loginButton.layer.frame.height / 2
        signInButton.layer.borderColor = UIColor.whiteColor().CGColor
        signInButton.layer.borderWidth = 2
        signInButton.layer.backgroundColor = UIColor.clearColor().CGColor
        signInButton.layer.masksToBounds = true;
        
        
        emailT.attributedPlaceholder =
            NSAttributedString(string: "E-mail", attributes:[NSForegroundColorAttributeName : UIColor.grayColor()])
        passwordT.attributedPlaceholder =
            NSAttributedString(string: "Password", attributes:[NSForegroundColorAttributeName : UIColor.grayColor()])
        
       // emailT.layer.cornerRadius = emailT.layer.frame.height/2
       // passwordT.layer.cornerRadius = passwordT.layer.frame.height/2
        

        self.emailT.delegate = self
        self.passwordT.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signInAction(sender: AnyObject) {
        
        
        if emailT.text!.characters.count > 0 &&  passwordT.text!.characters.count > 0 {
            var email = emailT.text
            var password = passwordT.text
            
            let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/customerLogin");
            let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
            request1.HTTPMethod = "POST";
            let requestString = "email="+email!+"&" + "password="+password!
            let data = (requestString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            request1.HTTPBody =  data
            
            
            
            var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
            
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
                            
                            
                            self.delegate.cardName = json[0]["name"].string! //required
                            //self.delegate.cardCity = json[0]["city"].string!  //required
                            //self.delegate.cardOostalCode = json[0]["postalCode"].string!  //required
                            self.delegate.cardNumber = json[0]["creditNumber"].string!  //required
                            self.delegate.cardExpirationMonth = json[0]["expireMounth"].string!  //required
                            self.delegate.cardExpirationYear = json[0]["expireYear"].string!  //required
                            self.delegate.cardSecurityCode = json[0]["CVC"].string!  //required
                            self.delegate.cardEmail = json[0]["email"].string!
                            self.delegate.nationality = json[0]["nationality"].string!
                            print("Naitonality = \(self.delegate.nationality)")
                            
                            //self.delegate.mqtt.start("id"+userID)
                            
                            print(userID)
                            
                            //self.delegate.initMQTT()
                            print("Did login =============================== true ===")
                            didLogin = true
                            
                            NSNotificationCenter.defaultCenter().postNotificationName(mqttConnectedNotificationKey, object: self)
                            
                            
                            
                            
                            while(self.delegate.mqttComplete == false){
                              
                                NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 1))
                            }
                            
                            
                            //if((self.prefs.objectForKey("username")) == nil){
                            self.prefs.setObject(email, forKey: "username")
                            self.prefs.setObject(password, forKey: "password")
                            self.prefs.setObject("yes", forKey: "haveLogin")
                                
                           // }
                            
                            
                            self.delegate.prefs.setObject(userID, forKey: "userID")
                            
                            self.delegate.imageID = json[0]["id"].string!
                            
                            var url = "http://" + mainHost + pathToImage + self.delegate.imageID + ".png"
                            print(url)
                            
                            if let checkedUrl = NSURL(string: url) {
                                self.downloadImage(checkedUrl)
                            }

                            
                        } else {
                            dispatch_async(dispatch_get_main_queue()) { // 2
                                var cancelAlertView: UIAlertView = UIAlertView(title: "Login fail", message: "ข้อมูลไม่ถูกต้อง", delegate: self, cancelButtonTitle: "OK");
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
            
        } else {
            dispatch_async(dispatch_get_main_queue()) { // 2
                var cancelAlertView: UIAlertView = UIAlertView(title: "Login fail", message: "กรอกข้อมูลไม่ครบ", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.show()
            }
        }
        
        

   
        
    }

    
    func getDataFromUrl(urL:NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(urL) { (data, response, error) in
            completion(data: data)
            }.resume()
    }
    
    
    func downloadImage(url:NSURL){
    //    print("Started downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
        getDataFromUrl(url) { data in
            dispatch_async(dispatch_get_main_queue()) {
      //          print("Finished downloading \"\(url.lastPathComponent!.stringByDeletingPathExtension)\".")
                self.delegate.userImage = UIImage(data: data!)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                let vc = storyboard.instantiateViewControllerWithIdentifier("ViewController") 
                
                self.delegate.window?.rootViewController = vc
                self.delegate.window?.makeKeyAndVisible()

            }
        }
    }
    

    
    @IBAction func registerAction(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("registerViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()
        
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

    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
