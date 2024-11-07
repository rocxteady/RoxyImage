//
//  ImageLoader.swift
//  PressReader
//
//  Created by Ulaş Sancak on 8.07.2024.
//

import Foundation
#if os(macOS)
@preconcurrency import AppKit.NSImage
extension NSImage: @unchecked @retroactive Sendable { }
typealias MyImage = NSImage
#else
import UIKit.UIImage
typealias MyImage = UIImage
#endif


actor ImageLoader {
    static let shared = ImageLoader()
        
    private var tasks: [URL: Task<MyImage?, Error>] = [:]
    private var waitingTasks: [(URL, CheckedContinuation<Void, Error>)] = []
    private let sessionConfiguration: URLSessionConfiguration
    private let imageCache: ImageCache
    private let maxConcurrentTasks: Int
    
    init(sessionConfiguration: URLSessionConfiguration = .default,
         imageCache: ImageCache = RoxyImageCache(),
         maxConcurrentTasks: Int = 10) {
        self.sessionConfiguration = sessionConfiguration
        self.imageCache = imageCache
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    private lazy var urlCache: URLCache = {
        let memoryCapacity = 20 * 1024 * 1024
        let diskCapacity = 100 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "ImageCache")
        return cache
    }()
    
    private var session: URLSession {
        sessionConfiguration.timeoutIntervalForRequest = 10
        sessionConfiguration.timeoutIntervalForResource = 10
        sessionConfiguration.urlCache = urlCache
        sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: sessionConfiguration)
    }
    
    private func fetchImage(from url: URL) async throws -> MyImage? {
        if let data = await imageCache.cachedResponse(for: url) {
            return MyImage(data: data)
        }
        
        let session = session
        defer { session.finishTasksAndInvalidate() }
        
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        await imageCache.store(response: response, data: data, for: url)
        return MyImage(data: data)
    }

    private func waitForSlot(url: URL) async throws {
        guard tasks.count >= maxConcurrentTasks else { return }
        
        try await withCheckedThrowingContinuation { continuation in
            waitingTasks.append((url, continuation))
        }
    }

    private func resumeNextWaitingTask() {
        guard !waitingTasks.isEmpty, tasks.count < maxConcurrentTasks else { return }
        let (_, continuation) = waitingTasks.removeFirst()
        continuation.resume()
    }
    
    func load(url: URL) async throws -> MyImage? {
        if let existingTask = tasks[url] {
            return try await existingTask.value
        }
        
        try await waitForSlot(url: url)
        
        let task = Task {
            defer {
                tasks[url] = nil
                resumeNextWaitingTask()
            }
            return try await fetchImage(from: url)
        }
        
        tasks[url] = task
        return try await task.value
    }

    func cancel(url: URL) {
        tasks[url]?.cancel()
        tasks[url] = nil
        
        // If we have waiting tasks and now have capacity, start the next one
        if !waitingTasks.isEmpty && tasks.count < maxConcurrentTasks {
            let (_, continuation) = waitingTasks.removeFirst()
            continuation.resume()
        }
    }
}
