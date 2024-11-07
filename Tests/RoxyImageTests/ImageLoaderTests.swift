//
//  ImageLoaderTests.swift
//  RoxyImage
//
//  Created by Ulaş Sancak on 6.11.2024.
//

import Testing
@testable import RoxyImage
import Foundation
import UIKit.UIImage

final class ImageLoaderTests {
    let sessionConfiuration = URLSessionConfiguration.default

    init() async throws {
        sessionConfiuration.protocolClasses = [MockedURLProtocol.self]
    }
    
    deinit {
        sessionConfiuration.protocolClasses = nil
    }
    
    @Test func test() async throws {
        let imageCache = RoxyImageCache()
        await imageCache.removeCache()
        let imageLoader = ImageLoader(sessionConfiguration: sessionConfiuration, imageCache: imageCache)
        let image = try await imageLoader.load(url: URL(string: "https://www.example.com/")!)
        #expect(image != nil)
        
        let cachedImage = try await imageLoader.load(url: URL(string: "https://www.example.com/")!)
        #expect(cachedImage != nil)
    }

}

final class ImageLoaderWithWaitingTests {
    let sessionConfiuration = URLSessionConfiguration.default
    
    init() async throws {
        sessionConfiuration.protocolClasses = [MockedURLWithWaitingProtocol.self]
    }
    
    deinit {
        sessionConfiuration.protocolClasses = nil
    }
    
    @Test func test() async throws {
        let imageCache = RoxyImageCache()
        await imageCache.removeCache()
        let imageLoader = ImageLoader(sessionConfiguration: sessionConfiuration, imageCache: imageCache, maxConcurrentTasks: 2)
        let urls = (0...3).map { URL(string: "https://test\($0).com")! }
        
        // Start measuring time
        let startTime = Date()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = try await imageLoader.load(url: url)
                }
            }
            try await group.waitForAll()
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // With 4 tasks and max 2 concurrent, should take at least 2 rounds of 500ms
        #expect(totalTime > 1.0)
    }
    
    @Test func testCancellation() async throws {
        let imageCache = RoxyImageCache()
        await imageCache.removeCache()
        let imageLoader = ImageLoader(sessionConfiguration: sessionConfiuration, imageCache: imageCache, maxConcurrentTasks: 2)
        let url = URL(string: "https://test.com")!
        let task = Task {
            try await imageLoader.load(url: url)
        }
        Task {
            do {
                _ = try await task.value
                Issue.record("Task should have been cancelled")
            } catch URLError.cancelled {
            } catch {
                Issue.record(error)
            }
        }
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        await imageLoader.cancel(url: url)
    }
}

final class ImageLoaderRepeatingTasksTests {
    let sessionConfiuration = URLSessionConfiguration.default
    
    init() async throws {
        sessionConfiuration.protocolClasses = [MockedURLWithWaitingProtocol.self]
    }
    
    deinit {
        sessionConfiuration.protocolClasses = nil
    }
    
    @Test func testRepeating() async throws {
        let imageCache = RoxyImageCache()
        await imageCache.removeCache()
        let imageLoader = ImageLoader(sessionConfiguration: sessionConfiuration, imageCache: imageCache, maxConcurrentTasks: 2)
        let url = URL(string: "https://test.com")!
        let url2 = URL(string: "https://test.com")!
        let task = Task {
            try await imageLoader.load(url: url)
        }
        let task2 = Task {
            try await imageLoader.load(url: url2)
        }

        Task {
            do {
                _ = try await task.value
                print("executed 1")
            } catch {
                Issue.record(error)
            }
        }
        Task {
            do {
                _ = try await task2.value
                print("executed 2")
            } catch {
                Issue.record(error)
            }
        }

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
}
    
final class ImageLoaderWithCancellingWithManyTasksTests {
    let sessionConfiuration = URLSessionConfiguration.default
    
    init() async throws {
        sessionConfiuration.protocolClasses = [MockedURLWithWaitingProtocol.self]
    }
    
    deinit {
        sessionConfiuration.protocolClasses = nil
    }
    
    
    @Test func test() async throws {
        let imageCache = RoxyImageCache()
        await imageCache.removeCache()
        let imageLoader = ImageLoader(sessionConfiguration: sessionConfiuration, imageCache: imageCache, maxConcurrentTasks: 2)
        
        let url1 = URL(string: "https://test1.com")!
        let url2 = URL(string: "https://test2.com")!
        let url3 = URL(string: "https://test3.com")!
        
        var completedUrls: [URL] = []
        
        
        let task1 = Task {
            try await imageLoader.load(url: url1)
        }

        // Start second task
        let task2 = Task {
            try await imageLoader.load(url: url2)
        }
        
        // Start third task (should wait)
        let task3 = Task {
            try await imageLoader.load(url: url3)
        }
        
        // Give time for tasks to start
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Cancel task1 while it's running
        await imageLoader.cancel(url: url1)
        
        // Wait for all tasks
        do {
            _ = try await task1.value
            completedUrls.append(url1)
        } catch URLError.cancelled {
        }
        _ = try await task2.value
        completedUrls.append(url2)
        _ = try await task3.value
        completedUrls.append(url3)
        #expect(completedUrls.count == 2)
    }
}

final class ImageLoaderWithNilResultTests {
    let sessionConfiuration = URLSessionConfiguration.default

    init() async throws {
        sessionConfiuration.protocolClasses = [MockedURLWithNilResultProtocol.self]
    }
    
    deinit {
        sessionConfiuration.protocolClasses = nil
    }
    
    @Test func test() async throws {
        let imageCache = RoxyImageCache()
        await imageCache.removeCache()
        let imageLoader = ImageLoader(sessionConfiguration: sessionConfiuration, imageCache: imageCache)
        let image = try await imageLoader.load(url: URL(string: "https://www.example.com/")!)
        #expect(image == nil)
    }
}



final class ImageLoaderFailingTests {
    let sessionConfiuration = URLSessionConfiguration.default

    init() async throws {
        sessionConfiuration.protocolClasses = [MockedURLFailingProtocol.self]
    }
    
    deinit {
        sessionConfiuration.protocolClasses = nil
    }
    
    @Test func test() async throws {
        let imageCache = RoxyImageCache()
        await imageCache.removeCache()
        let imageLoader = ImageLoader(sessionConfiguration: sessionConfiuration, imageCache: imageCache)
        do {
            _ = try await imageLoader.load(url: URL(string: "https://www.example.com/")!)
            Issue.record("Fetching image should fail")
        } catch URLError.badServerResponse {
        } catch {
            Issue.record(error)
        }
    }
}

