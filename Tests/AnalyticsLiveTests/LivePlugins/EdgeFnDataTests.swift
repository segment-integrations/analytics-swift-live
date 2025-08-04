//
//  EdgeFnDataTests.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 7/14/25.
//

import Foundation
import XCTest
@testable import Segment
@testable import Substrata
@testable import AnalyticsLive

/**
 Dedicated tests for EdgeFunction data handling logic.
 These tests specifically target the setEdgeFnData method and related download logic
 to ensure completion callbacks are ALWAYS called and edge cases are handled properly.
 */
class EdgeFunctionDataHandlingTests: XCTestCase {
    
    // Use the exact same URL strings that will be put in test data
    let validDownloadURLString = "http://segment.com/bundles/testbundle.js"
    let invalidDownloadURLString = "http://error.com/bundles/testbundle.js"
    let malformedURLString = "not-a-valid-url-at-all"
    
    var livePlugins: LivePlugins!
    
    override func setUpWithError() throws {
        // Setup mock network handling - following the exact pattern from BundlerTests
        Bundler.sessionConfig = URLSessionConfiguration.ephemeral
        Bundler.sessionConfig.protocolClasses = [URLProtocolMock.self]
        
        let dataFile = bundleTestFile(file: "testbundle.js")
        let bundleData = try Data(contentsOf: dataFile!)
        
        // Create URLs from the exact strings we'll use in test data
        let validURL = URL(string: validDownloadURLString)!
        let errorURL = URL(string: invalidDownloadURLString)!
        let malformedURL = URL(string: malformedURLString)! // this surprisingly works lol.
        
        URLProtocolMock.testURLs = [
            validURL: .success(bundleData),
            errorURL: .failure(NetworkError.failed(URLError.cannotLoadFromNetwork)),
            malformedURL: .failure(NetworkError.failed(URLError.badURL))
        ]
        
        // Clear any existing cache
        LivePlugins.clearCache()
        
        // Create a fresh LivePlugins instance
        livePlugins = LivePlugins(fallbackFileURL: bundleTestFile(file: "testbundle.js"))
    }
    
    override func tearDownWithError() throws {
        Bundler.sessionConfig = URLSessionConfiguration.default
        LivePlugins.clearCache()
        livePlugins = nil
    }
    
    // MARK: - Completion Callback Guarantee Tests
    
    func testCompletionCalledWithNilData() throws {
        let expectation = XCTestExpectation(description: "Completion called with nil data")
        
        livePlugins.setEdgeFnData(nil) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCompletionCalledWithInvalidDataType() throws {
        let expectation = XCTestExpectation(description: "Completion called with invalid data type")
        
        let invalidData: [AnyHashable: Any] = ["someKey": 123] // Not a string dict
        
        livePlugins.setEdgeFnData(invalidData) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCompletionCalledWithMissingVersionKey() throws {
        let expectation = XCTestExpectation(description: "Completion called with missing version")
        
        let dataWithoutVersion: [String: Any] = [
            "downloadURL": "http://example.com/bundle.js"
            // Missing version key
        ]
        
        livePlugins.setEdgeFnData(dataWithoutVersion) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCompletionCalledWithMissingDownloadURLKey() throws {
        let expectation = XCTestExpectation(description: "Completion called with missing downloadURL")
        
        let dataWithoutURL: [String: Any] = [
            "version": 1
            // Missing downloadURL key
        ]
        
        livePlugins.setEdgeFnData(dataWithoutURL) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCompletionCalledWithInvalidURLString() throws {
        let expectation = XCTestExpectation(description: "Completion called with invalid URL")
        
        let dataWithInvalidURL: [String: Any] = [
            "version": 1,
            "downloadURL": 12345 // Not a string!
        ]
        
        livePlugins.setEdgeFnData(dataWithInvalidURL) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCompletionCalledWithEmptyURLString() throws {
        let expectation = XCTestExpectation(description: "Completion called with empty URL")
        
        let dataWithEmptyURL: [String: Any] = [
            "version": 1,
            "downloadURL": "" // Empty string - should disable bundle
        ]
        
        livePlugins.setEdgeFnData(dataWithEmptyURL) { success in
            XCTAssertTrue(success) // Empty URL is treated as "disable" = success
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCompletionCalledWithMalformedURL() throws {
        let expectation = XCTestExpectation(description: "Completion called with malformed URL")
        
        let dataWithBadURL: [String: Any] = [
            "version": 1,
            "downloadURL": "not-a-valid-url-at-all"
        ]
        
        livePlugins.setEdgeFnData(dataWithBadURL) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Version Comparison Tests
    
    func testFirstTimeInstallTriggersDownload() throws {
        let expectation = XCTestExpectation(description: "First install triggers download")
        
        let newData: [String: Any] = [
            "version": 1,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(newData) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNewerVersionTriggersDownload() throws {
        // First, install version 1
        let firstExpectation = XCTestExpectation(description: "Install version 1")
        
        let initialData: [String: Any] = [
            "version": 1,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(initialData) { success in
            XCTAssertTrue(success)
            firstExpectation.fulfill()
        }
        
        wait(for: [firstExpectation], timeout: 5.0)
        
        // Now try to install version 2
        let secondExpectation = XCTestExpectation(description: "Install version 2")
        
        let newerData: [String: Any] = [
            "version": 2,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(newerData) { success in
            XCTAssertTrue(success)
            secondExpectation.fulfill()
        }
        
        wait(for: [secondExpectation], timeout: 5.0)
    }
    
    func testSameVersionSkipsDownload() throws {
        // First, install version 1
        let firstExpectation = XCTestExpectation(description: "Install version 1")
        
        let initialData: [String: Any] = [
            "version": 1,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(initialData) { success in
            XCTAssertTrue(success)
            firstExpectation.fulfill()
        }
        
        wait(for: [firstExpectation], timeout: 5.0)
        
        // Now try to install same version again
        let secondExpectation = XCTestExpectation(description: "Skip same version")
        
        let sameData: [String: Any] = [
            "version": 1,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(sameData) { success in
            XCTAssertTrue(success) // Should succeed but skip download
            secondExpectation.fulfill()
        }
        
        wait(for: [secondExpectation], timeout: 1.0) // Should be fast since no download
    }
    
    func testOlderVersionSkipsDownload() throws {
        // First, install version 2
        let firstExpectation = XCTestExpectation(description: "Install version 2")
        
        let newerData: [String: Any] = [
            "version": 2,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(newerData) { success in
            XCTAssertTrue(success)
            firstExpectation.fulfill()
        }
        
        wait(for: [firstExpectation], timeout: 5.0)
        
        // Now try to "downgrade" to version 1
        let secondExpectation = XCTestExpectation(description: "Skip older version")
        
        let olderData: [String: Any] = [
            "version": 1,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(olderData) { success in
            XCTAssertTrue(success) // Should succeed but skip download
            secondExpectation.fulfill()
        }
        
        wait(for: [secondExpectation], timeout: 1.0) // Should be fast since no download
    }
    
    // MARK: - Network Failure Tests
    
    func testNetworkFailureCallsCompletion() throws {
        let expectation = XCTestExpectation(description: "Network failure calls completion")
        
        let dataWithFailingURL: [String: Any] = [
            "version": 1,
            "downloadURL": invalidDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(dataWithFailingURL) { success in
            XCTAssertFalse(success) // Should fail due to network error
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Edge Case Tests
    
    func testInvalidVersionNumbersHandledGracefully() throws {
        let expectation = XCTestExpectation(description: "Invalid version numbers handled")
        
        let dataWithBadVersion: [String: Any] = [
            "version": "not-a-number",
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(dataWithBadVersion) { success in
            // Should handle gracefully - version will default to 0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConcurrentCallsHandledSafely() throws {
        let expectation1 = XCTestExpectation(description: "First call completes")
        let expectation2 = XCTestExpectation(description: "Second call completes")
        
        let data1: [String: Any] = [
            "version": 1,
            "downloadURL": validDownloadURLString
        ]
        
        let data2: [String: Any] = [
            "version": 2,
            "downloadURL": validDownloadURLString
        ]
        
        // Fire both calls simultaneously
        livePlugins.setEdgeFnData(data1) { success in
            expectation1.fulfill()
        }
        
        livePlugins.setEdgeFnData(data2) { success in
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }
    
    // MARK: - Cache and UserDefaults Tests
    
    func testUserDefaultsUpdatedOnSuccessfulDownload() throws {
        let expectation = XCTestExpectation(description: "UserDefaults updated")
        
        let testData: [String: Any] = [
            "version": 42,
            "downloadURL": validDownloadURLString
        ]
        
        livePlugins.setEdgeFnData(testData) { success in
            XCTAssertTrue(success)
            
            // Verify UserDefaults was updated
            let savedData = UserDefaults.standard.dictionary(forKey: "LivePlugin")
            XCTAssertNotNil(savedData)
            XCTAssertEqual(savedData?["version"] as? Int, 42)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Helper Extensions

extension EdgeFunctionDataHandlingTests {
    
    /// Helper to get test bundle file URLs - matching the working pattern
    private func bundleTestFile(file: String) -> URL? {
        // This should match however bundleTestFile is implemented in the working tests
        return Bundle.module.url(forResource: file, withExtension: nil)
    }
}
