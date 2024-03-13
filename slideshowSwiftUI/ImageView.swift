//
//  ImageView.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//

import SwiftUI

//struct IdentifiableImage: Identifiable {
//    var id = UUID()
//    var image: Image
//    var filename: String
//}

struct IdentifiableImage: Identifiable {
    var id = UUID()  // Unique identifier for each image
    var image: Image?  // Used for static images (non-GIFs)
    var gifData: Data?  // The raw data for GIF images
    var isGIF: Bool  // Indicates whether the image is a GIF
    var filename: String  // The name of the file, useful for debugging or UI display
    var path: String // The directory path of the file

    // Initializer for non-GIF images
    init(image: Image, filename: String, path: String) {
        self.image = image
        self.filename = filename
        self.isGIF = false
        self.gifData = nil
        self.path = path
    }

    // Initializer for GIF images
    init(image: Image, gifData: Data, isGIF: Bool, filename: String, path: String) {
        self.image = image
        self.gifData = gifData
        self.isGIF = isGIF
        self.filename = filename
        self.path = path
    }
    
    init(image: Image? = nil, gifData: Data? = nil, isGIF: Bool, filename: String, path: String) {
        self.image = image
        self.gifData = gifData
        self.isGIF = isGIF
        self.filename = filename
        self.path = path
    }
}

struct ImageView: View {
    var identifiableImages: [IdentifiableImage]?

    var body: some View {
        if let identifiableImages = identifiableImages {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(identifiableImages, id: \.id) { identifiableImage in
                        // Check if the image is not nil before applying modifiers
                        if let image = identifiableImage.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(5)
                                .frame(width: 150, height: 150)
                                .clipped()
                        } else {
                            // Provide a default view for nil images, like a placeholder or an empty view
                            Rectangle()
                                .foregroundColor(.gray)
                                .cornerRadius(5)
                                .frame(width: 150, height: 150)
                        }
                    }
                    .padding(2)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 10)
        } else {
            EmptyView()
        }
    }
}
