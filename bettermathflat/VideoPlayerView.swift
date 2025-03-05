//
//  VideoPlayerView.swift
//  bettermathflat
//
//  Created by youngzheimer on 3/4/25.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Binding var videoURL: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let newPlayer = AVPlayer(url: videoURL)
                player = newPlayer
                newPlayer.play()
            }
            .onDisappear {
                player?.pause()
            }
    }
}
