//
//  URLMatcher.swift
//  AnalyticsLive
//
//  Fast glob pattern matcher without regex
//

import Foundation

class URLMatcher {
    private let pattern: String
    private let hostPattern: String
    private let pathPattern: String?
    
    init(pattern: String) {
        let lowercased = pattern.lowercased()
        self.pattern = lowercased
        
        // Handle edge cases
        guard !lowercased.isEmpty else {
            self.hostPattern = ""
            self.pathPattern = nil
            return
        }
        
        // Special case for just "**"
        if lowercased == "**" {
            self.hostPattern = "**"
            self.pathPattern = nil
            return
        }
        
        // Split into host and path parts - use the lowercased version!
        let parts = lowercased.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        
        if parts.isEmpty {
            self.hostPattern = ""
            self.pathPattern = nil
            return
        }
        
        // Store host pattern
        self.hostPattern = String(parts[0])
        
        // Store path pattern if it exists
        if parts.count > 1 {
            self.pathPattern = String(parts[1])
        } else {
            self.pathPattern = nil
        }
    }
    
    func matches(_ urlString: String) -> Bool {
        // Handle empty string
        if urlString.isEmpty {
            return false
        }
        
        // Handle empty pattern
        if pattern.isEmpty {
            return false
        }
        
        // Parse the URL - be strict about URL format
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              !scheme.isEmpty,
              let host = url.host,
              !host.isEmpty else {
            return false
        }
        
        // Special case for "**" pattern - matches everything
        if hostPattern == "**" {
            return true
        }
        
        // Check host match
        if !matchHost(pattern: hostPattern, host: host.lowercased()) {
            return false
        }
        
        // If no path pattern specified, match any path
        guard let pathPattern = pathPattern else {
            return true
        }
        
        // Get and normalize the URL path
        let urlPath = url.path
        let normalizedPath: String
        
        if urlPath == "/" {
            normalizedPath = ""
        } else if urlPath.hasPrefix("/") {
            normalizedPath = String(urlPath.dropFirst())
        } else {
            normalizedPath = urlPath
        }
        
        // Match the path
        return matchPath(pattern: pathPattern, path: normalizedPath.lowercased())
    }
    
    private func matchHost(pattern: String, host: String) -> Bool {
        let patternParts = pattern.split(separator: ".").map(String.init)
        let hostParts = host.split(separator: ".").map(String.init)
        
        // Host matching doesn't support globstar, only single wildcards
        if patternParts.count != hostParts.count {
            return false
        }
        
        for (p, h) in zip(patternParts, hostParts) {
            if !matchSimplePattern(pattern: p, text: h) {
                return false
            }
        }
        
        return true
    }
    
    private func matchPath(pattern: String, path: String) -> Bool {
        // Handle special patterns
        if pattern.isEmpty {
            // Pattern "blah.com/" expects root
            return path.isEmpty
        }
        
        // For non-wildcard patterns, handle trailing slash tolerance
        if !pattern.contains("*") {
            // Exact match
            if path == pattern {
                return true
            }
            // Handle trailing slash tolerance
            if path.hasSuffix("/") && String(path.dropLast()) == pattern {
                return true
            }
            if pattern.hasSuffix("/") && String(pattern.dropLast()) == path {
                return true
            }
            return false
        }
        
        // Handle file extension patterns like "**/*.jpg"
        if let dotIndex = pattern.lastIndex(of: "."),
           pattern.contains("*") {
            // Check if path ends with the required extension
            let ext = String(pattern[dotIndex...])
            if pattern.hasPrefix("**/") && pattern.dropFirst(3).firstIndex(of: "/") == nil {
                // Pattern is like "**/*.jpg" - just check extension
                return path.hasSuffix(ext)
            }
        }
        
        // Split into segments for matching
        let patternSegments = pattern.split(separator: "/").map(String.init)
        let pathSegments = path.isEmpty ? [] : path.split(separator: "/").map(String.init)
        
        return matchSegments(pattern: patternSegments, path: pathSegments)
    }
    
    private func matchSegments(pattern: [String], path: [String]) -> Bool {
        var pIndex = 0
        var tIndex = 0
        var lastGlobstarP = -1
        var lastGlobstarT = -1
        
        while pIndex < pattern.count || tIndex < path.count {
            if pIndex < pattern.count {
                let p = pattern[pIndex]
                
                if p == "**" {
                    // Globstar matches zero or more segments
                    lastGlobstarP = pIndex
                    lastGlobstarT = tIndex
                    pIndex += 1
                    continue
                }
                
                if tIndex < path.count {
                    // Try to match current segment
                    if matchSimplePattern(pattern: p, text: path[tIndex]) {
                        pIndex += 1
                        tIndex += 1
                        continue
                    }
                }
            }
            
            // No match, try to backtrack to last globstar
            if lastGlobstarP >= 0 && lastGlobstarT < path.count {
                // Restart from globstar, consuming one more segment
                pIndex = lastGlobstarP + 1
                lastGlobstarT += 1
                tIndex = lastGlobstarT
                continue
            }
            
            // No match possible
            return false
        }
        
        return true
    }
    
    private func matchSimplePattern(pattern: String, text: String) -> Bool {
        // Handle patterns with * (but not **)
        if pattern == "*" {
            return true
        }
        
        if !pattern.contains("*") {
            return pattern == text
        }
        
        // Handle patterns like "v*", "*.jpg", "*foo*"
        let parts = pattern.split(separator: "*", omittingEmptySubsequences: false).map(String.init)
        
        var textPos = 0
        for (i, part) in parts.enumerated() {
            if part.isEmpty {
                continue
            }
            
            // Find this part in the remaining text
            let searchStart = text.index(text.startIndex, offsetBy: min(textPos, text.count))
            guard let range = text[searchStart...].range(of: part) else {
                return false
            }
            
            let foundPos = text.distance(from: text.startIndex, to: range.lowerBound)
            
            // First part must be at the beginning
            if i == 0 && foundPos != 0 {
                return false
            }
            
            // Last part must be at the end
            if i == parts.count - 1 && range.upperBound != text.endIndex {
                return false
            }
            
            textPos = foundPos + part.count
        }
        
        return true
    }
}
