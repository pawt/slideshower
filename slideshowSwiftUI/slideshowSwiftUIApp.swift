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
                Button("Check for Updates…") {
                    // Access updaterController through appDelegate
                    appDelegate.updaterController.checkForUpdates(nil)
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
    var updaterController: SPUStandardUpdaterController!
    
    var updaterControllerWrapper = UpdaterControllerWrapper()

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Initialize the updater controller
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Optionally, you can configure automatic update checks here
        // This will start the updater which will check for updates based on the interval specified in your Info.plist
        try? updaterController.updater.start()
        
        
        // If you want to customize the behavior further, you can set the delegate
        // and implement the appropriate delegate methods, like so:
        // updaterController.updater.delegate = self
        
        // Pass updaterController to updaterControllerWrapper
        updaterControllerWrapper.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
}
