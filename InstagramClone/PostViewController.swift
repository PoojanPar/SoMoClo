//  PostViewController.swift

import Foundation

class PostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    let databaseService = DatabaseService()
    
    var activityIndicator = UIActivityIndicatorView()
    
    let S3BucketName = "instagram-clone-project-ver1-1" //this needs to be moved to a settings file
    
    @IBOutlet var imagePost: UIImageView!
    
    @IBOutlet var setMessage: UITextField!
    
    @IBAction func chooseAnImage(_ sender: AnyObject) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        
        self.present(image, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.dismiss(animated: true, completion:nil)
        imagePost.image = image
    }
    
    @IBAction func postAnImage(_ sender: AnyObject) {
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let S3UploadKeyName = UUID().uuidString + ".png"
        var location = ""
        
        if let data = UIImagePNGRepresentation(self.imagePost.image!) {
            location = databaseService.getDocumentsDirectory().appendingPathComponent(S3UploadKeyName)
            try? data.write(to: URL(fileURLWithPath: location), options: [.atomic])
        } else {
            self.displayAlert("Error", message: "Could not process selected image. UIImagePNGRepresentation failed.")
            return
        }
        
        let uploadFileUrl = URL(fileURLWithPath: location)
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: Progress) in
            print("Progress is: %f", progress.fractionCompleted)
        }
        
        let completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                self.activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                
                if error != nil {
                    print(error)
                    self.displayAlert("Could not post image", message: "Please try again later")
                } else {
                    self.savePostToDatabase(self.S3BucketName, key: S3UploadKeyName)
                }
            })
            } as AWSS3TransferUtilityUploadCompletionHandlerBlock
        
        
        let transferUtility = AWSS3TransferUtility.default()
        
        transferUtility.uploadFile(uploadFileUrl, bucket: S3BucketName, key: S3UploadKeyName, contentType: "image/png", expression: expression, completionHander: completionHandler).continue({ (task) -> AnyObject! in
            if let error = task.error {
                print("Error: %@", error.localizedDescription);
                //self.statusLabel.text = "Failed"
            }
            if let exception = task.exception {
                print("Exception: %@", exception.description);
                //self.statusLabel.text = "Failed"
            }
            if let _ = task.result {
                print("Upload Started")
            }
            
            return nil;
        })
    }
    
    func savePostToDatabase(_ bucket: String, key: String) {
        let identityId = credentialsProvider.identityId! as String
        let mapper = AWSDynamoDBObjectMapper.default()
        let post = Post()
        
        post?.id = UUID().uuidString
        post?.bucket = bucket
        post?.filename = key
        post?.userId = identityId
        
        if (!self.setMessage.text!.isEmpty) {
            post?.message = self.setMessage.text!
        } else {
            post?.message = nil //we cannot save a message that is an empty string
        }
        
        mapper.save(post!).continue({ (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error )
            }
            
            if (task.exception != nil) {
                print(task.exception )
            }
            
            DispatchQueue.main.async(execute: {
                self.displayAlert("Saved", message: "Your post has been saved")
            })
            
            return nil
        })
    }
    
    func displayAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction((UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
        })))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicator)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
