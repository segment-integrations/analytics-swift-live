//
//  BundlerTests.swift
//  
//
//  Created by Brandon Sneed on 5/9/22.
//

import XCTest
@testable import EdgeFn;

class BundlerTests: XCTestCase {
    let downloadURL = URL(string: "http://segment.com/bundles/testbundle.js")!
    let errorURL = URL(string:"http://error.com/bundles/testbundle.js")
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // setup our mock network handling.
        Bundler.sessionConfig = URLSessionConfiguration.ephemeral
        Bundler.sessionConfig.protocolClasses = [URLProtocolMock.self]
        
        let dataFile = bundleTestFile(file: "testbundle.js")
        let bundleData = try Data(contentsOf: dataFile!)
        
        URLProtocolMock.testURLs = [
            downloadURL: .success(bundleData),
            errorURL: .failure(NetworkError.failed(URLError.cannotLoadFromNetwork))
        ]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        // set our network handling back to default.
        Bundler.sessionConfig = URLSessionConfiguration.default
    }

    func testLocalBundleFolder() throws {
        let folderURL = Bundler.getLocalBundleFolderURL()
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)
        XCTAssertTrue(exists)
        XCTAssertTrue(isDirectory.boolValue)
        try? FileManager.default.removeItem(at: folderURL)
    }
    
    func testLocalBundleFile() throws {
        let folderURL = Bundler.getLocalBundleFolderURL()
        let fileURL = Bundler.getLocalBundleURL(bundleName: "testbundle.js")
        
        let folderString = folderURL.absoluteString
        let fileString = fileURL.absoluteString
        
        XCTAssertNotEqual(fileString, folderString)
        XCTAssertTrue(fileString.contains(folderString))
    }

    func testBundleLocal() throws {
        let loadingDone = expectation(description: "bundle downloaded")
        
        let folderURL = Bundler.getLocalBundleFolderURL()
        let fileURL = Bundler.getLocalBundleURL(bundleName: "testbundle.js")
        let localTestFile = bundleTestFile(file: "testbundle.js")
        
        Bundler.download(url: localTestFile, to: fileURL) { _ in
            loadingDone.fulfill()
        }
        
        wait(for: [loadingDone], timeout: 5)
        
        let fileData = try! String(contentsOf: fileURL)
        
        XCTAssertTrue(fileData.contains("TestSuper"))
        
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: folderURL)
    }

    func testBundleDownload() throws {
        let downloadDone = expectation(description: "bundle downloaded")
        
        let folderURL = Bundler.getLocalBundleFolderURL()
        let fileURL = Bundler.getLocalBundleURL(bundleName: "testbundle.js")
        
        Bundler.download(url: downloadURL, to: fileURL) { _ in
            downloadDone.fulfill()
        }
        
        wait(for: [downloadDone], timeout: 5)
        
        let fileData = try! String(contentsOf: fileURL)
        
        XCTAssertTrue(fileData.contains("TestSuper"))
        
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: folderURL)
    }

    func testBundleDownloadError() throws {
        let downloadDone = expectation(description: "bundle downloaded")
        
        let folderURL = Bundler.getLocalBundleFolderURL()
        let fileURL = Bundler.getLocalBundleURL(bundleName: "testbundle.js")
        
        Bundler.download(url: errorURL, to: fileURL) { success in
            XCTAssertFalse(success)
            downloadDone.fulfill()
        }
        
        wait(for: [downloadDone], timeout: 5)
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: folderURL)
    }

}
