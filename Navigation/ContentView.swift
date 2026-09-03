//
//  ContentView.swift
//  Navigation
//
//  Created by apple on 2026/8/29.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(Router.self) private var router
    
    var body: some View {
        @Bindable var router = router
        
        NavigationStack(path: $router.path) {
            VStack {
                NavigationLink("Detail") {
                    DetailView()
                }
                NavigationLink("Setting") {
                    SettingView()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
