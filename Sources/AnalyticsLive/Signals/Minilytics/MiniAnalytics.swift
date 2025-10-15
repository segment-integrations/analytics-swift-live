//
//  File.swift
//  
//
//  Created by Brandon Sneed on 3/8/24.
//

import Foundation
import Segment

enum HTTPClientErrors: Error {
    case badSession
    case failedToOpenBatch
    case statusCode(code: Int)
    case unknown(error: Error)
}

enum AnalyticsError: Error {
    case storageUnableToCreate(String)
    case storageUnableToWrite(String)
    case storageUnableToRename(String)
    case storageUnableToOpen(String)
    case storageUnableToClose(String)
    case storageInvalid(String)
    case storageUnknown(Error)

    case networkUnexpectedHTTPCode(Int)
    case networkServerLimited(Int)
    case networkServerRejected(Int)
    case networkUnknown(Error)
    case networkInvalidData

    case jsonUnableToSerialize(Error)
    case jsonUnableToDeserialize(Error)
    case jsonUnknown(Error)

    case pluginError(Error)
    
    case enrichmentError(String)
}

internal struct MiniTrackEvent: RawEvent {
    @Noncodable var enrichments: [EnrichmentClosure]? = nil
    var context: JSON? = nil
    var integrations: JSON? = nil
    var metrics: [JSON]? = nil
    var type: String? = "track"
    var anonymousId: String?
    var messageId: String?
    var userId: String?
    var timestamp: String?
    
    var event: String = "Segment Signal Generated"
    let properties: JSON
    var _metadata: Segment.DestinationMetadata?
}

internal class MiniAnalytics {
    let session: URLSession
    let apiHost: String
    let storage: TransientDB
    
    @Atomic var flushing: Bool = false
    
    struct LocalUserInfo {
        var userId: String? = nil
        var anonymousId: String? = nil
    }
    @Atomic var userInfo = LocalUserInfo()
    
    // used for testing only.
    internal static var observer: ((_ in: any RawSignal, _ out: MiniTrackEvent) -> Void)? = nil
    
    init(writeKey: String, apiHost: String) {
        self.apiHost = apiHost
        self.session = Self.configuredSession()
        
        let fileStore = DirectoryStore(
            configuration:
                DirectoryStore.Configuration(
                    writeKey: writeKey,
                    storageLocation: Self.signalStorageDirectory(writeKey: writeKey),
                    baseFilename: "segment-signals",
                    maxFileSize: 475000,
                    indexKey: "signalFileIndex")
        )
        self.storage = TransientDB(store: fileStore, asyncAppend: true)
    }
    
    func stateSubscriber(userInfo: UserInfo) {
        _userInfo.set(LocalUserInfo(userId: userInfo.userId, anonymousId: userInfo.anonymousId))
    }
    
    func track(signal: any RawSignal, obfuscate: Bool) {
        let input = signal
        var signal = signal
        
        if obfuscate, let obf = signal as? JSONObfuscation {
            signal = obf.obfuscated()
        }
        
        guard let props = try? JSON(with: signal) else { return }
        
        let userInfo = self.userInfo
        let anonId = userInfo.anonymousId
        let userId = userInfo.userId
        let messageId = UUID().uuidString
        let timestamp = Date().iso8601()
        
        let track = MiniTrackEvent(
            anonymousId: anonId,
            messageId: messageId,
            userId: userId,
            timestamp: timestamp,
            properties: props)
        
        storage.append(data: track)
        
        if let observer = Self.observer {
            observer(input, track)
        }
    }
    
    func flush() {
        guard flushing == false else { return }
        guard let pending = storage.fetch() else { return }
        guard let urls = pending.dataFiles else { return }
        
        _flushing.set(true)
        
        let group = DispatchGroup()
        group.enter()
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self else { return }
            _flushing.set(false)
        }
        
        for url in urls {
            group.enter()
            startBatchUpload(batch: url) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(_):
                    storage.remove(data: [url])
                case .failure(HTTPClientErrors.statusCode(code: 400)):
                    storage.remove(data: [url])
                default:
                    break
                }
                
                Analytics.segmentLog(message: "Processed: \(url.lastPathComponent)", kind: .debug)
                group.leave()
            }
        }
        
        group.leave()
    }
}

// MARK: - Network Stuff

extension MiniAnalytics {
    //private static let defaultAPIHost = "signals.segment.io/v1"
    //private static let defaultAPIHost = "signals.segment.build/v1"
    
    func segmentURL(for host: String, path: String) -> URL? {
        let s = "https://\(host)\(path)"
        let result = URL(string: s)
        return result
    }
    
    @discardableResult
    func startBatchUpload(batch: URL, completion: @escaping (_ result: Result<Bool, Error>) -> Void) -> URLSessionDataTask? {
        guard let uploadURL = segmentURL(for: self.apiHost, path: "/b") else {
            Analytics.reportInternalError(HTTPClientErrors.failedToOpenBatch, fatal: false)
            completion(.failure(HTTPClientErrors.failedToOpenBatch))
            return nil
        }
          
        let urlRequest = configuredRequest(for: uploadURL, method: "POST")

        let dataTask = session.uploadTask(with: urlRequest, fromFile: batch) { [weak self] (data, response, error) in
            guard let self else { return }
            handleResponse(data: data, response: response, error: error, completion: completion)
        }
        
        dataTask.resume()
        return dataTask
    }
    
    internal func configuredRequest(for url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        request.httpMethod = method
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("analytics-ios/\(Analytics.version())", forHTTPHeaderField: "User-Agent")
        request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        return request
    }
    
    internal static func configuredSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 2
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        return session
    }
    
    private func handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (_ result: Result<Bool, Error>) -> Void) {
        if let error = error {
            Analytics.segmentLog(message: "Error uploading request \(error.localizedDescription).", kind: .error)
            Analytics.reportInternalError(AnalyticsError.networkUnknown(error), fatal: false)
            completion(.failure(HTTPClientErrors.unknown(error: error)))
        } else if let httpResponse = response as? HTTPURLResponse {
            switch (httpResponse.statusCode) {
            case 1..<300:
                completion(.success(true))
                return
            case 300..<400:
                Analytics.reportInternalError(AnalyticsError.networkUnexpectedHTTPCode(httpResponse.statusCode), fatal: false)
                completion(.failure(HTTPClientErrors.statusCode(code: httpResponse.statusCode)))
            case 429:
                Analytics.reportInternalError(AnalyticsError.networkServerLimited(httpResponse.statusCode), fatal: false)
                completion(.failure(HTTPClientErrors.statusCode(code: httpResponse.statusCode)))
            default:
                Analytics.reportInternalError(AnalyticsError.networkServerRejected(httpResponse.statusCode), fatal: false)
                completion(.failure(HTTPClientErrors.statusCode(code: httpResponse.statusCode)))
            }
        }
    }
}

// MARK: - Storage Stuff
extension MiniAnalytics {
    static internal func signalStorageDirectory(writeKey: String) -> URL {
        #if os(tvOS) || os(macOS)
        let searchPathDirectory = FileManager.SearchPathDirectory.cachesDirectory
        #else
        let searchPathDirectory = FileManager.SearchPathDirectory.documentDirectory
        #endif
        
        let urls = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask)
        let docURL = urls[0]
        let segmentURL = docURL.appendingPathComponent("segment/signals/\(writeKey)/")
        // try to create it, will fail if already exists, nbd.
        // tvOS, watchOS regularly clear out data.
        try? FileManager.default.createDirectory(at: segmentURL, withIntermediateDirectories: true, attributes: nil)
        return segmentURL
    }

}
