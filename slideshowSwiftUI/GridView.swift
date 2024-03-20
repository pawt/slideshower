//
//  GridView.swift
//  Slideshower for macOS
//
//  Created by Paweł Trybulski on 18/03/2024.
//

import SwiftUI

struct GridView: View {
    @EnvironmentObject var slideshowManager: SlideshowManager
    @Environment(\.presentationMode) var presentationMode
    
    var images: [IdentifiableImage]
    var delay: Double
    var randomOrder: Bool
    var loopSlideshow: Bool
    var useFadingTransition: Bool
    
    @State private var currentIndices: [Int] = []
    @State private var updatedIndices: Set<Int> = []
    @State private var timer: Timer?
    
    // Add a property to keep track of whether all photos have been shown at least once
    @State private var allPhotosShown = false
    @State private var hasStoppedSlideshow = false
    
    @State private var updatedGridPositions: Set<Int> = []

    let rows: Int = 3
    let columns: Int = 3

    var body: some View {
        GeometryReader { geometry in
            
            let horizontalSpacing = CGFloat(5 * (columns - 1))
            let verticalSpacing = CGFloat(5 * (rows - 1))
            let sizeWidth = (geometry.size.width - horizontalSpacing) / CGFloat(columns)
            let sizeHeight = (geometry.size.height - verticalSpacing) / CGFloat(rows)
            
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 5), count: columns), spacing: 5) {
                ForEach(currentIndices, id: \.self) { index in
                    if images.indices.contains(index), let image = images[index].image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: sizeWidth, height: sizeHeight)
                        // ... other modifiers ...
                    }
                }
            }
        }
        .onAppear(perform: setupGrid)
        .onDisappear {
            invalidateTimer()
            stopSlideshow()
        }
        .onReceive(slideshowManager.$isSlideshowRunning) { isRunning in
            if !isRunning {
                stopSlideshow()
            }
        }
        
        KeyPressHandlingView { event in
            if event.keyCode == 53 { // 53 is the key code for ESC
                print("Key pressed: ESC")
                stopSlideshow() // Call the stopSlideshow function
            }
        }
        .frame(width: 0, height: 0)
    }

    private func setupGrid() {
        // If there are not enough images to fill the grid, use all images.
        // Otherwise, use only as many images as the grid can hold.
        
        print("Loopslideshow is set to: \(loopSlideshow)")
        
        if images.count < rows * columns {
            currentIndices = Array(images.indices)
        } else {
            currentIndices = Array(images.indices.prefix(rows * columns))
        }
        updatedIndices = []
        print("Initial currentIndices: \(currentIndices)")
        setupTimer()
    }

    private func setupTimer() {
        print("Setting up timer with delay \(delay)")
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true) { _ in
            updateGridPeriodically()
        }
    }
    
    private func updateGridPeriodically() {
        // Check if we've updated the grid as many times as we have images (minus the initial grid count).
        if updatedIndices.count >= images.count - currentIndices.count {
            if !loopSlideshow {
                invalidateTimer()
                stopSlideshow()
                return
            }
            updatedIndices = []
        }

        // New: Track which grid positions have been updated in this cycle.
        // If all positions have been updated, clear the set for a new cycle.
        if updatedIndices.count % currentIndices.count == 0 {
            updatedGridPositions = []
        }
        
        var potentialNewIndices = Set(images.indices).subtracting(updatedIndices)
        if potentialNewIndices.isEmpty {
            potentialNewIndices = Set(images.indices)
        }

        // New: Select a grid position that hasn't been updated yet in this cycle.
        let unupdatedGridPositions = Set(currentIndices.indices).subtracting(updatedGridPositions)
        if let gridIndexToUpdate = unupdatedGridPositions.randomElement() {
            // Ensure we select a new image that isn't currently displayed.
            let currentImageIndex = currentIndices[gridIndexToUpdate]
            var potentialNewImageIndices = potentialNewIndices.subtracting(Set(currentIndices))
            if potentialNewImageIndices.isEmpty {
                potentialNewImageIndices.insert(currentImageIndex) // Allow current index for a seamless experience
            }
            
            if let newImageIndex = potentialNewImageIndices.randomElement() {
                withOptionalAnimation {
                    currentIndices[gridIndexToUpdate] = newImageIndex
                }
                updatedIndices.insert(newImageIndex)
                updatedGridPositions.insert(gridIndexToUpdate) // Mark this grid position as updated in this cycle
            }
        }
        
        print("Updated grid. Current indices: \(currentIndices), Updated indices: \(updatedIndices), Updated grid positions: \(updatedGridPositions)")
        
        // Check if all images have been shown
        if updatedIndices.count == images.count {
            if !loopSlideshow {
                allPhotosShown = true
            } else {
                updatedIndices = []
            }
        }
    }
    
    private func withOptionalAnimation(_ updates: () -> Void) {
        if useFadingTransition {
            withAnimation(.easeInOut(duration: delay)) {
                updates()
            }
        } else {
            updates()
        }
    }

    
    private func stopSlideshow() {
        if !hasStoppedSlideshow {
            print("Stopping the slideshow")
            hasStoppedSlideshow = true
            invalidateTimer()
            slideshowManager.isSlideshowRunning = false
            // Ensuring UI changes are done on the main thread
            DispatchQueue.main.async {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
  
    private func invalidateTimer() {
        print("Invalidating timer")
        timer?.invalidate()
        timer = nil
    }


}
