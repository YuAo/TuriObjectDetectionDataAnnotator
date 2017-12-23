//
//  ImageListViewController.swift
//  TuriObjectDetectionAnnotator
//
//  Created by Yu Ao on 23/12/2017.
//  Copyright © 2017 yuao. All rights reserved.
//
import Cocoa

class ImageListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    private var imageURLs: [URL] = []
    
    var url: URL? {
        didSet {
            if self.isViewLoaded {
                if let url = self.url {
                    let fileManager = FileManager()
                    if let urls = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).filter({
                        return ["jpg", "png", "jpeg"].contains($0.pathExtension)
                    }) {
                        self.imageURLs = urls
                    } else {
                        self.imageURLs = []
                    }
                } else {
                    self.imageURLs = []
                }
                self.tableView.reloadData()
            }
        }
    }

    @IBOutlet private weak var tableView: NSTableView!
    
    var imageSelectionHandler: ((URL?) -> Void)?
    
    func next() {
       self.offsetSelection(by: 1)
    }
    
    func previous() {
        self.offsetSelection(by: -1)
    }
    
    func offsetSelection(by offset: Int) {
        if self.imageURLs.count > 0 {
            if self.tableView.selectedRow >= 0 {
                var index = (self.tableView.selectedRow + offset) % self.imageURLs.count
                if index < 0 {
                    index += self.imageURLs.count
                }
                self.tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            } else {
                self.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.imageURLs.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell"), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = self.imageURLs[row].lastPathComponent
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.tableView.selectedRow >= 0 {
            self.imageSelectionHandler?(self.imageURLs[self.tableView.selectedRow])
        } else {
            self.imageSelectionHandler?(nil)
        }
    }
    
}
