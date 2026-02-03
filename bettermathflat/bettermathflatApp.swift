//
//  bettermathflatApp.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import SwiftUI

@main
struct bettermathflatApp: App {
    
    init() {
        // 1. 캐시 크기 조정 (메모리 200MB, 디스크 1GB)
        let memoryCapacity = 200 * 1024 * 1024
        let diskCapacity = 1024 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "bettermathflat_cache")
        URLCache.shared = cache
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
