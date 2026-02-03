//
//  OfflineManager.swift
//  bettermathflat
//
//  Created by Copilot on 2/3/26.
//

import Foundation
import Combine

class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    private let fileManager = FileManager.default
    
    // MARK: - Status Publishing
    enum CachingStatus: Equatable {
        case idle
        case processing(message: String)
        case downloading(current: Int, total: Int)
        case completed
        case error(String)
    }
    
    @Published var status: CachingStatus = .idle
    @Published var progress: Double = 0.0
    @Published var isSyncing: Bool = false
    
    private var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5 // 동시에 5개까지만 다운로드
        return queue
    }()
    
    private var totalItems = 0
    private var processedItems = 0
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var imagesDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("OfflineImages")
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    private var dataDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("OfflineData")
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    // MARK: - Homework List Caching
    func saveHomeworkList(_ list: [Homework]) {
        let url = dataDirectory.appendingPathComponent("homeworks.json")
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: url)
        }
    }
    
    func loadHomeworkList() -> [Homework]? {
        let url = dataDirectory.appendingPathComponent("homeworks.json")
        if let data = try? Data(contentsOf: url) {
            return try? JSONDecoder().decode([Homework].self, from: data)
        }
        return nil
    }
    
    // MARK: - Problem List Caching
    func saveProblemList(studentBookId: String, list: [ProblemItem]) {
        let url = dataDirectory.appendingPathComponent("problems-\(studentBookId).json")
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: url)
        }
    }
    
    func loadProblemList(studentBookId: String) -> [ProblemItem]? {
        let url = dataDirectory.appendingPathComponent("problems-\(studentBookId).json")
        if let data = try? Data(contentsOf: url) {
            return try? JSONDecoder().decode([ProblemItem].self, from: data)
        }
        return nil
    }
    
    // MARK: - Image Caching
    func getLocalImageURL(for imageUrl: String) -> URL? {
        guard !imageUrl.isEmpty else { return nil }
        guard let data = imageUrl.data(using: .utf8) else { return nil }
        let filename = data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        
        let localURL = imagesDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }
        return nil
    }
    
    private func downloadImage(url: String, completion: @escaping () -> Void) {
        if getLocalImageURL(for: url) != nil {
            completion()
            return
        }
        
        guard let remoteURL = URL(string: url) else {
            completion()
            return
        }
        
        guard let data = url.data(using: .utf8) else {
            completion()
            return
        }
        let filename = data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        let localURL = imagesDirectory.appendingPathComponent(filename)
        
        let task = URLSession.shared.dataTask(with: remoteURL) { data, _, _ in
            if let data = data {
                try? data.write(to: localURL)
            }
            completion()
        }
        task.resume()
    }
    
    // MARK: - Orchestration
    func cacheAllHomeworkDetails(token: String, homeworks: [Homework]) {
        guard !isSyncing else { return }
        
        Task { @MainActor in
            self.isSyncing = true
            self.status = .processing(message: "문제 업데이트 중...")
            self.progress = 0.0
            self.totalItems = 0
            self.processedItems = 0
        }
        
        let dispatchGroup = DispatchGroup()
        let lock = NSLock()
        var imagesToDownload: [String] = []
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            for homework in homeworks {
                guard let bookId = homework.studentBookId else { continue }
                let bookIdStr = String(bookId)
                
                dispatchGroup.enter()
                
                fetchProblemList(token: token, studentBookId: bookIdStr) { result in
                    switch result {
                    case .success(let response):
                        if let problems = response.data?.content {
                            self.saveProblemList(studentBookId: bookIdStr, list: problems)
                            
                            var candidates: [String] = []
                            for item in problems {
                                if let problem = item.problem {
                                    if let img = problem.problemImageUrl { candidates.append(img) }
                                    if let img = problem.solutionImageUrl { candidates.append(img) }
                                    if let img = problem.answerImageUrl { candidates.append(img) }
                                }
                            }
                            
                            // Check which images are missing locally
                            let needed = candidates.filter { self.getLocalImageURL(for: $0) == nil }
                            
                            if !needed.isEmpty {
                                lock.lock()
                                imagesToDownload.append(contentsOf: needed)
                                lock.unlock()
                            }
                        }
                    case .failure(let error):
                        print("Failed to fetch problems for \(bookIdStr): \(error)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if imagesToDownload.isEmpty {
                    // Nothing to download
                    self.isSyncing = false
                    self.status = .completed
                    self.scheduleIdleReset()
                } else {
                    self.startImageDownloads(urls: imagesToDownload)
                }
            }
        }
    }
    
    private func startImageDownloads(urls: [String]) {
        self.totalItems = urls.count
        self.processedItems = 0
        self.updateProgress()
        
        for url in urls {
            self.downloadQueue.addOperation { [weak self] in
                guard let self = self else { return }
                let semaphore = DispatchSemaphore(value: 0)
                self.downloadImage(url: url) {
                    DispatchQueue.main.async {
                        self.processedItems += 1
                        self.updateProgress()
                    }
                    semaphore.signal()
                }
                _ = semaphore.wait(timeout: .now() + 30)
            }
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.downloadQueue.waitUntilAllOperationsAreFinished()
            DispatchQueue.main.async {
                self.isSyncing = false
                self.status = .completed
                self.scheduleIdleReset()
            }
        }
    }
    
    private func scheduleIdleReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.status == .completed {
                self.status = .idle
            }
        }
    }
    
    private func updateProgress() {
        if totalItems == 0 {
            progress = 0.0
        } else {
            progress = Double(processedItems) / Double(totalItems)
        }
        
        if progress >= 1.0 && processedItems > 0 && totalItems > 0 {
            // Completed state handled by queue monitoring
        } else {
            status = .downloading(current: processedItems, total: totalItems)
        }
    }
    
    // Removed old monitorQueueCompletion as logic is now integrated above
}
