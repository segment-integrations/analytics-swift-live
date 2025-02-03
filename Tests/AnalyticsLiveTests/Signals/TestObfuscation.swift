//
//  TestObfuscation.swift
//  
//
//  Created by Brandon Sneed on 3/11/24.
//

import XCTest
@testable import AnalyticsLive
@testable import Segment

final class TestObfuscation: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testObfuscation() throws {
        let example = """
        {
            "messageId": "22599A53-7AF0-4AF2-8A48-A6B2B3C2E31B",
            "type": "track",
            "anonymousId": "4A748B2B-8AB5-450E-9766-2F667AA0EC6A",
            "timestamp": "2024-03-11T18:08:31.682Z",
            "properties": {
            "data": {
              "action": "loaded",
              "identifier": "Favorites Loaded",
              "data": {
                "saveKey": "Favorites",
                "someBool": true,
                "someNumber": 1234.56,
                "products": [
                  "Dynamo",
                  "Aura",
                  "My-Fancy-pants-Product's are Here!"
                ]
              }
            },
            "type": "localData",
            "anonymousId": "4A748B2B-8AB5-450E-9766-2F667AA0EC6A",
            "timestamp": "2024-03-11T18:08:30.424Z",
            "index": 68
            },
            "event": "Segment Signal Generated"
        }
        """
        
        let jsonObject = try! JSONSerialization.jsonObject(with: example.data(using: .utf8)!)
        
        let json = try! JSON(jsonObject)
        
        struct TestStruct: JSONObfuscation {
            func obfuscated() -> any RawSignal {
                return LocalDataSignal(action: .loaded, identifier: "1234")
            }
        }
        
        let ts = TestStruct()
        let result = ts.obfuscate(json)!
        print(result.prettyPrint())
    }

}
