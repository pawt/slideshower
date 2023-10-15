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
    
    let backgroundGradient = LinearGradient(
        colors: [Color.white, Color.white],
        startPoint: .top, endPoint: .bottom)
    
    var body: some View {
        VStack(alignment: .leading) {
            
            /**            if !images.isEmpty {
             //ImageView(identifiableImages: images)
             Text("Selected Files:")
             List(selectedFileNames, id: \.self, rowContent: { fileName in
             Text(fileName)
             })
             }
             */
            
            // Use a fixed frame for the list
        
            
            ScrollView(.vertical) {
                VStack {
                    
                    if !images.isEmpty {
                        ImageView(identifiableImages: images)
                            .frame(height: 300)
                    }
                    
                    // Fixed frame and scrollbar for selected file names
 /**                   List(selectedFileNames, id: \.self) { fileName in
                        Text(fileName)
                    }
                    .frame(height: 200) // Set the fixed height
  */
                }
            }
            
            // Label displaying the number of files
            if !images.isEmpty {
                HStack(alignment: .center) {
                    Text("\(selectedFileNames.count) files on the list")
                        .font(.headline)
                    .padding(.top, 10)
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
            .padding()
        
            
            
            GroupBox(label: Text("Settings")
                .font(.subheadline)
                .padding(.bottom, 5)) {
                    VStack(alignment: .leading) {
                        Toggle("Random Order", isOn: $randomOrder)
                            .padding(6)
                        HStack {
                            Text("Slideshow Delay (in sec):")
                            TextField("Enter delay", text: $delayInput)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: delayInput) { newValue in
                                    if let delay = Double(newValue) {
                                        slideshowDelay = delay
                                    }
                                }
                        }
                        .padding(6)
                    }
                    
                    
                }
                .position(x: 150, y: 100)
            
            Button("Run Slideshow") {
                if images.isEmpty {
                    showAlert = true
                } else {
                    runSlideshow()
                }
            }
            .padding()
            .controlSize(.large)
            .position(x: 450, y: -20)
            .buttonStyle(.borderedProminent)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("No Images Selected"),
                    message: Text("Please select images before running the slideshow."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .background(Color("CustomColor"))
    }
       
    
    func loadImages(from urls: [URL]) {
        images.removeAll()
        
        for url in urls {
            if let nsImage = NSImage(contentsOf: url) {
                let fileName = url.lastPathComponent
                selectedFileNames.append(fileName)
                images.append(IdentifiableImage(image: Image(nsImage: nsImage)))
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
