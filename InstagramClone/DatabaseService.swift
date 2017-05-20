//  DatabaseService.swift

import Foundation

class DatabaseService {
    
    func findFollowings(_ follower: String, map: AWSDynamoDBObjectMapper) -> AWSTask<AnyObject>
    {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "follower = :val"
        scan.expressionAttributeValues = [":val":follower]
        
        return map.scan(Follower.self, expression: scan).continue({ (task: AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil){
                print(task.exception)
            }
            
            if (task.result != nil) {
                let result : AWSDynamoDBPaginatedOutput? = task.result
                return result?.items as! [Follower] as AnyObject?
            }
            
            return nil
        })
    }
    
    func findFollower(_ follower: String, following: String, map: AWSDynamoDBObjectMapper) -> AWSTask<AnyObject> {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "follower = :follower AND following = :following"
        scan.expressionAttributeValues = [":follower":follower,":following":following]
        
        return map.scan(Follower.self, expression: scan).continue({ (task: AWSTask) -> AnyObject? in
            if (task.error != nil) {
                print(task.error)
            }
            
            if (task.exception != nil){
                print(task.exception)
            }
            
            if (task.result != nil) {
                let result : AWSDynamoDBPaginatedOutput? = task.result
                return result?.items as! [Follower] as AnyObject?
            }
            
            return nil
        })
        
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
}
