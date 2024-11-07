//
//  MockedURLProtocol.swift
//  
//
//  Created by Ulaş Sancak on 2.10.2023.
//

import Foundation
#if os(macOS)
import AppKit.NSImage
#else
import UIKit.UIImage
#endif

extension URLProtocol: @unchecked @retroactive Sendable { }

final class MockedURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(url: URL(string: "https://www.example.com/")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        #if os(macOS)
        let image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        let tiffRepresentation = image?.tiffRepresentation
        let bitmap = NSBitmapImageRep(data: tiffRepresentation!)
        let data = bitmap?.representation(using: .png, properties: [:])
        #else
        let data = UIImage(systemName: "star.fill")?.pngData()
        #endif

        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

final class MockedURLWithWaitingProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(url: URL(string: "https://www.example.com/")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        #if os(macOS)
        let image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        let tiffRepresentation = image?.tiffRepresentation
        let bitmap = NSBitmapImageRep(data: tiffRepresentation!)
        let data = bitmap?.representation(using: .png, properties: [:])
        #else
        let data = UIImage(systemName: "star.fill")?.pngData()
        #endif
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            if let response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() { }
}

final class MockedURLWithNilResultProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(url: URL(string: "https://www.example.com/")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

final class MockedURLFailingProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(url: URL(string: "https://www.example.com/")!, statusCode: 400, httpVersion: nil, headerFields: nil)
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}
