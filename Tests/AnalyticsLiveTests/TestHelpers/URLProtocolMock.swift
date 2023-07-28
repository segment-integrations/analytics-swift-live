//
//  URLProtocolMock.swift
//  
//
//  Created by Brandon Sneed on 5/9/22.
//

import Foundation

class URLProtocolMock: URLProtocol {
    // this dictionary maps URLs to test data
    static var testURLs = [URL?: Result<Data, Error>]()

    // say we want to handle all types of request
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    // ignore this method; just send back what we were given
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
      guard let response = URLProtocolMock.testURLs[self.request.url] else {
        fatalError("""
          No mock response for \(request.url!). This should never happen. Check
          the implementation of `canInit(with request: URLRequest) -> Bool`.
          """
        )
      }

      // Simulate response on a background thread.
      DispatchQueue.global(qos: .default).async {
        switch response {
        case let .success(data):

          // Step 1: Simulate receiving an URLResponse. We need to do this
          // to let the client know the expected length of the data.
          let response = URLResponse(
            url: self.request.url!,
            mimeType: nil,
            expectedContentLength: data.count,
            textEncodingName: nil
          )

          self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

          // Step 2: Split data into chunks
          let chunkSize = 10
          let chunks = stride(from: 0, to: data.count, by: chunkSize).map {
            data[$0 ..< min($0 + chunkSize, data.count)]
          }

          // Step 3: Simulate received data chunk by chunk.
          for chunk in chunks {
            self.client?.urlProtocol(self, didLoad: chunk)
          }

          // Step 4: Finish loading (required).
          self.client?.urlProtocolDidFinishLoading(self)

        case let .failure(error):
          // Simulate error.
          self.client?.urlProtocol(self, didFailWithError: error)
        }
      }
    }

    // this method is required but doesn't need to do anything
    override func stopLoading() { }
}
