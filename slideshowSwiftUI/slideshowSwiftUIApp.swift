//
//  slideshowSwiftUIApp.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//

import SwiftUI
import Countly

@main
struct slideshowSwiftUIApp: App {
    
    // Create an instance of SlideshowManager
    var slideshowManager = SlideshowManager()
    
    init() {
        
        // Configuration for Countly
        let config = CountlyConfig()
        config.host = "https://slideshower-211a80ac116b2.flex.countly.com"
        config.appKey = "b45bc8d055233be28efd89ca5cdfec81d0de681d"
        config.features = [CLYFeature.pushNotifications, CLYFeature.crashReporting]
        config.updateSessionPeriod = 600

        // Start Countly with the configuration
        Countly.sharedInstance().start(with: config)
        }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 750)
                .environmentObject(slideshowManager)
        }
        .windowResizability(.contentSize)
        .commands {
            // for example
//            CommandGroup(replacing: .help) {
//                Button(action: {}) {
//                    Text("MyApp Help")
//                }
//            }
        }
    }
    
    
}
