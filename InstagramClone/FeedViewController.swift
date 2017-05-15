//
//  FeedViewController.swift
//  InstagramClone
//


import Foundation

class FeedViewController: UITableViewController {
    
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    let databaseService = DatabaseService()
    var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
    
    var imageFiles = [Post]()
    
    func refresh() {
        
        let identityId = credentialsProvider.identityId! as String
        let mapper = AWSDynamoDBObjectMapper.default()
        
        self.imageFiles.removeAll(keepingCapacity: true)
        
        databaseService.findFollowings(identityId, map: mapper).continue({ (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil) {
                print(task.exception)
            }
            
            if (task.result != nil) {
                for item in task.result as! [Follower] {
                    let result = self.getPosts(userId: item.following, map: mapper)
                    
                    result.continue({ (task:AWSTask) -> AnyObject? in
                        let posts = task.result as! [Post]
                        
                        for post in posts {
                            self.imageFiles.append(post)
                        }
                        
                        DispatchQueue.main.async(execute: {
                            self.tableView.reloadData()
                        })
                        
                        return nil
                    })
                }
            }
            
            return nil
        })
    }
    
    func getPosts(userId: String, map: AWSDynamoDBObjectMapper) -> AWSTask<AnyObject> {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "userId = :userId"
        scan.expressionAttributeValues = [":userId":userId]
        
        return map.scan(Post.self, expression: scan).continue({ (task: AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil){
                print(task.exception)
            }
            
            if (task.result != nil) {
                let result : AWSDynamoDBPaginatedOutput = task.result!
                return result.items as! [Post] as AnyObject?
            }
            
            return nil
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        return imageFiles.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell
 {
        let post = imageFiles[indexPath.row]
        let myCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! cell
        
        let currentLocation = self.databaseService.getDocumentsDirectory().appendingPathComponent(post.filename)
        let manager = FileManager.default
        
        if (manager.fileExists(atPath: currentLocation)) {
            myCell.postedImage.image = UIImage(contentsOfFile: currentLocation)
        } else {
            let transferUtility = AWSS3TransferUtility.default()
            
            let expression = AWSS3TransferUtilityDownloadExpression()
            expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: Progress) in
                print("Download Progress is: %f", progress.fractionCompleted)
            }
            
            self.completionHandler = { (task, location, data, error) -> Void in
                
                DispatchQueue.main.async(execute: {
                    myCell.postedImage.image = UIImage(data: data!)
                    
                    if let imagedata = UIImagePNGRepresentation(myCell.postedImage.image!) {
                        let location = self.databaseService.getDocumentsDirectory().appendingPathComponent(post.filename)
                        
                        do {
                            try imagedata.write(to: URL(fileURLWithPath: location), options: .atomic)
                        } catch let error {
                            print(error) 
                        }
                    }
                })
            }
            
            transferUtility.downloadData(fromBucket: post.bucket+"-resized", key: post.filename, expression: expression, completionHander: completionHandler);
        }
        
        
        myCell.message.text = post.message != nil ? post.message : ""
        
        return myCell
    }
}
