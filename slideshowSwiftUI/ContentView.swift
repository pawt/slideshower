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

enum ActiveAlert: Identifiable {
    case photoCounter, thumbnailAlert
    
    var id: Self {
        return self
    }
}

struct ContentView: View {
    @EnvironmentObject var slideshowManager: SlideshowManager
    @EnvironmentObject var updaterControllerWrapper: UpdaterControllerWrapper
    
    @State private var images: [IdentifiableImage] = []
    @State private var selectedFileNames: [String] = []
    @State private var slideshowDelay: Double = 3.0
    @State private var delayInput: String = "3"
    @State private var randomOrder = false

    @State private var showAlert = false
    @State private var showPhotoCounterInfo = false // TODO: to remove, not used anymore
    @State private var isLoading = false
    @State private var isHovered = false
    @State private var loopSlideshow = false
    @State private var useFadingTransition = false
    
    @State private var isInfoVisible = false
//    @State private var isVersionPopoverPresented = false
    
    @State private var progress = 0.0
    @State private var totalImagesToLoad = 0.0
    @State private var totalPhotosAdded = 0
    
    @State private var showErasePhotosAlert = false
    @State private var confirmDeletePhotos = false
    
    @State private var showThumbnailAlert = false // TODO: to remove, not used anymore
    @State private var urlsToLoad: [URL] = []
    @State private var totalPhotosToBeAdded = 0
    
    @State private var thumbnailsEnabledTreshold = 200
    @State private var displayThumbnails = true
    
    @State private var activeAlert: ActiveAlert?
    
    @State private var hideThumbnailsButton: Bool = false
    
    @State private var isUpdatePopoverPresented = false
    
    // Determines if the thumbnails should be displayed
    private var shouldDisplayThumbnails: Bool {
        return displayThumbnails && !hideThumbnailsButton && images.count <= thumbnailsEnabledTreshold
    }
    
    var body: some View {
        
        VStack() {
            
            HStack {
                
                ZStack(alignment: .bottomTrailing) {
                    
                    VStack {
                        
                        ZStack {
                            
                            // Display thumbnails or filenames
                            VStack {
                                if shouldDisplayThumbnails && !images.isEmpty {
                                    ImageView(identifiableImages: images)
                                } else if !shouldDisplayThumbnails {
                                    List(images) { image in
                                        Text(image.filename) // Assume 'filename' is a property of IdentifiableImage
                                    }
                                }
                            }
                            
                            
                            // Display the progress view for the first time loading
                            if isLoading && totalPhotosAdded == 0 {
                                VStack {
                                    Text("Adding \(totalPhotosToBeAdded) photos...")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.top, 20)
                                    ProgressView(value: progress, total: totalImagesToLoad)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(maxWidth: 400)
                                        .padding(20)
                                }
                                .background(Color.white)
                            }
                            
                            
                            // Display the progress view with border for subsequent loading
                            else if isLoading {
                                VStack {
                                    Text("Adding \(totalPhotosToBeAdded) photos...")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.top, 20)
                                    ProgressView(value: progress, total: totalImagesToLoad)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(maxWidth: 400)
                                        .padding(20)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                        .background(Color.white)
                                )
                                .padding(20)
                            }
                            
                            // Display the placeholder when no images are loaded
                            else if images.isEmpty {
                                VStack {
                                    Image("slideshower_logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 300)
                                        .opacity(0.5)
                                    Text("Selected photos will appear here")
                                        .fontWeight(.light)
                                        .foregroundColor(Color(hue: 1.0, saturation: 0.0, brightness: 0.831))
                                        .font(.title2)
                                }
                                
                            }
                            
                        }
//                        .border(Color.orange, width: 2)

                    }
                    // .border(Color.green, width:2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            
                    
                    // Button to toggle between thumbnail and filename view
                    Button(action: {
                        self.hideThumbnailsButton.toggle()
                    }) {
                        Image(systemName: hideThumbnailsButton ? "eye.fill" : "eye.slash.fill")
                            .padding(.init(top: 0, leading: 2, bottom: 0, trailing: 2))
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .offset(x:-70, y:-20)
                    .help(hideThumbnailsButton ? "Show thumbnails" : "Hide thumbnails")
                    .onHover { inside in
                        isHovered = inside
                        NSCursor.pointingHand.set()
                    }
                    .disabled(!displayThumbnails)
                    
                    Button(action: {
                        // Check if there are any photos added
                        if !images.isEmpty {
                            // If there are photos, show the alert
                            self.showErasePhotosAlert = true}
                    }
                           // If there are no photos, do nothing
                    )
                    {
                        Image(systemName: "trash")
                            .padding(.init(top: 0, leading: 2, bottom: 0, trailing: 2))
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .offset(x:-25, y:-20)
                    .help("Delete all added photos")
                    .onHover { inside in
                        isHovered = inside
                        NSCursor.pointingHand.set()
                    }
                    .alert(isPresented: $showErasePhotosAlert) {
                        Alert(
                            title: Text("Confirm Deletion"),
                            message: Text("Do you really want to remove all added files?"),
                            primaryButton: .destructive(Text("Yes")) {
                                // Perform the deletion
                                confirmDeletePhotos = true
                                removeAllImages()
                            },
                            secondaryButton: .cancel {
                                // User chose not to delete
                                confirmDeletePhotos = false
                            }
                        )
                    }
                    
                    
                }
            }
            .background(Color(NSColor.textBackgroundColor))

            Spacer()

            HStack(alignment: .top){
                
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
                            self.urlsToLoad = openPanel.urls
                            prepareForLoadingImages(urls: openPanel.urls)
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
                    .alert(item: $activeAlert) { activeAlert in
                        switch activeAlert {
                        case .photoCounter:
                            return Alert(
                                title: Text("\(selectedFileNames.count) photos added"),
                                dismissButton: .default(Text("OK"))
                            )
                        case .thumbnailAlert:
                            return Alert(
                                title: Text("Important Info"),
                                message: Text("You are going to import \(totalPhotosToBeAdded) photos. Total num of photos added will be more than \(thumbnailsEnabledTreshold), so thumbnails will not be displayed (faster import)."),
                                dismissButton: .default(Text("OK")) {
                                    processSelectedUrls(urls: self.urlsToLoad)
                                }
                            )
                        }
                    }
                    
                    Divider()
                        .padding(.init(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .frame(width:200)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.secondary)
                        Text("Total num of photos added: \(totalPhotosAdded)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    
                }
                .padding(.init(top: 0, leading: 50, bottom: 0, trailing: 0))
                .frame(width:300)
            
                
                VStack {
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
                                .padding(.init(top: 0, leading: 10, bottom: 10, trailing: 10))
                            }
                            .padding(0)
                            
                            Divider()
                                .padding(5)
                            
                            VStack(alignment: .leading) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pause.circle")
                                        .foregroundColor(.secondary)
                                    Text("Spacebar: pause the slideshow.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)
                                    Text("Right arrow: go to next photo.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.left")
                                        .foregroundColor(.secondary)
                                    Text("Left arrow: go to previous photo.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "escape")
                                        .foregroundColor(.secondary)
                                    Text("Escape: quit the slideshow.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                        }
                }
                .frame(width: 300)

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
                            message: Text("Please add images before running the slideshow."),
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
                .frame(width:300)
                
                Spacer()

            }
            .onChange(of: isHovered) { _ in
                if !isHovered {
                    NSCursor.arrow.set()
                }
            }
            .padding(.bottom, 20)
            .padding(.horizontal)
            .frame(maxHeight: 300)
            
            Spacer()
                        
            HStack {
                Text("If you like this app")
                    .font(.caption)
                    .padding(.init(top: 0, leading: 10, bottom: 7, trailing: -5))
                Link("buy me a coffee :)", destination: URL(string: "https://www.buymeacoffee.com/slideshower")!)
                    .font(.caption)
                    .padding(.init(top: 0, leading: 0, bottom: 7, trailing: 0))
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
                    .padding(.init(top: 0, leading: 0, bottom: 7, trailing: 0))
//                    .onTapGesture {
//                        self.isVersionPopoverPresented = true
//                    }
//                    .popover(isPresented: $isVersionPopoverPresented) {
//                        VStack {
//                            Text("Slideshower version")
//                                .font(.headline)
//                                .padding(.init(top: 5, leading: 0, bottom: 0, trailing: 0))
//                            Text("Go to www.slideshower.com to see the latest version available.")
//                                .padding()
//                        }
//                        .padding(10)
//                        .frame(width: 400)
//                    }
//                    .onTapGesture {
//                            self.isVersionPopoverPresented = true
//                    }
//                    .popover(isPresented: $isVersionPopoverPresented) {
//                        VStack {
////                            Text("Slideshower version")
////                                .font(.headline)
////                                .padding(.init(top: 5, leading: 0, bottom: 0, trailing: 0))
////                            Text("Slideshower version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")")
////                                .padding(.init(top: 5, leading: 0, bottom: 0, trailing: 0))
//                            Button("Check for Updates") {
//                                // Assuming you have access to updaterController here
//                                updaterControllerWrapper.updaterController?.checkForUpdates(nil)
//                            }
//                            .padding()
//                        }
//                        .frame(width: 200)
//                    }
                
                Button("Check for updates") {
                    self.checkForUpdatesButtonClicked()
                }
                .font(.caption)
                .padding(.init(top: 0, leading: 0, bottom: 10, trailing: 10))
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
//                Link("https://slideshower.com", destination: URL(string: "https://slideshower.com")!)
//                    .font(.caption)
//                    .padding(.init(top: 0, leading: 0, bottom: 10, trailing: 10))
//                    .onHover { hovering in
//                        if hovering {
//                            NSCursor.pointingHand.push()
//                        } else {
//                            NSCursor.pop()
//                        }
//                    }
            }
        }
    }
    
    // Function to handle the preparation of loading images
    func prepareForLoadingImages(urls: [URL]) {
        
        totalPhotosToBeAdded = urls.reduce(0) { (result, url) -> Int in
            if url.hasDirectoryPath {
                do {
                    // Get the content of the directory
                    let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    // Filter out non-image files
                    let imageFileURLs = fileURLs.filter {
                        let fileType = $0.pathExtension.lowercased()
                        return ["jpg", "jpeg", "png", "heic"].contains(fileType)
                    }
                    print("Directory: \(url.lastPathComponent), Image file count: \(imageFileURLs.count)")
                    return result + imageFileURLs.count
                } catch {
                    print("Error reading contents of directory: \(error)")
                    return result
                }
            } else {
                // If it's not a directory, check if it's an image file
                let fileType = url.pathExtension.lowercased()
                if ["jpg", "jpeg", "png", "heic"].contains(fileType) {
                    return result + 1
                } else {
                    return result
                }
            }
        }
        
        if totalPhotosAdded > thumbnailsEnabledTreshold {
            processSelectedUrls(urls: urls)
        } else {
            // Check if adding the new photos will exceed the threshold.
            if totalPhotosToBeAdded + totalPhotosAdded > thumbnailsEnabledTreshold {
                // Set the active alert to thumbnailAlert
                activeAlert = .thumbnailAlert
            } else {
                processSelectedUrls(urls: urls)
            }
        }
    }
    
    func processSelectedUrls(urls: [URL]) {
        var allUrlsToLoad: [URL] = []

        for url in urls {
            if url.hasDirectoryPath {
                // Add all image URLs from the directory to `allUrlsToLoad`
                do {
                    let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    allUrlsToLoad += fileURLs.filter {
                        let fileType = $0.pathExtension.lowercased()
                        return ["jpg", "jpeg", "png", "heic"].contains(fileType)
                    }
                } catch {
                    print("Error reading directory contents: \(error)")
                }
            } else {
                // Add single image URL to `allUrlsToLoad`
                allUrlsToLoad.append(url)
            }
        }

        // Update totalImagesToLoad for the progress view
        DispatchQueue.main.async {
            self.totalImagesToLoad = Double(allUrlsToLoad.count)
        }

        // Load all images at once
        loadImages(from: allUrlsToLoad) {
            // This will be called once all images are loaded
            self.activeAlert = .photoCounter
            // Check if the threshold is exceeded and update the thumbnail display
            if self.totalPhotosAdded > self.thumbnailsEnabledTreshold {
                self.displayThumbnails = false
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
        
        print("loadImages method is started.")
        
        // Reset progress and update totalImagesToLoad
        DispatchQueue.main.async {
            self.progress = 0
//            self.totalImagesToLoad = Double(urls.count)
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
                
                // Update displayThumbnails based on the new total
                if self.totalPhotosAdded <= self.thumbnailsEnabledTreshold {
                    self.displayThumbnails = true
                }
                
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
    
    func checkForUpdatesButtonClicked() {

        // Get the current version string directly
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        
        // Pass the version string as part of the segmentation dictionary
        Countly.sharedInstance().recordEvent("check_for_updates_clicked", segmentation: ["version": currentVersion], count: 1)
        
        // This is the action tied to your "Check for updates" button
        updaterControllerWrapper.updaterController?.checkForUpdates(nil)
        


    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            
    }
}
