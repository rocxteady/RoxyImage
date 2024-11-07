//
//  File.swift
//  RoxyImage
//
//  Created by Ulaş Sancak on 6.11.2024.
//

import Foundation

protocol ImageCache: Sendable {
    func cachedResponse(for url: URL) async -> Data?
    func store(response: URLResponse, data: Data, for url: URL) async
    func removeCache() async
}

actor RoxyImageCache: ImageCache {
    private lazy var urlCache: URLCache = {
        let memoryCapacity = 20 * 1024 * 1024 // 20 MB
        let diskCapacity = 100 * 1024 * 1024 // 100 MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "ImageCache")
        return cache
    }()

    func cachedResponse(for url: URL) async -> Data? {
        urlCache.cachedResponse(for: URLRequest(url: url))?.data
    }
    
    func store(response: URLResponse, data: Data, for url: URL) async {
        let cachedResponse = CachedURLResponse(response: response, data: data)
        urlCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
    }
    
    func removeCache() async {
        urlCache.removeAllCachedResponses()
    }
}
