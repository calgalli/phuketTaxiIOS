//
//  paymentViewController.swift
//  phuketTaxiM
//
//  Created by cake on 8/10/2558 BE.
//  Copyright (c) 2558 cake. All rights reserved.
//

import UIKit

class paymentViewController: UIViewController,OmiseRequestDelegate, UITextFieldDelegate, UIAlertViewDelegate,  NSURLSessionDelegate, NSURLSessionTaskDelegate, UITextViewDelegate, FloatRatingViewDelegate {

    var omise = Omise()
    var token : Token?
    
    @IBOutlet weak var commenttextView: UITextView!
    var placeholderLabel : UILabel!

    
    
    @IBOutlet weak var floatRatingView: FloatRatingView!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var fareLabel: UILabel!
    @IBOutlet weak var tipTextField: UITextField!
    @IBOutlet weak var fareTextField: UITextField!

    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var alert : UIAlertView = UIAlertView()
    var rating:String = "5"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Required float rating view params
        self.floatRatingView.emptyImage = UIImage(named: "StarEmpty")
        self.floatRatingView.fullImage = UIImage(named: "StarFull")
        // Optional params
        self.floatRatingView.delegate = self
        self.floatRatingView.contentMode = UIViewContentMode.ScaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 1
        self.floatRatingView.rating =  3
        self.floatRatingView.editable = true
        self.floatRatingView.halfRatings = false
        self.floatRatingView.floatRatings = false
        
        
        payButton.layer.cornerRadius = 30 //registerButton.layer.frame.height / 2
        payButton.layer.borderColor = UIColor.whiteColor().CGColor
        payButton.layer.borderWidth = 2
        payButton.layer.backgroundColor = UIColor.clearColor().CGColor
        payButton.layer.masksToBounds = true;

        
        
        commenttextView.delegate = self
        placeholderLabel = UILabel()
        placeholderLabel.text = "Comment"
        commenttextView.font = UIFont.systemFontOfSize(commenttextView.font!.pointSize)
        placeholderLabel.sizeToFit()
        commenttextView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPointMake(5, commenttextView.font!.pointSize / 2)
        placeholderLabel.textColor = UIColor(white: 0, alpha: 0.3)
        placeholderLabel.hidden = commenttextView.text.characters.count != 0

        if self.delegate.isCash == "yes" {
            payButton.setTitle("Pay by cash", forState: [])
        } else {
            payButton.setTitle("Pay by cradit card", forState: [])
            
            //set parameters
            let tokenRequest = TokenRequest()
            
            
            
            tokenRequest.publicKey = omisePublicKey //required
            tokenRequest.card!.name = self.delegate.cardName  //required
            //tokenRequest.card!.city = self.delegate.cardCity//required
            //tokenRequest.card!.postalCode = self.delegate.cardOostalCode //required
            tokenRequest.card!.number = self.delegate.cardNumber  //required
            tokenRequest.card!.expirationMonth = self.delegate.cardExpirationMonth //required
            tokenRequest.card!.expirationYear = self.delegate.cardExpirationYear  //required
            tokenRequest.card!.securityCode = self.delegate.cardSecurityCode //required
            
            //request
            
            omise.delegate = self
            omise.requestToken(tokenRequest)
            // Do any additional setup after loading the view.
        }

        
  
        
        fareLabel.text = self.delegate.fare
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func payAction(sender: AnyObject) {
        
        if self.delegate.isCash == "yes" {
            
        } else {
            payUsingCraditCard()
        }
        
        
        
        var err: NSError?
        let date = NSDate()
        let formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy-MM-dd";
        let dateString = formatter.stringFromDate(date);
        
        let formatter2 = NSDateFormatter();
        formatter2.dateFormat = "HH:mm:ss";
        let timeString = formatter2.stringFromDate(date);
        
        var allParams = Dictionary<String, String>()
        
        
        allParams["idNumber"] = self.delegate.selectedTaxiId
        allParams["fare"] = fareLabel.text
        allParams["tip"] = tipTextField.text
        allParams["customerID"] = "id" + userID
        allParams["date"] = dateString
        allParams["time"] = timeString
        allParams["comment"] = commenttextView.text
        allParams["rating"] = rating
        
        
        
        let custommerDataUrl = NSURL(string: "https://"+mainHost + ":1880/updateTransaction");
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
            
            // You can print out response object
            print("response = \(response)")
            
            // Print out response body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
            
           
            
            self.performSegueWithIdentifier("toMaiViewFromPay", sender: nil)
            
            
        }
        
        task.resume()

    
        
        
        
        
    }
    
    
    func payUsingCraditCard(){
        let spaceSet = NSCharacterSet.whitespaceCharacterSet()
        
        let total = (fareLabel.text! as NSString).doubleValue + (tipTextField.text! as NSString).doubleValue
        
        
        let totalAmount : String = String(format:"%8.0f", (total*100))
        let tt = totalAmount.stringByTrimmingCharactersInSet(spaceSet)
        
        let custommerDataUrl = NSURL(string: "http://"+mainHost + ":3000/pay?");
        let request1 = NSMutableURLRequest(URL:custommerDataUrl!);
        request1.HTTPMethod = "GET";
        
        let email : String = self.delegate.cardEmail
        let tokenID : String = token!.tokenId
        
        //token=tokn_test_50zx11844sn5ny38y9h&amount=44400&email=cake@yahoo.com&desc=kkkkkkk
        //  let data = (requestString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        // request1.HTTPBody =  data
        
        
        
        let requestString : String = "http://"+mainHost + ":3000/pay?"
        //    requestString =  requestString + "token="+tokenID+"&" + "amount="+xxx + "&" + "email="
        //  requestString = requestString   + email + "&" + "desc=" + "kkkkk"
        
        var parameters: [String: AnyObject] = [String: AnyObject]()
        parameters["token"]=tokenID
        parameters["amount"]=tt
        parameters["email"]=email
        parameters["desc"]="kkkk"
        let parameterString = parameters.stringFromHttpParameters()
        let requestURL = NSURL(string:"\(requestString)\(parameterString)")!
        
        print(requestURL)
        
        let request = NSMutableURLRequest(URL: requestURL)
        request.HTTPMethod = "GET"
        
        let session = NSURLSession.sharedSession()
        //let task = session.dataTaskWithRequest(request, completionHandler:nil)
        let task = session.dataTaskWithRequest(request)
        task.resume()
        
    }
    
    func alertView(View: UIAlertView, clickedButtonAtIndex buttonIndex: Int){
        
        if View.tag == 100 {
            
            switch buttonIndex{
                
            case 0:
                
               // println(alert.textFieldAtIndex(0)!.text)
          
                performSegueWithIdentifier("toMaiViewFromPay", sender: nil)
                
                break;
            default:
                
                
                
                break;
                //Some code here..
                
            }
        }
    }
    

    
    
    //MARK: UITextField delegates
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textViewDidChange(textView: UITextView) {
        placeholderLabel.hidden = textView.text.characters.count != 0
    }
    
    @IBAction func ratingChange(sender: AnyObject) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            rating = "1";
        case 1:
            rating = "2";
        case 2:
             rating = "3";
        case 3:
             rating = "4";
        case 4:
             rating = "5";
        default:
            break; 
        }
        
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
        print("Omise oFail")
    }
    
    func omiseOnSucceededToken(token1: Token?) {
        
        self.token = token1
        //handle success
        if let token = token1 {
            
            let brand : String = token.tokenId
            
            //your code here
            print("Omise ok with \(brand)")
            
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
    
    // MARK: FloatRatingViewDelegate
    
    func floatRatingView(ratingView: FloatRatingView, isUpdating rating1:Float) {
      //  self.liveLabel.text = NSString(format: "%.2f", self.floatRatingView.rating) as String
    }
    
    func floatRatingView(ratingView: FloatRatingView, didUpdate rating1: Float) {
        rating = NSString(format: "%d", Int(self.floatRatingView.rating)) as String
    }

    
    
  
}


extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// - returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joinWithSeparator("&")
    }
    
}

extension String {
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        characterSet.addCharactersInString("-._~")
        
        return stringByAddingPercentEncodingWithAllowedCharacters(characterSet)
    }
}




