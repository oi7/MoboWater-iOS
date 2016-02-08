//
//  SwiftRecognitionViewController.swift
//  ClarifaiApiDemo
//

import UIKit

/**
 * This view controller performs recognition using the Clarifai API.
 */
class SwiftRecognitionViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Custom Training (Alpha): to predict against a custom concept (instead of the standard
    // tag model), set this to be the name of the concept you wish to predict against. You must
    // have previously trained this concept using the same app ID and secret as above. For more
    // info on custom training, see https://github.com/Clarifai/hackathon
    static let conceptName: String? = nil
    static let conceptNamespace = "default"

    @IBOutlet weak var backgoundImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var qualityTextView: UITextView!
//    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    
    private lazy var client : ClarifaiClient =
        ClarifaiClient(appID: clarifaiClientID, appSecret: clarifaiClientSecret)
    
    @IBAction func openCamera(sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .Camera
        picker.allowsEditing = false
        picker.delegate = self
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBAction func shareButton(sender: UIButton) {
        let image = generateImage()
        
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        activity.completionWithItemsHandler = { (activityType: String?, completed: Bool, returnedItems: [AnyObject]?, activityError: NSError?) -> Void in
            if completed {
                activity.dismissViewControllerAnimated(true, completion: nil)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        presentViewController(activity, animated: true, completion: nil)
    }
    
    func generateImage() -> UIImage {
        
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }

    @IBAction func openLibrary(sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .PhotoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        self.presentViewController(picker, animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // The user picked an image. Send it Clarifai for recognition.
            imageView.image = image
            backgoundImageView.hidden = true
            textView.text = "Recognizing..."
//            button.enabled = false
            recognizeImage(image)
        }
    }

    private func recognizeImage(image: UIImage!) {
        // Scale down the image. This step is optional. However, sending large images over the
        // network is slow and does not significantly improve recognition performance.
        let size = CGSizeMake(320, 320 * image.size.height / image.size.width)
        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Encode as a JPEG.
        let jpeg = UIImageJPEGRepresentation(scaledImage, 0.9)!

        if SwiftRecognitionViewController.conceptName == nil {
            // Standard Recognition: Send the JPEG to Clarifai for standard image tagging.
            client.recognizeJpegs([jpeg]) {
                (results: [ClarifaiResult]?, error: NSError?) in
                if error != nil {
                    print("Error: \(error)\n")
                    self.textView.text = "Sorry, there was an error recognizing your image."
                } else {
                    self.textView.text = "Tags:\n" + results![0].tags.joinWithSeparator(", ")
                    let a:Double = drand48()
                    let b:String = String(format:"%f", a)
                    self.qualityTextView.text = "Quality:\n" + b
                }
//                self.button.enabled = true
            }
        } else {
            // Custom Training: Send the JPEG to Clarifai for prediction against a custom model.
            client.predictJpegs([jpeg], conceptNamespace: SwiftRecognitionViewController.conceptNamespace, conceptName: SwiftRecognitionViewController.conceptName) {
                (results: [ClarifaiPredictionResult]?, error: NSError?) in
                if error != nil {
                    print("Error: \(error)\n")
                    self.textView.text = "Sorry, there was an error running prediction on your image."
                } else {
                    self.textView.text = "Prediction score for \(SwiftRecognitionViewController.conceptName!):\n\(results![0].score)"
                }
//                self.button.enabled = true
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
