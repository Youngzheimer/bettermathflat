//
//  SceneDelegate.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import Foundation
import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // ContentView 인스턴스 생성
        let contentView = ContentView()

        // UIHostingController를 사용하여 SwiftUI View를 UIKit View Controller로 감싸기
        let hostingController = UIHostingController(rootView: contentView)

        // Window 생성 및 Root View Controller 설정
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = hostingController // ContentView를 Root View Controller로 설정
        window?.makeKeyAndVisible()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name("LoginSuccess"), object: nil)

    }
    
    @objc func loginSuccess() {
            print("going to main view")
            // ContentView 인스턴스 생성
            let contentView = ContentView()

            // UIHostingController를 사용하여 SwiftUI View를 UIKit View Controller로 감싸기
            let hostingController = UIHostingController(rootView: contentView)

            // Root View Controller 변경
            window?.rootViewController = hostingController
        }

    // ... 나머지 SceneDelegate 메서드 ...
}
