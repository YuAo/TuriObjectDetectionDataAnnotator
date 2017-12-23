//
//  AnnotationView.swift
//  TuriObjectDetectionAnnotator
//
//  Created by Yu Ao on 23/12/2017.
//  Copyright © 2017 yuao. All rights reserved.
//

import Cocoa

fileprivate class BoundingBoxTextLabel: NSTextField {
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    private func setup() {
        self.isEditable = false
        self.font = NSFont.boldSystemFont(ofSize: 13)
        self.isBordered = false
        let trackingArea = NSTrackingArea(rect: .zero, options: [.inVisibleRect,.activeInKeyWindow,.cursorUpdate,.mouseMoved], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        NSCursor.openHand.set()
    }
    
    var mouseDraggedHandler: ((NSEvent)-> Void)?
    
    override func mouseDragged(with event: NSEvent) {
        self.mouseDraggedHandler?(event)
    }
}

class BoundingBoxView: NSView {
    
    var label: String = "" {
        didSet {
            self.textLabel.stringValue = self.label
            self.needsLayout = true
        }
    }
    
    var color: NSColor = NSColor.green {
        didSet {
            self.layer?.borderColor = self.color.cgColor
            self.textLabel.backgroundColor = self.color
        }
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    fileprivate weak var textLabel: NSTextField!
    
    private func setup() {
        self.wantsLayer = true
        self.layer?.borderWidth = 2
        
        let textLabel = BoundingBoxTextLabel(frame: self.bounds)
        textLabel.mouseDraggedHandler = { [unowned self] event in
            self.draggedHandler?(event)
        }
        self.addSubview(textLabel)
        self.textLabel = textLabel
        
        self.color = NSColor.green
    }
    
    override func layout() {
        super.layout()
        self.textLabel.sizeToFit()
        if self.textLabel.frame.width < 40 {
            self.textLabel.frame.size.width = 40
        }
        self.textLabel.frame.origin = .zero
    }
    
    var draggedHandler: ((NSEvent)-> Void)?
}

class AnnotationView: NSView {
    
    private var imageSize: NSSize = .zero
    
    private(set) var boundingBoxes: [BoundingBox] {
        set {
            _boundingBoxes = newValue
            self.boundingBoxViews.forEach {
                $0.removeFromSuperview()
            }
            self.boundingBoxViews = []
            for box in _boundingBoxes {
                let view = BoundingBoxView(frame: .zero)
                view.label = box.label
                view.draggedHandler = { [unowned view, unowned self] event in
                    view.frame = view.frame.offsetBy(dx: event.deltaX, dy: -event.deltaY)
                    self.updateBoundingBoxWithViews()
                }
                self.addSubview(view)
                self.boundingBoxViews.append(view)
            }
            self.needsLayout = true
        }
        get {
            return _boundingBoxes
        }
    }
    
    private var _boundingBoxes: [BoundingBox] = []
    
    private func updateBoundingBoxWithViews() {
        var boundingBoxes = self.boundingBoxes
        for (i,box) in self.boundingBoxes.enumerated() {
            var boundingBox = box;
            let view = self.boundingBoxViews[i]
            boundingBox.coordinates = self.coordinatesFromBoundingBoxView(view)
            boundingBoxes[i] = boundingBox
        }
        _boundingBoxes = boundingBoxes
        self.boundingBoxesChangedHandler?(_boundingBoxes)
    }
    
    private func coordinatesFromBoundingBoxView(_ view: BoundingBoxView) -> Coordinates {
        var coordinates = Coordinates()
        coordinates.x = Int(round(view.frame.midX/self.bounds.width * self.imageSize.width))
        coordinates.y = Int(round((1.0 - view.frame.midY/self.bounds.height) * self.imageSize.height))
        coordinates.width = Int(round(view.frame.width/self.bounds.width * self.imageSize.width))
        coordinates.height = Int(round(view.frame.height/self.bounds.height * self.imageSize.height))
        return coordinates
    }
    
    private var boundingBoxViews: [BoundingBoxView] = []
    
    func update(imageSize: CGSize, boundingBoxes: [BoundingBox]) {
        self.imageSize = imageSize
        self.boundingBoxes = boundingBoxes
    }
    
    var boundingBoxesChangedHandler: (([BoundingBox]) -> Void)?
    
    override func layout() {
        super.layout()
      
        for (i,box) in self.boundingBoxes.enumerated() {
            let view = self.boundingBoxViews[i]
            let x = CGFloat(box.coordinates.x - box.coordinates.width/2)/self.imageSize.width * self.bounds.width
            let y = (1.0 - CGFloat(box.coordinates.y + box.coordinates.height/2)/self.imageSize.height) * self.bounds.height
            let width = CGFloat(box.coordinates.width)/self.imageSize.width * self.bounds.width
            let height = CGFloat(box.coordinates.height)/self.imageSize.height * self.bounds.height
            view.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    private func setup() {
        self.wantsLayer = true
        //self.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.2).cgColor
        
        let clickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick))
        clickGestureRecognizer.numberOfClicksRequired = 2
        self.addGestureRecognizer(clickGestureRecognizer)
        
        let trackingArea = NSTrackingArea(rect: .zero, options: [.inVisibleRect,.activeInKeyWindow,.cursorUpdate,.mouseMoved], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    @objc private func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
        for (i,boxView) in self.boundingBoxViews.reversed().enumerated() {
            let index = self.boundingBoxes.count - i - 1
            let box = self.boundingBoxes[index]
            if boxView.textLabel.frame.contains(sender.location(in: boxView)) {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("Rename", comment: "")
                alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                let inputTextField = NSTextField(string: box.label)
                inputTextField.sizeToFit()
                inputTextField.frame.size.width = 300
                alert.accessoryView = inputTextField
                alert.beginSheetModal(for: self.window!, completionHandler: { response in
                    if response == .alertFirstButtonReturn && inputTextField.stringValue.count > 0 {
                        self.boundingBoxes[index].label = inputTextField.stringValue
                        self.boundingBoxesChangedHandler?(self.boundingBoxes)
                    }
                    if response == .alertSecondButtonReturn {
                        self.boundingBoxes.remove(at: index)
                        self.boundingBoxesChangedHandler?(self.boundingBoxes)
                    }
                })
                inputTextField.becomeFirstResponder()
                break
            }
        }
    }
    
    enum BoxBorder {
        case none
        case left
        case right
        case top
        case bottom
    }
    
    private var activeBorder: BoxBorder = .none
    
    private weak var activeBoundingBoxView: BoundingBoxView? = nil
    
    override func mouseMoved(with event: NSEvent) {
        if let view = self.newlyCreatedBoundingBoxView {
            self.newlyCreatedBoundingBoxView = nil
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("Rename", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            let inputTextField = NSTextField(string: "Unknown")
            inputTextField.sizeToFit()
            inputTextField.frame.size.width = 300
            alert.accessoryView = inputTextField
            alert.beginSheetModal(for: self.window!, completionHandler: { [unowned self] response in
                view.removeFromSuperview()
                if response == .alertFirstButtonReturn && inputTextField.stringValue.count > 0 {
                    let boundingBox = BoundingBox(coordinates: self.coordinatesFromBoundingBoxView(view), label: inputTextField.stringValue)
                    self.boundingBoxes.append(boundingBox)
                    self.boundingBoxesChangedHandler?(self.boundingBoxes)
                }
            })
            inputTextField.becomeFirstResponder()
            return
        }
        for boxView in self.boundingBoxViews.reversed() {
            let locationInView = self.window!.contentView!.convert(event.locationInWindow, to: self)
            
            let frame = boxView.frame
            
            var topBorderFrame = frame
            topBorderFrame.size.height = 0
            topBorderFrame = topBorderFrame.insetBy(dx: 0, dy: -5)
            
            var bottomBorderFrame = frame
            bottomBorderFrame.origin.y += frame.height
            bottomBorderFrame.size.height = 0
            bottomBorderFrame = bottomBorderFrame.insetBy(dx: 0, dy: -5)
            
            var leftBorderFrame = frame
            leftBorderFrame.size.width = 0
            leftBorderFrame = leftBorderFrame.insetBy(dx: -5, dy: 0)

            var rightBorderFrame = frame
            rightBorderFrame.origin.x += frame.width
            rightBorderFrame.size.width = 0
            rightBorderFrame = rightBorderFrame.insetBy(dx: -5, dy: 0)
            
            if topBorderFrame.contains(locationInView) {
                NSCursor.resizeUpDown.set()
                self.activeBoundingBoxView = boxView
                self.activeBorder = .top
                break
            } else if bottomBorderFrame.contains(locationInView) {
                NSCursor.resizeUpDown.set()
                self.activeBoundingBoxView = boxView
                self.activeBorder = .bottom
                break
            } else if leftBorderFrame.contains(locationInView) {
                NSCursor.resizeLeftRight.set()
                self.activeBoundingBoxView = boxView
                self.activeBorder = .left
                break
            } else if rightBorderFrame.contains(locationInView) {
                NSCursor.resizeLeftRight.set()
                self.activeBoundingBoxView = boxView
                self.activeBorder = .right
                break
            } else {
                NSCursor.arrow.set()
                self.activeBoundingBoxView = nil
                self.activeBorder = .none
            }
        }
    }
    
    private weak var newlyCreatedBoundingBoxView: BoundingBoxView?
    private var newlyCreatedBoundingBoxSize: CGSize = .zero
    
    override func moveUp(_ sender: Any?) {
        print("mouse up")
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let activeView = self.activeBoundingBoxView {
            var frame = activeView.frame
            switch self.activeBorder {
            case .left:
                frame.origin.x -= -event.deltaX
                frame.size.width += -event.deltaX
            case .right:
                frame.size.width += event.deltaX
            case .top:
                frame.origin.y -= event.deltaY
                frame.size.height += event.deltaY
            case .bottom:
                frame.size.height += -event.deltaY
            case .none:
                break
            }
            activeView.frame = frame
            self.updateBoundingBoxWithViews()
        } else {
            if let boundingBoxView = self.newlyCreatedBoundingBoxView {
                var frame = boundingBoxView.frame
                self.newlyCreatedBoundingBoxSize.height += -event.deltaY
                self.newlyCreatedBoundingBoxSize.width += event.deltaX
                if self.newlyCreatedBoundingBoxSize.width < 0 {
                    frame.origin.x += event.deltaX
                }
                frame.size.width = abs(self.newlyCreatedBoundingBoxSize.width)

                if self.newlyCreatedBoundingBoxSize.height < 0 {
                    frame.origin.y -= event.deltaY
                }
                frame.size.height = abs(self.newlyCreatedBoundingBoxSize.height)
                
                boundingBoxView.frame = frame
            } else {
                let locationInView = self.window!.contentView!.convert(event.locationInWindow, to: self)
                let boundingBoxView = BoundingBoxView(frame: CGRect(origin: locationInView, size: .zero))
                self.addSubview(boundingBoxView)
                self.newlyCreatedBoundingBoxView = boundingBoxView
                self.newlyCreatedBoundingBoxSize = .zero
            }
        }
    }
    
}
