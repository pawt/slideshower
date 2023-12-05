//
//  SlideshowView.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//
import SwiftUI

struct SlideshowView: View {
    let images: [IdentifiableImage]
    let slideshowDelay: Double
    let randomOrder: Bool
    let loopSlideshow: Bool
    let useFadingTransition: Bool

    @State private var currentIndex = 0
    @State private var shuffledIndices: [Int] = []
    @State private var isMouseOver = false
    
    @Binding var isSlideshowRunning: Bool

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
        }
        .onAppear {
            // Start the slideshow
            if isSlideshowRunning {
                if randomOrder {
                    shuffledIndices = Array(0..<images.count).shuffled()
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
        
        KeyPressHandlingView { event in
            if event.keyCode == 53 { // 53 is the key code for ESC
                stopSlideshow() // Call the stopSlideshow function
            }
        }
        .frame(width: 0, height: 0)
    }
    
    private func startRandomSlideshow() {
        guard isSlideshowRunning else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + slideshowDelay) {
            withAnimation(self.useFadingTransition ? .easeInOut(duration: 1.0) : nil) {
                // Proceed with the next image if there are images left in the shuffledIndices
                if !self.shuffledIndices.isEmpty {
                    self.currentIndex = self.shuffledIndices.removeFirst()
                } else {
                    // If there are no images left and looping is enabled, reshuffle and start over
                    if self.loopSlideshow {
                        self.shuffledIndices = Array(0..<self.images.count).shuffled()
                        self.currentIndex = self.shuffledIndices.removeFirst()
                    } else {
                        // If not looping, stop the slideshow
                        self.isSlideshowRunning = false
                    }
                }
            }
            // If the slideshow is still running, continue to the next image after a delay
            if self.isSlideshowRunning {
                self.startRandomSlideshow()
            }
        }
    }
    

    private func startSlideshow() {
        guard isSlideshowRunning else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + slideshowDelay) {
            withAnimation(useFadingTransition ? Animation.easeInOut(duration: 1.0) : nil) {
                if self.currentIndex < self.images.count - 1 {
                    self.currentIndex += 1
                } else {
                    if self.loopSlideshow {
                        self.currentIndex = 0
                    }
                }
            }
            if self.isSlideshowRunning {
                self.startSlideshow()
            }
        }
    }

    
    // Function to stop the slideshow
    private func stopSlideshow() {
        isSlideshowRunning = false
        presentationMode.wrappedValue.dismiss()
    }
}
