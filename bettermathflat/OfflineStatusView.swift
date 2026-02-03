//
//  OfflineStatusView.swift
//  bettermathflat
//
//  Created by Copilot on 2/3/26.
//

import SwiftUI

struct OfflineStatusView: View {
    @ObservedObject var offlineManager = OfflineManager.shared
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        if offlineManager.status != .idle {
            HStack(spacing: 12) {
                switch offlineManager.status {
                case .processing(let message):
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(message)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                case .downloading(let current, let total):
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오프라인 데이터 동기화 중")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(current) / \(total) 파일 다운로드")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ProgressView(value: offlineManager.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 80)
                    
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("동기화 완료")
                        .font(.caption)
                        .fontWeight(.bold)
                    
                case .error(let msg):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                    
                case .idle:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(scheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
            .padding(.top, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: offlineManager.status)
        }
    }
}
