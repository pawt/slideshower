//
//  ContentView.swift
//  slideshowSwiftUI
//
//  Created by Paweł Trybulski on 11/10/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import Countly
import Foundation

struct ContentView: View {
    @EnvironmentObject var slideshowManager: SlideshowManager
    
    @State private var images: [IdentifiableImage] = []
    @State private var selectedFileNames: [String] = []
    @State private var slideshowDelay: Double = 3.0
    @State private var delayInput: String = "3"
    @State private var randomOrder = false
    @State private var showAlert = false
    @State private var showPhotoCounterInfo = false
    @State private var isLoading = false
    @State private var isHovered = false
    @State private var loopSlideshow = false
    @State private var useFadingTransition = false
    
    @State private var isInfoVisible = false
    @State private var isVersionPopoverPresented = false
    
    @State private var progress = 0.0
    @State private var totalImagesToLoad = 0.0
    @State private var totalPhotosAdded = 0

    
    // Determines if the thumbnails should be displayed
    private var shouldDisplayThumbnails: Bool {
        return images.count <= 50
    }
    
    var body: some View {
        
        VStack() {
            
            ZStack(alignment: .bottomTrailing) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack() {
                        ZStack {
                            if shouldDisplayThumbnails {
                                if !images.isEmpty {
                                    ImageView(identifiableImages: images)
                                        .frame(minHeight: 550)
                                        .background(Color.white)
                                }
                            } else {
                                // A new view that only displays filenames
                                List(images) { image in
                                    Text(image.filename) // Assume 'filename' is a property of IdentifiableImage
                                }
                            }
                            
                            if (isLoading && totalPhotosAdded==0) {

                                    Color.white // Set the background color of the VStack
                                        .frame(minHeight: 550)
                                    ProgressView(value: progress, total: totalImagesToLoad)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(maxWidth: .infinity) // Makes the progress bar wider
                                        .padding(100) // Adds some padding around the progress bar
 
                            }
                            else if isLoading {
                                VStack {
                                    Text("Loading Photos...")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.top, 20)
                                    ProgressView(value: progress, total: totalImagesToLoad)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(maxWidth: 400)
                                        .padding(20)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10) // Rounded rectangle background
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5) // Light grey border
                                        .background(Color.white) // White fill for the rounded rectangle
                                )
                                .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
                            } else if images.isEmpty {
                                Color.white // Set the background color of the VStack
                                    .frame(minHeight: 550)
                                Image("slideshower_logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:300)
                                    .opacity(0.5)
                                Text("Selected photos will appear here")
                                    .fontWeight(.light)
                                    .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.831))
                                    .font(.title2)
                                    .offset(y: 100)
                            }
                        }
                        .frame(minHeight: 550) // Set the initial height of the scrollable panel
                    }
                }
                Button(action: removeAllImages) {
                    Image(systemName: "trash")
                        .padding(.init(top: 5, leading: 7, bottom: 5, trailing: 0))

                }
                .buttonStyle(BorderedButtonStyle())
                .padding(.trailing, 25)
                .padding(.bottom, 15)
                .help("Delete all added photos")
                .onHover { inside in
                    isHovered = inside
                    NSCursor.pointingHand.set()
                }
            }
            

            HStack(alignment: .top, spacing: 0){
                Spacer()
                VStack {
                    VStack(alignment: .center) {
                        Text("Add photos")
                            .font(.title2)
                            .padding(.init(top: 20, leading: 0, bottom: 10, trailing: 0))
                    }
                    
                    Button(action: {
                        let openPanel = NSOpenPanel()
                        openPanel.allowsMultipleSelection = true
                        openPanel.canChooseDirectories = true
                        openPanel.canChooseFiles = true
                        openPanel.allowedContentTypes = [UTType.jpeg, UTType.png, UTType.heic]
                        
                        self.selectedFileNames.removeAll() // Reset the file names before adding new ones
                        
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
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { inside in
                        isHovered = inside
                        NSCursor.pointingHand.set()
                    }
                    .alert(isPresented: $showPhotoCounterInfo, content: {
                        Alert(
                            title: Text("\(selectedFileNames.count) photos added"),
                            dismissButton: .default(Text("OK"))
                        )
                    })
                    
                    Divider()
                        .padding(5)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.secondary)
                        Text("Total photos added: \(totalPhotosAdded)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    
                }
                .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 50))
                
                GroupBox(label: Text("Settings")
                    .font(.title2)
                    .padding(.init(top: 20, leading: 0, bottom: 10, trailing: 0))
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
                                            Text("Delay")
                                                .fontWeight(.bold)
                                            Text("- sets the timing between consecutive photos.")
                                        }
                                        HStack {
                                            Text("Shuffle mode")
                                                .fontWeight(.bold)
                                            Text("- if enabled the photos will be shown in a shuffle mode.")
                                        }
                                        HStack {
                                            Text("Fading transition")
                                                .fontWeight(.bold)
                                            Text("- if enabled there will be a fading transition between photos.")
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
                                Text("Delay between photos (in sec):")
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
                                Text("Fading transition:")
                                Spacer()
                                Toggle("", isOn: $useFadingTransition)
                            }
                            .padding(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                            HStack {
                                Text("Loop slideshow:")
                                Spacer()
                                Toggle("", isOn: $loopSlideshow)
                            }
                            .padding(.init(top: 0, leading: 10, bottom: 20, trailing: 10))
                        }
                        .padding(0)
                        
                        Divider()
                            .padding(5)

                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle")
                                .foregroundColor(.secondary)
                            Text("SPACEBAR pauses the slideshow.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "escape")
                                .foregroundColor(.secondary)
                            Text("ESC quits the slideshow.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                    }
                    .frame(maxWidth: 300)
            

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
                            .padding(.init(top: 16, leading: 40, bottom: 16, trailing: 40))
                            .background(RoundedRectangle(cornerRadius:8).fill(Color(hue: 0.295, saturation: 1.0, brightness: 0.68)))
                            .frame(minWidth: 100)
//                            .disabled(isSlideshowRunning)
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
                    .disabled(slideshowManager.isSlideshowRunning)
                    
                    Button(action: {
                        slideshowManager.isSlideshowRunning = false
                    })
                    {
                        Text("Stop").font(.system(size: 13))
                            .foregroundStyle(Color.white)
                            .shadow(radius: 5)
                            .padding(.init(top: 16, leading: 40, bottom: 16, trailing: 40))
                            .background(RoundedRectangle(cornerRadius:8).fill(Color(hue: 1.0, saturation: 0.7, brightness: 0.8)))
                            .frame(minWidth: 100)
//                            .disabled(isSlideshowRunning)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { inside in
                        isHovered = inside
                        NSCursor.pointingHand.set()
                    }
                    .disabled(!slideshowManager.isSlideshowRunning)

                    
                    if (slideshowManager.isSlideshowRunning) {
                        Label("Slideshow is running. Stop it to start another one.", systemImage: "exclamationmark.triangle")
                               .foregroundColor(Color.red)
                               .font(.caption)
                               .padding()
                               .background(Color.yellow.opacity(0.2))
                               .cornerRadius(10)
                               .frame(maxWidth:200)
                        }
                }
                .padding(.leading, 60)
                
                Spacer()

            }
            .padding(.bottom, 20)
            .padding(.horizontal, 40.0)
            .padding(.trailing, 0)
            .onChange(of: isHovered) { _ in
                if !isHovered {
                    NSCursor.arrow.set()
                }
            }
            
            
            Spacer()
                        
                        HStack {
                            Text("If you like this app")
                                .font(.caption)
                                .padding(.init(top: 0, leading: 10, bottom: 10, trailing: -5))
                            Link("support its development.", destination: URL(string: "https://www.buymeacoffee.com/slideshower")!)
                                .font(.caption)
                                .padding(.init(top: 0, leading: 0, bottom: 10, trailing: 0))
                                .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                            Spacer()
                        
                            
                            Label("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")", systemImage: "info.circle")
                                .font(.caption)
                                .padding(.init(top: 0, leading: 0, bottom: 10, trailing: 0))
                                .onTapGesture {
                                    self.isVersionPopoverPresented = true
                                }
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                                .popover(isPresented: $isVersionPopoverPresented) {
                                    VStack {
                                        Text("Slideshower version")
                                            .font(.headline)
                                            .padding(.init(top: 5, leading: 0, bottom: 0, trailing: 0))
                                        Text("Go to www.slideshower.com to see the latest version available.")
                                            .padding()
                                    }
                                    .padding(10)
                                    .frame(width: 400)
                                }
                            
                            Link("https://slideshower.com", destination: URL(string: "https://slideshower.com")!)
                                .font(.caption)
                                .padding(.init(top: 0, leading: 0, bottom: 10, trailing: 10))
                                .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
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
        
        // Reset progress and update totalImagesToLoad
        DispatchQueue.main.async {
            self.progress = 0
            self.totalImagesToLoad = Double(urls.count)
            self.isLoading = true
        }
        
        DispatchQueue.global(qos: .background).async {
            var newImages = [IdentifiableImage]()
            var newFileNames = [String]()
            
            for url in urls {
                if let nsImage = NSImage(contentsOf: url) {
                    let fileName = url.lastPathComponent
                    // Create the image and append it to your array
                    newFileNames.append(fileName)
                    newImages.append(IdentifiableImage(id: UUID(), image: Image(nsImage: nsImage), filename: fileName))
                    
                    // Update progress on the main thread
                    DispatchQueue.main.async {
                        self.progress += 1 // Increment progress for each image
                    }
                    
                }
            }
            
            DispatchQueue.main.async {
                self.images.append(contentsOf: newImages)
                self.selectedFileNames.append(contentsOf: newFileNames)
                self.totalPhotosAdded += newImages.count
                self.isLoading = false
                completion()
            }

        }
    }

    func removeAllImages() {
        totalPhotosAdded = 0
        images.removeAll()
        selectedFileNames.removeAll()
    }

    
    func runSlideshow() {
        
        slideshowManager.isSlideshowRunning = true
        
        // Assuming 'images' is your array of IdentifiableImage
        let slideshowSize = images.count
        let slideshowDelay = slideshowDelay
        let loopEnabled = loopSlideshow
        let shuffleEnabled = randomOrder
        let fadingEnabled = useFadingTransition
        let sessionID = UUID().uuidString
        
        // Key for the event
        let key = "slideshowStarted"

        // Count for the event
        let count: UInt = 1

        // Segmentation for the event
        let segmentation: [String : String] = ["sessionID": sessionID,
                                               "slideshowSize": String(slideshowSize),
                                               "slideshowDelay": String(slideshowDelay),
                                               "loopEnabled": String(loopEnabled),
                                               "shuffleEnabled": String(shuffleEnabled),
                                               "fadingEnabled": String(fadingEnabled)]

        // Record the event with segmentation
        Countly.sharedInstance().recordEvent(key, segmentation: segmentation, count: count)

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
            loopSlideshow: loopSlideshow,
            useFadingTransition: useFadingTransition
//            isSlideshowRunning: slideshowManager.isSlideshowRunning
        )
            .environmentObject(slideshowManager)

        window.contentView = NSHostingView(rootView: slideshowView)
        window.makeKeyAndOrderFront(nil)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            
    }
}
