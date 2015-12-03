//
//  registerViewController.swift
//  phuketTaxiM
//
//  Created by cake on 4/23/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class registerViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate, UITextFieldDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, OmiseRequestDelegate{
    
    var omise = Omise()
    var token : Token?

    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var nameT: UITextField!
    @IBOutlet weak var CVCT: UITextField!
    
    @IBOutlet weak var expirationYear: UITextField!
    @IBOutlet weak var idT: UITextField!
    @IBOutlet weak var nationalityT: UITextField!
    @IBOutlet weak var phoneNumberT: UITextField!
    @IBOutlet weak var expireDateT: UITextField!
    @IBOutlet weak var creditNumberT: UITextField!
    @IBOutlet weak var passwordT: UITextField!
    @IBOutlet weak var emailT: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var chooseBtn: UIButton!
    var picker:UIImagePickerController?=UIImagePickerController()
    var popover:UIPopoverController?=nil
    
    var base64image : String = "";

  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerButton.layer.cornerRadius = 30 //registerButton.layer.frame.height / 2
        registerButton.layer.borderColor = UIColor.whiteColor().CGColor
        registerButton.layer.borderWidth = 2
        registerButton.layer.backgroundColor = UIColor.clearColor().CGColor
        registerButton.layer.masksToBounds = true;
        
        cancelButton.layer.cornerRadius = 30 //loginButton.layer.frame.height / 2
        cancelButton.layer.borderColor = UIColor.whiteColor().CGColor
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.backgroundColor = UIColor.clearColor().CGColor
        cancelButton.layer.masksToBounds = true;
        
        picker?.delegate = self
        
        
        self.idT.delegate = self
        self.nationalityT.delegate = self
        self.phoneNumberT.delegate = self
        self.expireDateT.delegate = self
        self.creditNumberT.delegate = self
        self.passwordT.delegate = self
        self.emailT.delegate = self
        self.nameT.delegate = self
        self.CVCT.delegate = self
        self.expirationYear.delegate = self
        
        self.expirationYear.placeholder = "YYYY"
        self.CVCT.placeholder = "CVC"
        self.expireDateT.placeholder = "MM"
        
        self.addDoneButtonOnKeyboard()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("loginViewController") 
        
        delegate.window?.rootViewController = vc
        delegate.window?.makeKeyAndVisible()

        
    }
    @IBAction func registerAction(sender: AnyObject) {
        
        if(nationalityT.text == "Thai" || nationalityT.text == "Thailand"){
            reg()
        } else {
        let tokenRequest = TokenRequest()
        
        
        
        tokenRequest.publicKey = omisePublicKey //required
        tokenRequest.card!.name = nameT.text //required
        //tokenRequest.card!.city = self.delegate.cardCity//required
        //tokenRequest.card!.postalCode = self.delegate.cardOostalCode //required
        tokenRequest.card!.number = creditNumberT.text  //required
        tokenRequest.card!.expirationMonth = expireDateT.text //required
        tokenRequest.card!.expirationYear = expirationYear.text  //required
        tokenRequest.card!.securityCode = CVCT.text //required
        
        //request
        
        omise.delegate = self
        omise.requestToken(tokenRequest)

        }
        
    
       
    }
    
 
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("loginViewController") 
        
        self.delegate.window?.rootViewController = vc
        self.delegate.window?.makeKeyAndVisible()
    }
    
    @IBAction func choosePhoto(sender: AnyObject) {
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone
        {
            self.presentViewController(picker!, animated: true, completion: nil)
        }
        else
        {
            popover=UIPopoverController(contentViewController: picker!)
            popover!.presentPopoverFromRect(chooseBtn.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
    }

    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        picker .dismissViewControllerAnimated(true, completion: nil)
        
        var imm: UIImage = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
        
        
        //imageView.image=info[UIImagePickerControllerOriginalImage] as? UIImage
        
        
        
       /* dispatch_async(dispatch_get_main_queue()) {
            self.imageView.image=imm
        }*/
        
        var scaledImage: UIImage = imm
        
        if(imm.size.width > 100){
            
            var fact  = 100.0/(imm.size.width)
            
            let size = CGSizeApplyAffineTransform(imm.size, CGAffineTransformMakeScale(fact, fact))
            let hasAlpha = false
            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
            
            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
            imm.drawInRect(CGRect(origin: CGPointZero, size: size))
            
            scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

        }
        
        var w = 150.0 as CGFloat;
        var h = 150.0*imm.size.height/imm.size.width as CGFloat
        
        imm.resize(CGSizeMake(w,h), completionHandler: { [weak self](resizedImage, data) -> () in
            
            let image = resizedImage
            var imagePngData = UIImagePNGRepresentation(image);
            
            self!.base64image = imagePngData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    
            
        })
        
        
        dispatch_async(dispatch_get_main_queue()) {
           self.imageView.image=scaledImage
        }
        
    
        
        let imageData = UIImageJPEGRepresentation(scaledImage, 1)
        let relativePath = "image_avatar.jpg"
        let path = self.documentsPathForFileName(relativePath)
        imageData!.writeToFile(path, atomically: true)
        NSUserDefaults.standardUserDefaults().setObject(relativePath, forKey: "path")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        
        //sets the selected image to image view
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        print("picker cancel.")
    }
    
    func documentsPathForFileName(name: String) -> String {
        /*let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true);
        let path = paths[0] ;
        let fullPath = path.stringByAppendingPathComponent(name)*/
        
        
        let manager = NSFileManager.defaultManager()
        let URLs = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let fullPath = URLs[0].URLByAppendingPathComponent(name)

        
        return fullPath.path!
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
    
    // MARK: Add done button
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        doneToolbar.barStyle = UIBarStyle.Default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("doneButtonAction"))
        
        //let items = NSMutableArray()
        //items.addObject(flexSpace)
        //items.addObject(done)
        
        
        var items: [UIBarButtonItem]? = [UIBarButtonItem]()
 
        
        items?.append(flexSpace)
        items?.append(done)

        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        //self.textView.inputAccessoryView = doneToolbar
        self.phoneNumberT.inputAccessoryView = doneToolbar
        self.creditNumberT.inputAccessoryView = doneToolbar
        self.CVCT.inputAccessoryView = doneToolbar
        
    }
    
    func doneButtonAction()
    {
        self.phoneNumberT.resignFirstResponder()
        self.creditNumberT.resignFirstResponder()
        self.CVCT.resignFirstResponder()
        //self.textViewDescription.resignFirstResponder()
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    func omiseOnFailed(error: NSError?) {
        //handle error
        dispatch_async(dispatch_get_main_queue()) { // 2
            let cancelAlertView: UIAlertView = UIAlertView(title: "Wrong cradit card number", message: "Please enter a valid cradit carda data", delegate: nil, cancelButtonTitle: "OK");
            cancelAlertView.show()
        }

    }
    
    func omiseOnSucceededToken(token1: Token?) {
        
        reg();
    }
    
    
    
    func reg(){
        var err: NSError?
        var allParams = Dictionary<String, String>()
        allParams["id"] = idT.text
        allParams["name"] = nameT.text
        allParams["email"] = emailT.text
        allParams["password"] = passwordT.text
        allParams["creditNumber"] = creditNumberT.text
        allParams["expireMounth"] = expireDateT.text
        allParams["expireYear"] = expirationYear.text
        allParams["CVC"] = CVCT.text
        allParams["phoneNumber"] = phoneNumberT.text
        allParams["nationality"] = nationalityT.text
        allParams["passportID"] = idT.text
        allParams["postalCode"] = "12345"
        allParams["city"] = "Phuket"
        
        
        
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/uploadCustommerData");
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
            
            // You can print out response object
            print("response = \(response)")
            
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
            
            dispatch_async(dispatch_get_main_queue()) { // 2
                var cancelAlertView: UIAlertView = UIAlertView(title: "Thank you", message: "Thank you for being our member, we already sent the activation link email. After clicking at the link, the account will be active.", delegate: self, cancelButtonTitle: "OK");
                cancelAlertView.show()
            }
            
            
        }
        
        task.resume()
        
        
        
        
        let myUrl = NSURL(string: "https://"+mainHost + ":1880/uploadImageCustommer");
        let request = NSMutableURLRequest(URL:myUrl!);
        request.HTTPMethod = "POST";
        
        // Compose a query string
        
        
        var filename = idT.text! + ".png"
        
        
        var params = ["filename": filename, "data":base64image] as Dictionary<String, String>
        
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
        } catch var error as NSError {
            err = error
            request.HTTPBody = nil
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var configuration2 = NSURLSessionConfiguration.defaultSessionConfiguration()
        var session2 = NSURLSession(configuration: configuration2, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        
        let task2 = session2.dataTaskWithRequest(request){
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            // You can print out response object
            print("response = \(response)")
            
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
            
            
        }
        
        task2.resume()
    }


}


extension UIImage {
    public func resize(size:CGSize, completionHandler:(resizedImage:UIImage, data:NSData)->()) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let newSize:CGSize = size
            let rect = CGRectMake(0, 0, newSize.width, newSize.height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.drawInRect(rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let imageData = UIImageJPEGRepresentation(newImage, 0.5)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(resizedImage: newImage, data:imageData!)
            })
        })
    }
}


