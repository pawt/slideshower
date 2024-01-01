//
//  UpdateControllerWrapper.swift
//  Slideshower for macOS
//
//  Created by Paweł Trybulski on 28/12/2023.
//

import Foundation
import Sparkle

class UpdaterControllerWrapper: NSObject, ObservableObject, SPUUpdaterDelegate {
    
    var updaterController: SPUStandardUpdaterController?
    
    @Published var isUpdateAvailable: Bool = false

    override init() {
        super.init()
        // Initialize and start the updater controller
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        
        // Explicitly start the updater
        do {
            try updaterController?.updater.start()
        } catch {
            print("Error starting Sparkle updater: \(error)")
        }
    }
    
    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
    
    func createUpdaterController() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }
    
    // Delegate methods to handle updater events.
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem, userInitiated: Bool) {
        DispatchQueue.main.async {
            self.isUpdateAvailable = true
            print("Update found")
        }
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater, userInitiated: Bool) {
        DispatchQueue.main.async {
            self.isUpdateAvailable = false
            print("No update found.")
        }
    }
    
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("Updater will install update: \(item)")
    }
    
    func updater(_ updater: SPUUpdater, didCancelInstallUpdate item: SUAppcastItem) {
        print("Updater did cancel install update: \(item)")
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("Updater did abort with error: \(error)")
    }
}

