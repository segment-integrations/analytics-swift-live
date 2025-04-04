//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/9/22.
//

import Foundation

internal class Bundler {
    static var sessionConfig = URLSessionConfiguration.default
    
    class func getLocalBundleFolderURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var result = paths[0]
        result.appendPathComponent("segmentJSBundles")
        if let identifier = Bundle.main.bundleIdentifier {
            result.appendPathComponent(identifier)
        }
        // try to create it in case it doesn't exist.
        try? FileManager.default.createDirectory(at: result, withIntermediateDirectories: true, attributes: nil)
        return result
    }
    
    class func getLocalBundleURL(bundleName: String) -> URL {
        var result = Bundler.getLocalBundleFolderURL()
        result.appendPathComponent(bundleName)
        return result
    }
    
    class func deleteLocalBundle(bundleName: String) {
        let localURL = Bundler.getLocalBundleURL(bundleName: bundleName)
        try? FileManager.default.removeItem(at: localURL)
    }
    
    class func disableBundleURL(localURL: URL) {
        // just empties the file.
        let contents = "// live plugins are disabled."
        try? contents.write(to: localURL, atomically: true, encoding: .utf8)
    }
    
    class func download(url: URL?, to localUrl: URL, completion: @escaping (_ success: Bool) -> ()) {
        guard let url = url else {
            return
        }
        
        var success: Bool = false
        
        // if it's local, just copy it to the bundle path.
        if url.isFileURL {
            do {
                _ = try FileManager.default.copyItem(at: url, to: localUrl)
                success = true
            } catch {
                print("Error writing file \(localUrl) : \(error)")
            }
            
            completion(success)
        } else {
            let session = URLSession(configuration: sessionConfig)
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)

            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    // Success
                    do {
                        _ = try FileManager.default.replaceItemAt(localUrl, withItemAt: tempLocalUrl)
                        success = true
                    } catch (let writeError) {
                        print("Error writing file \(localUrl) : \(writeError)")
                    }
                } else {
                    if let error = error {
                        print("Failure downloading \(url), \(error.localizedDescription)");
                    } else {
                        print("Failed to download \(url)")
                    }
                }
                completion(success)
            }
            
            task.resume()
        }
    }
}
