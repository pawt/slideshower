//
//  SlideshowView.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//
import SwiftUI


struct SlideshowView: View {
    @EnvironmentObject var slideshowManager: SlideshowManager
    
    let images: [IdentifiableImage]
    let slideshowDelay: Double
    let randomOrder: Bool
    let loopSlideshow: Bool
    let useFadingTransition: Bool

    @State private var currentIndex = 0
    @State private var shuffledIndices: [Int] = []
    
    @State private var isPaused = false
    @State private var showPauseInfo = false
    @State private var showResumeInfo = false
    
    // Add new properties for handling arrow keys
    private let rightArrowKeyCode = 124 // Right arrow key code
    private let leftArrowKeyCode = 123  // Left arrow key code
    
    @State private var slideshowWorkItem: DispatchWorkItem?

    @Environment(\.presentationMode) var presentationMode
    
    @State private var isMouseOver = false
    @State private var cursorTimer: Timer?
    private let cursorHideDelay: TimeInterval = 1.0
    
    var body: some View {
        ZStack {
            if images.indices.contains(currentIndex) {
                let image = images[currentIndex]
                if image.isGIF, let gifData = image.gifData {
                    AnimatedImageView(imageData: gifData)
                        .scaledToFit()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    image.image?
                        .resizable()
                        .scaledToFit()
                        .edgesIgnoringSafeArea(.all)
                }
            }
            
            if showPauseInfo {
                Text("Slideshow paused")
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
                    .onAppear {
                        // Automatically hide the pause info after 1 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                self.showPauseInfo = false
                            }
                        }
                    }
            }
            
            if showResumeInfo {
                Text("Slideshow resumed")
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
                    .onAppear {
                        // Automatically hide the resume info after 1 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                self.showResumeInfo = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            // Start the slideshow
            if slideshowManager.isSlideshowRunning {
                if randomOrder {
                    // Shuffle the indices and set the first image
                    shuffledIndices = Array(0..<images.count).shuffled()
                    currentIndex = shuffledIndices.removeFirst()
                    startRandomSlideshow()
                } else {
                    startSlideshow()
                }
            }
        }
        .onAppear {
            self.startMouseTracking()
        }
        .onDisappear {
            // Stop the slideshow and remove observer when view disappears
            stopSlideshow()
            NotificationCenter.default.removeObserver(self)
        }
        .onDisappear {
            self.stopMouseTracking()
        }
        .onReceive(slideshowManager.$isSlideshowRunning) { isRunning in
            if !isRunning {
                print("Button STOP pressed.")
                stopSlideshow()
            }
        }
        
        KeyPressHandlingView { event in
            if event.keyCode == 49 { // 49 is the key code for the space bar
                print("Spacebar pressed")
                if isPaused {
                    // Resume slideshow
                    resumeSlideshow()
                } else {
                    // Pause slideshow
                    pauseSlideshow()
                }
                
            } else if event.keyCode == 53 { // 53 is the key code for ESC
                print("ESC key pressed.")
                stopSlideshow() // Call the stopSlideshow function
            }
            
            // Handle right arrow key
            if event.keyCode == rightArrowKeyCode {
                goToNextPhoto()
            }
            // Handle left arrow key
            if event.keyCode == leftArrowKeyCode {
                goToPreviousPhoto()
            }
        }
        .frame(width: 0, height: 0)
    }
    
    private func goToNextPhoto() {
        
        // Cancel the current slideshow timer
        slideshowWorkItem?.cancel()
        
        // Logic to go to the next photo
        if randomOrder {
            if !shuffledIndices.isEmpty {
                currentIndex = shuffledIndices.removeFirst()
            } else if loopSlideshow {
                shuffledIndices = Array(0..<images.count).shuffled()
                currentIndex = shuffledIndices.removeFirst()
            }
        } else {
            if currentIndex < images.count - 1 {
                currentIndex += 1
            } else if loopSlideshow {
                currentIndex = 0
            }
        }
        
        // Restart the slideshow
        if randomOrder {
            startRandomSlideshow()
        } else {
            startSlideshow()
        }
    }
    
    private func goToPreviousPhoto() {
        
        // Cancel the current slideshow timer
        slideshowWorkItem?.cancel()
        
        // Logic to go to the previous photo
        if randomOrder {
            if currentIndex > 0 {
                currentIndex = shuffledIndices.prefix(while: { $0 != currentIndex }).last ?? 0
            } else if loopSlideshow {
                shuffledIndices = Array(0..<images.count).shuffled()
                currentIndex = shuffledIndices.last ?? 0
            }
        } else {
            if currentIndex > 0 {
                currentIndex -= 1
            } else if loopSlideshow {
                currentIndex = images.count - 1
            }
        }
        
        // Restart the slideshow
        if randomOrder {
            startRandomSlideshow()
        } else {
            startSlideshow()
        }
    }
    
    private func pauseSlideshow() {
        isPaused = true
        showPauseInfo = true
        // Cancel the pending work item to effectively pause the slideshow
        slideshowWorkItem?.cancel()
    }
    
    private func resumeSlideshow() {
        isPaused = false
        showPauseInfo = false
        showResumeInfo = true
        
        if randomOrder {
            startRandomSlideshow()
        } else {
            startSlideshow()
        }
    }
    
    private func startRandomSlideshow() {
        guard slideshowManager.isSlideshowRunning, !isPaused else { return }

        let workItem = DispatchWorkItem {
            withAnimation(self.useFadingTransition ? .easeInOut(duration: 1.0) : nil) {
                if !self.shuffledIndices.isEmpty {
                    self.currentIndex = self.shuffledIndices.removeFirst()
                } else if self.loopSlideshow {
                    // Reshuffle and continue only if looping
                    self.shuffledIndices = Array(0..<self.images.count).shuffled()
                    self.currentIndex = self.shuffledIndices.removeFirst()
                } else {
                    self.slideshowManager.isSlideshowRunning = false
                    return
                }

                // Schedule the next transition
                self.startRandomSlideshow()
            }
        }

        slideshowWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + slideshowDelay, execute: workItem)
    }

    

    private func startSlideshow() {
        guard slideshowManager.isSlideshowRunning, !isPaused else { return }
        
        // Cancel the previous work item if it was scheduled
        slideshowWorkItem?.cancel()
        
        // Create a new work item to change the current image
        let workItem = DispatchWorkItem {
            withAnimation(self.useFadingTransition ? .easeInOut(duration: 1.0) : nil) {
                // Proceed with the next image if there are images left
                if self.currentIndex < self.images.count - 1 {
                    self.currentIndex += 1
                } else {
                    // If at the end and looping is enabled, start over
                    if self.loopSlideshow {
                        self.currentIndex = 0
                    } else {
                        self.slideshowManager.isSlideshowRunning = false
                    }
                }
                
                // If the slideshow is still running, continue to the next image after a delay
                if self.slideshowManager.isSlideshowRunning {
                    self.startSlideshow()
                }
            }
        }
        
        // Save the new work item and schedule it
        slideshowWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + slideshowDelay, execute: workItem)
    }

    
    
    // Function to stop the slideshow
    private func stopSlideshow() {
        print("Stopping the slideshow.")
        slideshowWorkItem?.cancel()
        if slideshowManager.isSlideshowRunning {
            slideshowManager.isSlideshowRunning = false
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func startMouseTracking() {
        let trackingArea = NSTrackingArea(rect: NSApp.keyWindow?.contentView?.bounds ?? .zero, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        NSApp.keyWindow?.contentView?.addTrackingArea(trackingArea)
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willUpdateNotification,
            object: nil,
            queue: nil
        ) { _ in
            // Invalidate previous timer
            self.cursorTimer?.invalidate()

            // Schedule a new timer
            self.cursorTimer = Timer.scheduledTimer(withTimeInterval: self.cursorHideDelay, repeats: false) { _ in
                guard let currentWindow = NSApp.keyWindow else { return }
                
                // Check if the window is in full screen and the application is active
                if currentWindow.styleMask.contains(.fullScreen) && NSApp.isActive {
                    let mouseLocation = NSEvent.mouseLocation
                    
                    // Get the frame of the current screen
                    if let screenWithMouse = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
                        guard let windowScreen = currentWindow.screen else { return }
                        
                        // Check if the mouse is on the same screen as the full-screen window
                        if screenWithMouse == windowScreen {
                            // Hide the cursor
                            NSCursor.setHiddenUntilMouseMoves(true)
                        }
                    }
                }
            }
        }
    }

    private func stopMouseTracking() {
        cursorTimer?.invalidate()
        cursorTimer = nil
        NSApp.keyWindow?.contentView?.trackingAreas.forEach { NSApp.keyWindow?.contentView?.removeTrackingArea($0) }
    }
    
}
