//
//  MainTabView.swift
//  ArtiMorph
//
//  Created by admin on 2025/6/28.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView{
            NavigationStack{
                CanvasListView()
            }
            .tabItem {
                Label("首页", systemImage: "square.on.square")
            }
            
            NavigationStack{
                ARModelGalleryView()
            }
            .tabItem {
                Label("模型库", systemImage: "cube")
            }
        }
    }
}
