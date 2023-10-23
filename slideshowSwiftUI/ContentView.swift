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
    @State private var delayInput: String = "3"
    @State private var randomOrder = false
    @State private var showAlert = false
    @State private var showPhotoCounterInfo = false
    @State private var isLoading = false
    @State private var isHovered = false
    @State private var loopSlideshow = false
    
    var body: some View {
    
        VStack() {
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack() {
                    ZStack {
                        if !images.isEmpty {
                            ImageView(identifiableImages: images)
                                .frame(minHeight: 600)
                                .background(Color.white) // Add this line
                                .cornerRadius(8) // Optional: Add corner radius for a rounded look
                        }
                        
                        if isLoading {
                            ProgressView("Loading Images...")
                                .frame(maxWidth: .infinity, minHeight: 600)
                                .background(Color.white)
                        } else if images.isEmpty {
                            Color.white // Set the background color of the VStack
                                .frame(minHeight: 600) // Set a fixed height
                            Text("Selected photos will appear here")
                                .fontWeight(.light)
                                .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.831))
                                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        }
                    }
                    .frame(height: 600) // Set the initial height of the scrollable panel
                }
            }
            
            
            
            HStack(alignment: .top){
                
                Spacer()
                
                VStack {
                    VStack(alignment: .center) {
                        Text("Please add files")
                            .font(.title2)
                            .padding(.init(top: 20, leading: 0, bottom: 10, trailing: 20))
                    }
                    
                    Button(action: {
                        let openPanel = NSOpenPanel()
                        openPanel.allowsMultipleSelection = true
                        openPanel.canChooseDirectories = false
                        openPanel.canChooseFiles = true
                        openPanel.allowedContentTypes = [UTType.jpeg, UTType.png, UTType.heic]
                        if openPanel.runModal() == .OK {
                            loadImages(from: openPanel.urls)
                        }
                    }) {
                        Text("Select files").font(.system(size: 13))
                            .foregroundStyle(Color.white)
                            .shadow(radius: 5)
                            .padding()
                            .background(RoundedRectangle(cornerRadius:8).fill(Color.blue))
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { inside in
                        isHovered = inside
                        NSCursor.pointingHand.set()
                    }
                    .padding(.init(top: 0, leading: 0, bottom: 10, trailing: 20))
                    .alert(isPresented: $showPhotoCounterInfo, content: {
                        Alert(
                            title: Text("\(selectedFileNames.count) files successfully added!"),
                            //message: Text("\(selectedFileNames.count) files have been added."),
                            dismissButton: .default(Text("OK"))
                        )
                    })
                }
                
                Spacer()
                
                GroupBox(label: Text("Settings")
                    .font(.title2)
                    .padding(.init(top: 20, leading: 0, bottom: 10, trailing: 20))
                    .frame(maxWidth: .infinity, alignment: .center)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Slideshow delay (in sec):")
                                Spacer()
                                TextField("Enter delay", text: $delayInput)
                                    .frame(width: 60)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                                    .onChange(of: delayInput) { newValue in
                                        if let delay = Double(newValue) {
                                            slideshowDelay = delay
                                        }
                                    }
                            }
                            HStack {
                                Text("Random slideshow order:")
                                Spacer()
                                Toggle("", isOn: $randomOrder)
                            }
                            HStack {
                                Text("Loop slideshow:")
                                Spacer()
                                Toggle("", isOn: $loopSlideshow)
                            }
                        }
                        .padding(12)
                    }
                    .frame(maxWidth: 300)
                
                Spacer()
                
                VStack() {
                    Text("Run slideshow")
                        .font(.title2)
                        .padding(.init(top: 20, leading: 0, bottom: 10, trailing: 0))
                    Button(action: {
                        if images.isEmpty {
                            showAlert = true
                        } else {
                            runSlideshow()
                        }
                    })
                    {
                        Text("Start").font(.system(size: 13))
                            .foregroundStyle(Color.white)
                            .shadow(radius: 5)
                            .padding(.init(top: 16, leading: 35, bottom: 16, trailing: 35))
                            .background(RoundedRectangle(cornerRadius:8).fill(Color.green))
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { inside in
                        isHovered = inside
                        NSCursor.pointingHand.set()
                    }
                    .alert(isPresented: $showAlert)
                    {
                        Alert(
                            title: Text("No Images Selected"),
                            message: Text("Please select images before running the slideshow."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                Spacer()
            }
            .padding(.bottom, 40)
            .onChange(of: isHovered) { _ in
                if !isHovered {
                    NSCursor.arrow.set()
                }
            }
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
                self.isLoading = false
                self.showPhotoCounterInfo = true
            }
        }
    }

    
    func runSlideshow() {
        // Create a separate window for the slideshow
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 800, height: NSScreen.main?.frame.height ?? 600),
            //styleMask: [.borderless, .fullSizeContentView],
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)
        
        window.isReleasedWhenClosed = false
        window.center()
        window.backgroundColor = NSColor.black
        
        // Hide the menu bar and dock
        NSApp.presentationOptions = [
            .autoHideMenuBar,
            .autoHideDock
        ]
        
        window.level = .mainMenu
        window.collectionBehavior = .fullScreenPrimary
        
        let slideshowView = SlideshowView(
            images: images,
            slideshowDelay: slideshowDelay,
            randomOrder: randomOrder,
            loopSlideshow: loopSlideshow
        )

        window.contentView = NSHostingView(rootView: slideshowView)
        window.makeKeyAndOrderFront(nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
