//
//  ImageView.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//

import SwiftUI

struct IdentifiableImage: Identifiable {
    var id = UUID()
    var image: Image
}

struct ImageView: View {
    var identifiableImages: [IdentifiableImage]?

    var body: some View {
        if let identifiableImages = identifiableImages {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(identifiableImages, id: \.id) { image in
                        image.image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}
