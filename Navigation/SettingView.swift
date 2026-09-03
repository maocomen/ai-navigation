//
//  SettingView.swift
//  Navigation
//
//  Created by apple on 2026/8/29.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        VStack {
            Text("Hello, Setting View!")
        }
        .navigationTitle("Setting")
        .toolbar {
            ToolbarItem {
                Button("确定") {
                    
                }
            }
        }
    }
}
