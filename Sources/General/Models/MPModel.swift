//
//  MPModel.swift
//
//  Created by Валентин Панчишен on 12.04.2024.
//  Copyright © 2024 Валентин Панчишен. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    
import UIKit
import Photos

fileprivate let cameraIdent = "camera_ident"
fileprivate let addPhotoIdent = "add_photo_ident"

public struct MPModel {
    static var empty: MPModel {
        .init(items: [], offset: 0)
    }
    
    enum Item: Hashable {
        case media(MPPhotoModel)
        case camera(String)
    }
    
    enum Section: Hashable {
        case cameraRoll, main
    }
    
    var items: [Item]
    private var offset: Int
    private var currentOrientationIsLandscape: Bool = false
    
    func extractedMedia(forSelectedIndexPath indexPath: IndexPath, showCameraCell: Bool) -> ([MPPhotoModel], Int) {
        let index = getIndexWithOffset(indexPath, showCameraCell: showCameraCell) - offset
        return (items.compactMap({ $0.unwrapped }), index)
    }
    
    func getIndexPath(forMedia model: MPPhotoModel) -> IndexPath? {
        if let index = items.firstIndex(where: { $0.unwrapped == model }) {
            var itemsOffset = 5
            if currentOrientationIsLandscape {
                itemsOffset += 4
            }
            if index > itemsOffset - 1 {
                return IndexPath(item: index - itemsOffset, section: 1)
            } else {
                return IndexPath(item: index, section: 0)
            }
        }
        return nil
    }
    
    private func getIndexWithOffset(_ indexPath: IndexPath, showCameraCell: Bool) -> Int {
        let indexItem: Int
        if showCameraCell {
            var itemsOffset = 5
            if currentOrientationIsLandscape {
                itemsOffset += 4
            }
            if indexPath.section == 0 {
                indexItem = indexPath.item
            } else {
                indexItem = indexPath.item + itemsOffset
            }
        } else {
            indexItem = indexPath.item
        }
        return indexItem
    }
    
    func item(_ indexPath: IndexPath, showCameraCell: Bool) -> MPPhotoModel {
        let indexItem = getIndexWithOffset(indexPath, showCameraCell: showCameraCell)
        return items[indexItem].unwrapped!
    }
    
    func firstSelectedIndex(showCameraCell: Bool) -> IndexPath? {
        if showCameraCell {
            var itemsOffset = 5
            if currentOrientationIsLandscape {
                itemsOffset += 4
            }
            if let indexWithOffset = items.firstIndex(where: { ($0.unwrapped?.isSelected ?? false) }) {
                var trueIndex = indexWithOffset
                let section: Int
                if trueIndex > itemsOffset - 1 {
                    section = 1
                    trueIndex -= itemsOffset
                } else {
                    section = 0
                }
                return IndexPath(item: trueIndex, section: section)
            }
            return nil
        } else {
            if let indexWithOffset = items.firstIndex(where: { ($0.unwrapped?.isSelected ?? false) }) {
                return IndexPath(item: indexWithOffset, section: 0)
            }
            return nil
        }
    }
    
    @discardableResult
    mutating func toggleSelected(indexPath: IndexPath, showCameraCell: Bool, _ isSelected: Bool) -> MPPhotoModel? {
        let indexWithOffset = getIndexWithOffset(indexPath, showCameraCell: showCameraCell)
        items[indexWithOffset].unwrapped?.isSelected = isSelected
        return items[indexWithOffset].unwrapped
    }
    
    @discardableResult
    mutating func toggleSelected(indexWithoutOffset: Int, _ isSelected: Bool) -> MPPhotoModel? {
        let index = indexWithoutOffset + offset
        items[index].unwrapped?.isSelected = isSelected
        return items[index].unwrapped
    }
    
    @discardableResult
    mutating func insertNewModel(_ model: MPPhotoModel) -> Int{
        //items.insert(.media(model), at: offset)
        return offset
    }
    
    mutating func markAsSelected(selected: inout [MPPhotoModel]) {
        var selIds: [String: Bool] = [:]
        var selIdAndIndex: [String: Int] = [:]
        
        for (index, m) in selected.enumerated() {
            selIds[m.id] = true
            selIdAndIndex[m.id] = index
        }
        var i = 0
        items.forEach { item in
            if let model = item.unwrapped {
                if selIds[model.id] == true {
                    if let selectedSource = toggleSelected(indexWithoutOffset: i, true) {
                        selected[selIdAndIndex[model.id]!] = selectedSource
                    }
                } else {
                    toggleSelected(indexWithoutOffset: i, false)
                }
                //Increment only if the enum stores a PHAsset model
                i += 1
            }
        }
    }
    
    mutating func setOrinetation(isLandscape: Bool) {
        currentOrientationIsLandscape = isLandscape
    }
    
    mutating func unselectBy(_ item: MPPhotoModel) {
        if let index = items.firstIndex(where: { $0.unwrapped == item }) {
            items[index].unwrapped?.isSelected = false
        }
    }
}

extension MPModel {
    init(assets: [PHAsset], showCameraCell: Bool) {
        items = []
        offset = 0
        if showCameraCell {
            items.append(.camera(cameraIdent))
            offset += 1
        }
        
        items.append(contentsOf: assets.uniqued().map { Item.media(.init(asset: $0)) })
    }
    
    init(models: [MPPhotoModel], showCameraCell: Bool) {
        items = []
        offset = 0
        if showCameraCell {
            items.append(.camera(cameraIdent))
            offset += 1
        }
        
        items.append(contentsOf: models.uniqued().map { Item.media($0) })
    }
}

extension MPModel.Item {
    var unwrapped: MPPhotoModel? {
        get {
            if case let .media(model) = self {
                return model
            }
            return nil
        }
        
        set {
            if newValue != nil {
                self = .media(newValue!)
            }
        }
    }
}
