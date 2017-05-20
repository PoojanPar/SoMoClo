//  Post.swift

import Foundation

class Post : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var id: String = ""
    var message: String? = nil
    var userId: String = ""
    var bucket: String = ""
    var filename: String = ""
    
    override init!() {
        super.init()
    }
    
    
    override init(dictionary dictionaryValue: [AnyHashable: Any]!, error: ()) throws {
        super.init()
        
        if dictionaryValue["id"] != nil {
            id = dictionaryValue["id"] as! String
        }
        
        if dictionaryValue["bucket"] != nil {
            bucket = dictionaryValue["bucket"] as! String
        }
        
        if dictionaryValue["filename"] != nil {
            filename = dictionaryValue["filename"] as! String
        }
        
        if dictionaryValue["userId"] != nil {
            userId = dictionaryValue["userId"] as! String
        }
        
        message = dictionaryValue["message"] != nil ? dictionaryValue["message"] as! String : ""
    }
    
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String {
        return "Posts"
    }
    
    class func hashKeyAttribute() -> String {
        return "id"
    }
}
