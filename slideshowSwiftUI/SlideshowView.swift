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
            if randomOrder {
                shuffledIndices = Array(0..<images.count).shuffled()
                startRandomSlideshow()
            } else {
                startSlideshow()
            }
        }

    }
    
    private func startRandomSlideshow() {
        let queue = DispatchQueue.global(qos: .background)
        queue.asyncAfter(deadline: .now() + slideshowDelay) {
            if !shuffledIndices.isEmpty {
                currentIndex = shuffledIndices.removeFirst()
                startRandomSlideshow()
            }
        }
    }


    private func startSlideshow() {
        let queue = DispatchQueue.global(qos: .background)
        queue.asyncAfter(deadline: .now() + slideshowDelay) {
            if currentIndex < images.count - 1 {
                currentIndex += 1
            } else {
                if loopSlideshow {
                    currentIndex = 0
                }
            }
            startSlideshow()
        }
    }
}




