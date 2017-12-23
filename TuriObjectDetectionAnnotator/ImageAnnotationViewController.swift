//
//  ImageAnnotationViewController.swift
//  TuriObjectDetectionAnnotator
//
//  Created by Yu Ao on 23/12/2017.
//  Copyright © 2017 yuao. All rights reserved.
//

import Cocoa
import AVFoundation

class ImageAnnotationViewController: NSViewController {
    
    var annotationInfo: ImageAnnotationInfo? {
        set {
            _annotationInfo = newValue
            if let annotationInfo = newValue {
                let image = NSImage(byReferencing: annotationInfo.imageURL)
                self.imageView.image = image
                let imageRep = image.representations.first!
                self.annotationView.update(imageSize: CGSize(width: imageRep.pixelsWide, height: imageRep.pixelsHigh), boundingBoxes: annotationInfo.boundingBoxes)
                self.annotationView.isHidden = false
            } else {
                self.imageView.image = nil
                self.annotationView.isHidden = true
            }
            self.view.needsLayout = true
        }
        get {
            return _annotationInfo
        }
    }
    
    private var _annotationInfo: ImageAnnotationInfo?
    
    var annotationInfoChangedHandler: ((ImageAnnotationInfo) -> Void)?
    
    @IBOutlet private weak var imageView: NSImageView!
    
    private weak var annotationView: AnnotationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let annotationView = AnnotationView(frame: .zero)
        self.view.addSubview(annotationView)
        self.annotationView = annotationView
        self.annotationView.boundingBoxesChangedHandler = {[unowned self] boxes in
            self._annotationInfo?.boundingBoxes = boxes
            if let annotationInfo = self._annotationInfo {
                self.annotationInfoChangedHandler?(annotationInfo)
            }
        }
        self.annotationView.isHidden = true
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        self.annotationView.frame = AVMakeRect(aspectRatio: self.imageView.image?.size ?? self.imageView.bounds.size, insideRect: self.imageView.bounds)
    }
}
