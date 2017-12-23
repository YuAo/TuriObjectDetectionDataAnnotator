//
//  ImageAnnotation.swift
//  TuriObjectDetectionAnnotator
//
//  Created by Yu Ao on 23/12/2017.
//  Copyright © 2017 yuao. All rights reserved.
//

import Foundation

struct Coordinates: Codable {
    var height: Int = 0
    var width: Int = 0
    var x: Int = 0
    var y: Int = 0
}

struct BoundingBox: Codable {
    var coordinates: Coordinates = Coordinates()
    var label: String = ""
}

struct ImageAnnotationInfo: Codable {
    var imageURL: URL
    var boundingBoxes: [BoundingBox] = []
}

struct Annotations: Codable {
    var contents: [String: [BoundingBox]]
    
    init() {
        self.contents = [:]
    }
    
    init(contentsOf url: URL) {
        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            let contents = try? decoder.decode([String: [BoundingBox]].self, from: data)
            self.contents = contents ?? [:]
        } else {
            self.contents = [:]
        }
    }
    
    func write(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self.contents)
        try data.write(to: url)
    }
}
