//
//  GameAppApp.swift
//  GameApp
//
//  Created by admin on 4/10/23.
//

import SwiftUI

@main
struct GameAppApp: App {
    init() {
        UIView.appearance().isMultipleTouchEnabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
