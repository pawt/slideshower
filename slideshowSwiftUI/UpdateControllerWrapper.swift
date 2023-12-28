//
//  UpdateControllerWrapper.swift
//  Slideshower for macOS
//
//  Created by Paweł Trybulski on 28/12/2023.
//

import Foundation
import Sparkle

class UpdaterControllerWrapper: ObservableObject {
    var updaterController: SPUStandardUpdaterController?
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
}
