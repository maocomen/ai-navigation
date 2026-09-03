//
//  DetailView.swift
//  Navigation
//
//  Created by apple on 2026/8/29.
//

import SwiftUI

struct DetailView: View {
    
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Hello, Detail View!")
        }
        .navigationTitle("Detail")
        .toolbar {
            ToolbarItem {
                Button("测试") {
                    dismiss()
                }
            }
        }
    }
}
