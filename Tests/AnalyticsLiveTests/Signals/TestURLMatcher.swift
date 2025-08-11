//
//  TestURLMatcher.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 8/11/25.
//
import XCTest
@testable import AnalyticsLive

class URLMatcherTests: XCTestCase {
    
    // MARK: - Simple Pattern Tests (no **)
    
    func testExactHostMatch() {
        let matcher = URLMatcher(pattern: "blah.com")
        
        XCTAssertTrue(matcher.matches("https://blah.com"))
        XCTAssertTrue(matcher.matches("https://blah.com/"))
        XCTAssertTrue(matcher.matches("https://blah.com/anything"))
        XCTAssertTrue(matcher.matches("https://blah.com/path/to/resource"))
        XCTAssertTrue(matcher.matches("http://blah.com/test"))
        
        XCTAssertFalse(matcher.matches("https://other.com"))
        XCTAssertFalse(matcher.matches("https://sub.blah.com"))
        XCTAssertFalse(matcher.matches("https://blahh.com"))
    }
    
    func testExactPathMatch() {
        let matcher = URLMatcher(pattern: "blah.com/api/users")
        
        XCTAssertTrue(matcher.matches("https://blah.com/api/users"))
        XCTAssertTrue(matcher.matches("http://blah.com/api/users"))
        // Standard glob: exact path means exact match, no extension
        XCTAssertFalse(matcher.matches("https://blah.com/api"))
        XCTAssertFalse(matcher.matches("https://blah.com/api/users/123"))
        XCTAssertFalse(matcher.matches("https://blah.com/api/posts"))
        XCTAssertFalse(matcher.matches("https://other.com/api/users"))
    }
    
    func testSingleWildcardInHost() {
        let matcher = URLMatcher(pattern: "*.blah.com")
        
        XCTAssertTrue(matcher.matches("https://api.blah.com"))
        XCTAssertTrue(matcher.matches("https://cdn.blah.com/path"))
        XCTAssertTrue(matcher.matches("https://www.blah.com"))
        
        XCTAssertFalse(matcher.matches("https://blah.com"))
        XCTAssertFalse(matcher.matches("https://api.sub.blah.com"))
        XCTAssertFalse(matcher.matches("https://api.other.com"))
    }
    
    func testSingleWildcardInPath() {
        let matcher = URLMatcher(pattern: "blah.com/api/*/details")
        
        XCTAssertTrue(matcher.matches("https://blah.com/api/users/details"))
        XCTAssertTrue(matcher.matches("https://blah.com/api/posts/details"))
        XCTAssertTrue(matcher.matches("https://blah.com/api/123/details"))
        
        XCTAssertFalse(matcher.matches("https://blah.com/api/details"))
        XCTAssertFalse(matcher.matches("https://blah.com/api/users/posts/details"))
        XCTAssertFalse(matcher.matches("https://blah.com/api/users/info"))
    }
    
    func testMultipleSingleWildcards() {
        let matcher = URLMatcher(pattern: "*.com/*/v1/*")
        
        XCTAssertTrue(matcher.matches("https://api.com/users/v1/data"))
        XCTAssertTrue(matcher.matches("https://test.com/auth/v1/login"))
        
        XCTAssertFalse(matcher.matches("https://api.com/v1/data"))
        XCTAssertFalse(matcher.matches("https://api.com/users/v1/data/extra"))
        XCTAssertFalse(matcher.matches("https://api.net/users/v1/data"))
    }
    
    // MARK: - Globstar Pattern Tests (**)
    
    func testBasicGlobstar() {
        let matcher = URLMatcher(pattern: "blah.com/product/**/reviews")
        
        // Standard glob: ** matches zero or more segments
        XCTAssertTrue(matcher.matches("https://blah.com/product/reviews"))
        XCTAssertTrue(matcher.matches("https://blah.com/product/123/reviews"))
        XCTAssertTrue(matcher.matches("https://blah.com/product/123/ABC/reviews"))
        XCTAssertTrue(matcher.matches("https://blah.com/product/123/ABC/DEF/GHI/reviews"))
        
        XCTAssertFalse(matcher.matches("https://blah.com/product"))
        XCTAssertFalse(matcher.matches("https://blah.com/product/123"))
        XCTAssertFalse(matcher.matches("https://blah.com/api/123/reviews"))
        XCTAssertFalse(matcher.matches("https://other.com/product/123/reviews"))
    }
    
    func testGlobstarAtEnd() {
        let matcher = URLMatcher(pattern: "blah.com/api/**")
        
        // Standard glob: ** at end matches everything including nothing
        XCTAssertTrue(matcher.matches("https://blah.com/api"))
        XCTAssertTrue(matcher.matches("https://blah.com/api/"))
        XCTAssertTrue(matcher.matches("https://blah.com/api/users"))
        XCTAssertTrue(matcher.matches("https://blah.com/api/v1/users"))
        XCTAssertTrue(matcher.matches("https://blah.com/api/v1/users/123/details"))
        
        XCTAssertFalse(matcher.matches("https://blah.com/web/users"))
        XCTAssertFalse(matcher.matches("https://other.com/api/users"))
    }
    
    func testGlobstarAtBeginning() {
        let matcher = URLMatcher(pattern: "blah.com/**/reviews")
        
        // Standard glob: ** matches zero or more
        XCTAssertTrue(matcher.matches("https://blah.com/reviews"))
        XCTAssertTrue(matcher.matches("https://blah.com/product/reviews"))
        XCTAssertTrue(matcher.matches("https://blah.com/api/v1/product/123/reviews"))
        
        XCTAssertFalse(matcher.matches("https://blah.com/"))
        XCTAssertFalse(matcher.matches("https://blah.com/product"))
        XCTAssertFalse(matcher.matches("https://other.com/reviews"))
    }
    
    func testGlobstarWithLiteralSegments() {
        let matcher = URLMatcher(pattern: "blah.com/product/**/123/*/reviews")
        
        XCTAssertTrue(matcher.matches("https://blah.com/product/123/A/reviews"))
        XCTAssertTrue(matcher.matches("https://blah.com/product/ABC/123/A/reviews"))
        XCTAssertTrue(matcher.matches("https://blah.com/product/ABC/DEF/123/A/reviews"))
        
        XCTAssertFalse(matcher.matches("https://blah.com/product/1234/reviews"))
        XCTAssertFalse(matcher.matches("https://blah.com/product/123/reviews"))
        XCTAssertFalse(matcher.matches("https://blah.com/product/ABC/456/A/reviews"))
    }
    
    func testMultipleGlobstars() {
        let matcher = URLMatcher(pattern: "blah.com/**/middle/**/end")
        
        XCTAssertTrue(matcher.matches("https://blah.com/middle/end"))
        XCTAssertTrue(matcher.matches("https://blah.com/start/middle/end"))
        XCTAssertTrue(matcher.matches("https://blah.com/start/middle/path/end"))
        XCTAssertTrue(matcher.matches("https://blah.com/a/b/middle/c/d/end"))
        
        XCTAssertFalse(matcher.matches("https://blah.com/middle"))
        XCTAssertFalse(matcher.matches("https://blah.com/end"))
        XCTAssertFalse(matcher.matches("https://blah.com/start/end"))
    }
    
    // MARK: - Edge Cases
    
    func testEmptyPattern() {
        let matcher = URLMatcher(pattern: "")
        
        XCTAssertFalse(matcher.matches("https://blah.com"))
        XCTAssertFalse(matcher.matches(""))
    }
    
    func testJustGlobstar() {
        let matcher = URLMatcher(pattern: "**")
        
        XCTAssertTrue(matcher.matches("https://blah.com"))
        XCTAssertTrue(matcher.matches("https://blah.com/anything"))
        XCTAssertTrue(matcher.matches("http://any.site.com/deep/path"))
    }
    
    func testInvalidURLs() {
        let matcher = URLMatcher(pattern: "blah.com")
        
        XCTAssertFalse(matcher.matches("not-a-url"))
        XCTAssertFalse(matcher.matches(""))
        XCTAssertFalse(matcher.matches("://blah.com"))
    }
    
    func testCaseInsensitivity() {
        let matcher = URLMatcher(pattern: "BLAH.COM/API/USERS")
        
        XCTAssertTrue(matcher.matches("https://blah.com/api/users"))
        XCTAssertTrue(matcher.matches("https://BLAH.COM/API/USERS"))
        XCTAssertTrue(matcher.matches("https://Blah.Com/Api/Users"))
    }
    
    func testPathWithTrailingSlash() {
        let matcher = URLMatcher(pattern: "blah.com/api")
        
        XCTAssertTrue(matcher.matches("https://blah.com/api"))
        // Standard behavior: trailing slash shouldn't matter for non-wildcard patterns
        XCTAssertTrue(matcher.matches("https://blah.com/api/"))
        XCTAssertFalse(matcher.matches("https://blah.com/api/users"))
    }
    
    func testRootPath() {
        let matcher = URLMatcher(pattern: "blah.com/")
        
        XCTAssertTrue(matcher.matches("https://blah.com/"))
        // This is a special case - explicit "/" in pattern
        XCTAssertTrue(matcher.matches("https://blah.com"))
        XCTAssertFalse(matcher.matches("https://blah.com/api"))
    }
    
    // MARK: - Real World Examples
    
    func testAPIEndpoints() {
        let matcher = URLMatcher(pattern: "api.myapp.com/v*/users/**")
        
        XCTAssertTrue(matcher.matches("https://api.myapp.com/v1/users"))
        XCTAssertTrue(matcher.matches("https://api.myapp.com/v1/users/"))
        XCTAssertTrue(matcher.matches("https://api.myapp.com/v2/users/123"))
        XCTAssertTrue(matcher.matches("https://api.myapp.com/v1/users/123/profile"))
        
        XCTAssertFalse(matcher.matches("https://api.myapp.com/users/123"))
        XCTAssertFalse(matcher.matches("https://api.myapp.com/v1/posts/123"))
    }
    
    func testCDNResources() {
        let matcher = URLMatcher(pattern: "cdn.*.com/**/*.jpg")
        
        XCTAssertTrue(matcher.matches("https://cdn.images.com/photo.jpg"))
        XCTAssertTrue(matcher.matches("https://cdn.images.com/photos/image.jpg"))
        XCTAssertTrue(matcher.matches("https://cdn.assets.com/deep/path/photo.jpg"))
        
        XCTAssertFalse(matcher.matches("https://cdn.images.com/photo.png"))
        XCTAssertFalse(matcher.matches("https://api.images.com/photo.jpg"))
    }
    
    func testSegmentEndpoints() {
        let matcher = URLMatcher(pattern: "*.segment.com/**")
        
        XCTAssertTrue(matcher.matches("https://api.segment.com"))
        XCTAssertTrue(matcher.matches("https://api.segment.com/"))
        XCTAssertTrue(matcher.matches("https://api.segment.com/v1/track"))
        XCTAssertTrue(matcher.matches("https://cdn.segment.com/analytics.js"))
        XCTAssertTrue(matcher.matches("https://signals.segment.com/data"))
        
        XCTAssertFalse(matcher.matches("https://segment.com/data"))
        XCTAssertFalse(matcher.matches("https://api.other.com/data"))
    }
    
    // MARK: - Performance Test
    
    func testPerformance() {
        let patterns = [
            "api.myapp.com/**/users/**",
            "*.segment.com/**",
            "cdn.*/images/**/*.jpg",
            "app.com/api/v*/products/*/reviews"
        ]
        
        let urls = [
            "https://api.myapp.com/v1/users/123/profile",
            "https://cdn.segment.com/analytics.js",
            "https://cdn.images.com/photos/2023/image.jpg",
            "https://app.com/api/v2/products/456/reviews"
        ]
        
        measure {
            for _ in 0..<10000 {
                for (pattern, url) in zip(patterns, urls) {
                    let matcher = URLMatcher(pattern: pattern)
                    _ = matcher.matches(url)
                }
            }
        }
    }
}
