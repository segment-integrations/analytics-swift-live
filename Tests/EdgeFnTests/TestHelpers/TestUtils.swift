//
//  File.swift
//  
//
//  Created by Brandon Sneed on 5/9/22.
//

import Foundation

enum NetworkError: Error {
    case failed(URLError.Code)
}

func bundleTestFile(file: String) -> URL? {
    let bundle = Bundle.module
    if let pathURL = bundle.url(forResource: file, withExtension: nil) {
        return pathURL
    }
    return nil
}
