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
    @State private var isMouseOver = false
    
    @State private var isPaused = false
    @State private var showPauseInfo = false
    @State private var showResumeInfo = false
    
    @State private var slideshowWorkItem: DispatchWorkItem?

    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            if images.indices.contains(currentIndex) {
                images[currentIndex].image
                    .resizable()
                    .scaledToFit()
                    .id(currentIndex)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    .animation(useFadingTransition ? Animation.easeInOut(duration: 1.0) : nil, value: currentIndex)
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
                        // Automatically hide the pause info after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
                        // Automatically hide the resume info after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
            
            // Add observer to handle exit from full-screen
            NotificationCenter.default.addObserver(
                forName: NSWindow.didExitFullScreenNotification,
                object: nil,
                queue: .main) { _ in
                    self.stopSlideshow()
                }
        }
        .onDisappear {
            // Stop the slideshow and remove observer when view disappears
            stopSlideshow()
            NotificationCenter.default.removeObserver(self)
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
        }
        .frame(width: 0, height: 0)
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
                    // If not looping and no images left, stop the slideshow
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
                        // If not looping, stop the slideshow
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
    
    
}
