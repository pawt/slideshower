//
//  AnimatedImageView.swift
//  Slideshower for macOS
//
//  Created by Paweł Trybulski on 09/03/2024.
//

import SwiftUI

struct AnimatedImageView: NSViewRepresentable {
    var imageData: Data

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(data: imageData)
    }
}

