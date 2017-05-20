//  ViewController.swift

import UIKit
import GoogleSignIn

class ViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, AWSIdentityProviderManager {
    var googleIdToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
    }

    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            googleIdToken = user.authentication.idToken
            
            signInToCognito(user);
        } else {
            print("\(error.localizedDescription)")
        }

    }

    
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: NSError!){
        if (error == nil) {
            googleIdToken = user.authentication.idToken

            signInToCognito(user);
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func logins() -> AWSTask<NSDictionary> { 
        let result = NSDictionary(dictionary: [AWSIdentityProviderGoogle: googleIdToken])
        
        return AWSTask(result: result)
    }
    
    func signInToCognito(_ user: GIDGoogleUser!) {
        googleIdToken = user.authentication.idToken
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .usEast1, identityPoolId: "us-east-1:b7438204-078e-4594-a907-8f75289d5382", identityProviderManager: self)
        
        let configuration = AWSServiceConfiguration(region: .usEast1, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration		

        credentialsProvider.getIdentityId().continue({ (task:AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
                return nil
            }
            
            let syncClient = AWSCognito.default()
            let dataset = syncClient?.openOrCreateDataset("instagramDataSet")
            
            dataset?.setString(user.profile.email, forKey: "email")
            dataset?.setString(user.profile.name, forKey: "name")
            
            let result = dataset?.synchronize()
            
            result?.continue({ (task:AWSTask) -> AnyObject? in
                if task.error != nil {
                    print(task.error)
                } else {
                    DispatchQueue.main.async(execute: {
                        self.performSegue(withIdentifier: "login", sender: self)
                    })
                }
                
                return nil
            })
            
            return nil
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

