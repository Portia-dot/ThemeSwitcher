//
//  ContentView.swift
//  ThemeSwitcher
//
//  Created by Modamori Oluwayomi on 2024-09-14.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
   
    var body: some View {
        NavigationStack {
            List {
                ForEach(1...40, id: \.self) {_ in 
                    Text("Chat History")
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing){
                    Button{
                        showPickerView.toggle()
                    }label: {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    SchemeHostView{
        ContentView()
    }
}
