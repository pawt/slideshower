//
//  ContentView.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var images: [IdentifiableImage] = []
    @State private var selectedFileNames: [String] = []
    @State private var slideshowDelay: Double = 5.0
    @State private var delayInput: String = "5"
    @State private var randomOrder = false
    @State private var showAlert = false
    @State private var isLoading = false
    
    let backgroundGradient = LinearGradient(
        colors: [Color.white, Color.white],
        startPoint: .top, endPoint: .bottom)
    
    var body: some View {
        VStack() {
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack() {
                    ZStack {
                        if !images.isEmpty {
                            ImageView(identifiableImages: images)
                                .frame(height: 400)
                                .background(Color.white) // Add this line
                                .cornerRadius(8) // Optional: Add corner radius for a rounded look
                        } else {
                            Color.white // Set the background color of the VStack
                                .frame(height: 400) // Set a fixed height
                        }
                        if isLoading {
                            ProgressView("Loading Images...")
                                .padding(.top, 10)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .frame(height: 400) // Set the initial height of the scrollable panel
            }
            
            // Label displaying the number of files added
            if !images.isEmpty {
                VStack(alignment: .center) {
                    Text("\(selectedFileNames.count) files added")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(10)
                }
            } else {
                VStack(alignment: .center) {
                    Text("Please add files")
                        .frame(maxWidth: .infinity, alignment: .center)
                        //.padding(.top)
                }
            }
            
            Button("Select files") {
                let openPanel = NSOpenPanel()
                openPanel.allowsMultipleSelection = true
                openPanel.canChooseDirectories = false
                openPanel.canChooseFiles = true
                openPanel.allowedContentTypes = [UTType.jpeg, UTType.png, UTType.heic]
                if openPanel.runModal() == .OK {
                    loadImages(from: openPanel.urls)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom)
            
            HStack {
                GroupBox(label: Text("Settings")
                    .font(.title2)
                    .padding(.bottom, 5)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Random Order")
                                Spacer()
                                Toggle("", isOn: $randomOrder)
                                    .padding(6)
                            }
                            .padding(10)
                            HStack {
                                Text("Slideshow delay:")
                                Spacer()
                                TextField("Enter delay", text: $delayInput)
                                    .frame(width: 60)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: delayInput) { newValue in
                                        if let delay = Double(newValue) {
                                            slideshowDelay = delay
                                        }
                                    }
                                Text("sec")
                            }
                            .padding(10)
                        }
                    }
                    .frame(maxWidth: 300)
                    .padding(.leading)
                
                Button("Run Slideshow") {
                    if images.isEmpty {
                        showAlert = true
                    } else {
                        runSlideshow()
                    }
                }
                .padding()
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("No Images Selected"),
                        message: Text("Please select images before running the slideshow."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.bottom, 10.0)
        }
    }
    
    
    func loadImages(from urls: [URL]) {
        
        isLoading = true
        
        DispatchQueue.global(qos: .background).async {
            var loadedImages = [IdentifiableImage]()
            
            for url in urls {
                if let nsImage = NSImage(contentsOf: url) {
                    let fileName = url.lastPathComponent
                    self.selectedFileNames.append(fileName)
                    loadedImages.append(IdentifiableImage(image: Image(nsImage: nsImage)))
                }
            }
            
            DispatchQueue.main.async {
                self.images = loadedImages
                self.isLoading = false // Set isLoading back to false
            }
        }
    }

    
    func runSlideshow() {
        // Create a separate window for the slideshow
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 800, height: NSScreen.main?.frame.height ?? 600),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        // Set window background color to black
        window.backgroundColor = NSColor.black
        
    
        // Hide the menu bar and dock

        NSApp.presentationOptions = [
            //.autoHideMenuBar,
            .hideDock]
        
        let slideshowView = SlideshowView(images: images, slideshowDelay: slideshowDelay, randomOrder: randomOrder)
        
        window.contentView = NSHostingView(rootView: slideshowView)
        
        window.makeKeyAndOrderFront(nil)
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
