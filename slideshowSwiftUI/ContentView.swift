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
    @State private var isInfoVisible = false
    
    var body: some View {
    
        VStack() {
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack() {
                    ZStack {
                        if !images.isEmpty {
                            ImageView(identifiableImages: images)
                                .frame(minHeight: 500)
                                .background(Color.white)
                        }
                        if isLoading {
                            ProgressView("Loading Images...")
                                .frame(maxWidth: .infinity, minHeight: 500)
                                .background(Color.white)
                        } else if images.isEmpty {
                            Color.white // Set the background color of the VStack
                                .frame(minHeight: 500)
                            Image("slideshower_logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width:300)
                                .opacity(0.5)
                            Text("Selected photos will appear here")
                                .fontWeight(.light)
                                .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.831))
                                //.foregroundColor(Color(red:189, green:186, blue: 221))
                                .font(.title2)
                                .offset(y: 100)
                        }
                    }
                    .frame(height: 500) // Set the initial height of the scrollable panel
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
                        openPanel.canChooseDirectories = true
                        openPanel.canChooseFiles = true
                        openPanel.allowedContentTypes = [UTType.jpeg, UTType.png, UTType.heic]
                        if openPanel.runModal() == .OK {
                            let group = DispatchGroup()
                            
                            for url in openPanel.urls {
                                group.enter() // Enter the group
                                if url.hasDirectoryPath {
                                    addImagesFromDirectory(url) {
                                        group.leave() // Leave the group once images are loaded
                                    }
                                } else {
                                    loadImages(from: [url]) {
                                        group.leave() // Leave the group once image is loaded
                                    }
                                }
                            }
                            group.notify(queue: .main) {
                                // This will be called once all images are loaded
                                self.showPhotoCounterInfo = true
                            }
                        }
                    }) {
                        Text("Select files or a folder").font(.system(size: 13))
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
                            HStack() {
                                Spacer ()
                                Button(action: {
                                    isInfoVisible.toggle()
                                }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 14))
                                }
                                .help("Click for more information")
                                .buttonStyle(PlainButtonStyle())
                                .popover(isPresented: $isInfoVisible, content: {
                                    VStack {
                                        Text("Settings - help")
                                            .font(.headline)
                                            .padding()
                                        HStack {
                                            Text("Random slideshow order")
                                                .fontWeight(.bold)
                                            Text("- if enabled the files will be shown in a random order.")
                                        }
                                        HStack {
                                            Text("Loop slideshow")
                                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            Text("- if enabled the slideshow will not terminate itself.")
                                        }
                                    }
                                    .padding(.init(top: 10, leading: 10, bottom: 30, trailing: 10))
                                })
                            }
                            .padding(.init(top: 0, leading: 0, bottom: 5, trailing: 0))
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
                            .padding(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                            HStack {
                                Text("Shuffle mode:")
                                Spacer()
                                Toggle("", isOn: $randomOrder)
                            }
                            .padding(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                            HStack {
                                Text("Loop slideshow:")
                                Spacer()
                                Toggle("", isOn: $loopSlideshow)
                            }
                            .padding(.init(top: 0, leading: 10, bottom: 30, trailing: 10))
                        }
                        .padding(0)
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
                            .background(RoundedRectangle(cornerRadius:8).fill(Color(hue: 0.295, saturation: 1.0, brightness: 0.68)))
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
    
    func addImagesFromDirectory(_ directoryURL: URL, completion: @escaping () -> Void) {
        let fileManager = FileManager.default
        var urlsToLoad: [URL] = []
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                let fileType = fileURL.pathExtension.lowercased()
                if ["jpg", "jpeg", "png", "heic"].contains(fileType) {
                    urlsToLoad.append(fileURL)
                }
            }
            loadImages(from: urlsToLoad, completion: completion)
        } catch {
            print("Error reading directory contents: \(error)")
            completion()
        }
    }

        
    
    func loadImages(from urls: [URL], completion: @escaping () -> Void) {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async {
            var newImages = [IdentifiableImage]()
            var newFileNames = [String]()
            
            for url in urls {
                if let nsImage = NSImage(contentsOf: url) {
                    let fileName = url.lastPathComponent
                    newFileNames.append(fileName)
                    newImages.append(IdentifiableImage(id: UUID(), image: Image(nsImage: nsImage)))
                }
            }
            
            DispatchQueue.main.async {
                self.images.append(contentsOf: newImages)
                self.selectedFileNames.append(contentsOf: newFileNames)
                self.isLoading = false
                completion()
            }
        }
    }

    
    func runSlideshow() {
        // Create a separate window for the slideshow
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 800, height: NSScreen.main?.frame.height ?? 600),
            //styleMask: [.titled, .closable, .resizable],
            styleMask: [.fullSizeContentView, .closable, .resizable, .miniaturizable, .titled],
            backing: .buffered,
            defer: false)
        
        window.isReleasedWhenClosed = false
        window.center()
        window.backgroundColor = NSColor.black
        window.titlebarAppearsTransparent = true // Ensure the title bar is transparent
        window.titleVisibility = .hidden // Hide the title
        
        window.level = .mainMenu
        window.collectionBehavior = .fullScreenPrimary
        
        window.toggleFullScreen(nil)
        
        // Hide the menu bar and dock
        NSApp.presentationOptions = [
            .autoHideMenuBar,
            .autoHideDock
        ]
        
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
