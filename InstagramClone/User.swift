import Foundation

class User : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var id  : String = ""
    var name   : String = ""
    
    override init!() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [AnyHashable: Any]!, error: ()) throws {
        super.init()
        id = dictionaryValue["id"] as! String
        name = dictionaryValue["name"] as! String
    }
    
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) not implemented")
    }
    
    class func dynamoDBTableName() -> String {
        return "Users"
    }
    
    class func hashKeyAttribute() -> String {
        return "id"
    }
}
