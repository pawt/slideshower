//
//  slideshowSwiftUIApp.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//

import SwiftUI
import Countly
import Sparkle

@main
struct slideshowSwiftUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
                .environmentObject(appDelegate.updaterControllerWrapper)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("Updates") {
                Button("Check for updates…") {
                    appDelegate.updaterControllerWrapper.checkForUpdates()
                }
            }
        }
            // for example
//            CommandGroup(replacing: .help) {
//                Button(action: {}) {
//                    Text("MyApp Help")
//                }
//            }
        
    }
    
    
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var updaterControllerWrapper = UpdaterControllerWrapper()
    
    deinit {
        print("AppDelegate is being deinitialized")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Ensure that the updaterController within updaterControllerWrapper is initialized
//        updaterControllerWrapper.createUpdaterController()
                
        // Now you can safely start the updater
//        try? updaterControllerWrapper.updaterController?.updater.start()
        
        
        // If you want to customize the behavior further, you can set the delegate
        // and implement the appropriate delegate methods, like so:
        // updaterController.updater.delegate = self
        
    }
}
