//
//  slideshowSwiftUIApp.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//

import SwiftUI

@main
struct slideshowSwiftUIApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 800)
        }
        .windowResizability(.contentSize)
        .commands {
            // for example
            CommandGroup(replacing: .help) {
                Button(action: {}) {
                    Text("MyApp Help")
                }
            }
            CommandMenu("File") {
                            Button("Print message") {
                                print("Hello World!")
                            }
                            .keyboardShortcut("p")
            }
            
        }
    }
}
