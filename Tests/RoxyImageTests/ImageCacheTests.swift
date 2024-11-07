//
//  ImageCacheTests.swift
//  RoxyImage
//
//  Created by Ulaş Sancak on 7.11.2024.
//

import Testing
@testable import RoxyImage
import Foundation

final class ImageCacheTests {
    @Test func test() async throws {
        let cache = MockedImageCache()
        
        let url = URL(string: "https://www.example.com")!
        
        let urlData = await cache.cachedResponse(for: url)
        #expect(urlData == nil)
        
        let data = Data()
        await cache.store(response: URLResponse(), data: data, for: url)
        let cachedData = await cache.cachedResponse(for: url)
        #expect(cachedData == data)
        
        await cache.removeCache()
        let removedData = await cache.cachedResponse(for: url)
        #expect(removedData == nil)
    }
}
