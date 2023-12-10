//
//  KeyPressHandlingView.swift
//  Slideshower for macOS
//
//  Created by Paweł Trybulski on 22/11/2023.
//

import SwiftUI
import AppKit

struct KeyPressHandlingView: NSViewRepresentable {
    var onKeyPress: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyPressInterceptingView()
        view.onKeyPress = onKeyPress
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class KeyPressInterceptingView: NSView {
        var onKeyPress: ((NSEvent) -> Void)?

        // This property tells the window that this view wants to become the first responder
        override var acceptsFirstResponder: Bool { true }

        // This method is called when the view is about to become the first responder
        override func becomeFirstResponder() -> Bool {
            NSApp.keyWindow?.makeFirstResponder(self)
            return true
        }

        override func keyDown(with event: NSEvent) {
            print("Key pressed: \(event.keyCode)")
            onKeyPress?(event)
        }
    }
}
