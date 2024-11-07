//
//  MockedImageCache.swift
//  RoxyImage
//
//  Created by Ulaş Sancak on 7.11.2024.
//

import Foundation
@testable import RoxyImage

actor MockedImageCache: ImageCache {
    private var caches = [URL: (Data)]()
    
    func cachedResponse(for url: URL) async -> Data? {
        caches[url]
    }
    
    func store(response: URLResponse, data: Data, for url: URL) async {
        caches[url] = data
    }
    
    func removeCache() async {
        caches.removeAll()
    }
}
