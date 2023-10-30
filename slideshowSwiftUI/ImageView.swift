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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(identifiableImages, id: \.id) { image in
                        image.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(5)
                            .frame(width: 150, height: 150)
                            .clipped()
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
