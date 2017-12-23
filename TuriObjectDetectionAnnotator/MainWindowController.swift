//
//  MainWindowController.swift
//  TuriObjectDetectionAnnotator
//
//  Created by Yu Ao on 23/12/2017.
//  Copyright © 2017 yuao. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    private var splitViewController: NSSplitViewController!
    private var imageListViewController: ImageListViewController!
    private var imageAnnotationViewController: ImageAnnotationViewController!
 
    private var annotations: Annotations = Annotations()
    private var annotationsURL: URL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.annotationsURL = nil
        self.splitViewController = self.contentViewController as! NSSplitViewController
        self.imageListViewController = self.splitViewController.splitViewItems.first?.viewController as! ImageListViewController
        self.imageAnnotationViewController = self.splitViewController.splitViewItems.last?.viewController as! ImageAnnotationViewController
        self.imageListViewController.imageSelectionHandler = { [unowned self] url in
            if let annotationInfo = self.imageAnnotationViewController.annotationInfo {
                self.annotations.contents[annotationInfo.imageURL.lastPathComponent] = annotationInfo.boundingBoxes
                self.saveDocument(nil)
            }
            if let url = url {
                let boundingBoxes = self.annotations.contents[url.lastPathComponent]
                self.imageAnnotationViewController.annotationInfo = ImageAnnotationInfo(imageURL: url, boundingBoxes: boundingBoxes ?? [])
            } else {
                self.imageAnnotationViewController.annotationInfo = nil
            }
        }
        self.imageAnnotationViewController.annotationInfoChangedHandler = { [unowned self] info in
            self.annotations.contents[info.imageURL.lastPathComponent] = info.boundingBoxes
            self.saveDocumentAfterDelay()
        }
    }

    private var saveTimer: Timer?
    private func saveDocumentAfterDelay() {
        self.saveTimer?.invalidate()
        self.saveTimer = nil
        self.saveTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { [unowned self] timer in
            self.saveDocument(nil)
        })
    }
    
    @IBAction func annotatePreviousImage(_ sender: Any) {
        self.imageListViewController.previous()
    }
    
    @IBAction func annotateNextImage(_ sender: Any) {
        self.imageListViewController.next()
    }
    
    @IBAction func openWorkingDirectoryInFinder(_ sender: Any) {
        if let url = self.annotationsURL?.deletingLastPathComponent() {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func saveDocument(_ sender: Any?) {
        if let annotationsURL = self.annotationsURL {
            do {
                try self.annotations.write(to: annotationsURL)
                print("annotations saved...")
            } catch {
                NSAlert(error: error).beginSheetModal(for: self.window!, completionHandler: nil)
            }
        }
    }
    
    @IBAction func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: self.window!) { [unowned panel] response in
            if let url = panel.url {
                let annotationsURL = url.appendingPathComponent("annotations.json")
                self.annotations = Annotations(contentsOf: annotationsURL)
                self.annotationsURL = annotationsURL
                self.imageListViewController.url = url
            }
        }
    }
}
