//
//  AppDelegate.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 15/10/2023.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the window
        window = NSApplication.shared.windows.first
        window.delegate = self

        // Set full-screen options
        NSApplication.shared.presentationOptions = [
            .autoHideMenuBar,
            .autoHideDock,
            .fullScreen,
            .disableAppleMenu,
            .disableProcessSwitching
        ]

        // Set up the keyboard shortcut to exit full-screen mode
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // KeyCode for "Escape" key
                NSApplication.shared.keyWindow?.toggleFullScreen(nil)
                return nil
            }
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

