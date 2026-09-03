//
//  NavigationApp.swift
//  Navigation
//
//  Created by apple on 2026/8/29.
//

import SwiftUI

@main
struct NavigationApp: App {
    @State private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
        }
    }
}
