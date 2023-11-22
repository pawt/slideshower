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

    @State private var currentIndex = 0
    @State private var shuffledIndices: [Int] = []
    @State private var isMouseOver = false
    @State private var isSlideshowRunning = true

    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            if images.indices.contains(currentIndex) {
                images[currentIndex].image
                    .resizable()
                    .scaledToFit()
                    .edgesIgnoringSafeArea(.all)
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
        
        let queue = DispatchQueue.global(qos: .background)
        queue.asyncAfter(deadline: .now() + slideshowDelay) {
            guard self.isSlideshowRunning else { return }
            
            if !self.shuffledIndices.isEmpty {
                self.currentIndex = self.shuffledIndices.removeFirst()
                self.startRandomSlideshow()
            }
        }
    }

    private func startSlideshow() {
        guard isSlideshowRunning else { return }
        
        let queue = DispatchQueue.global(qos: .background)
        queue.asyncAfter(deadline: .now() + slideshowDelay) {
            guard self.isSlideshowRunning else { return }
            
            if self.currentIndex < self.images.count - 1 {
                self.currentIndex += 1
            } else {
                if self.loopSlideshow {
                    self.currentIndex = 0
                }
            }
            self.startSlideshow()
        }
    }

    
    // Function to stop the slideshow
    private func stopSlideshow() {
        isSlideshowRunning = false
        presentationMode.wrappedValue.dismiss()
    }
}
