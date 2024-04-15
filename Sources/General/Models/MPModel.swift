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

//
public struct MPModel {
    static var empty: MPModel {
        .init(items: [], offset: 0)
    }
    
    enum Item: Hashable {
        case media(MPPhotoModel)
        case addPhoto(String)
        case camera(String)
    }
    
    enum Section: Hashable {
        case cameraRoll, main
    }
    
    var items: [Item]
    private var offset: Int
    
    //private func extractedMedia() -> [MPPhotoModel] {
    //    items.compactMap({ $0.unwrapped })
    //}
    
    private func getIndexWithOffset(_ indexPath: IndexPath, showCameraCell: Bool) -> Int {
        let indexItem: Int
        if showCameraCell {
            if indexPath.section == 0 {
                indexItem = indexPath.item
            } else {
                indexItem = indexPath.item + 5
            }
        } else {
            indexItem = indexPath.item
        }
        return indexItem
    }
    
    func item(_ indexPath: IndexPath, showCameraCell: Bool) -> MPPhotoModel {
        let indexItem = getIndexWithOffset(indexPath, showCameraCell: showCameraCell)
        //let index = indexItem - offset
        return items[indexItem].unwrapped!// extractedMedia()[index]
    }
    
    func firstSelectedIndex(showCameraCell: Bool) -> IndexPath? {
        if showCameraCell {
            if let indexWithOffset = items.firstIndex(where: { ($0.unwrapped?.isSelected ?? false) }) {
                var trueIndex = indexWithOffset// + offset
                let section: Int
                if trueIndex > 4 {
                    section = 1
                    trueIndex -= 5
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
        items.insert(.media(model), at: offset)
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
                i += 1
            } else {
                i += 1
            }
        }
    }
}

extension MPModel {
    init(assets: [PHAsset], showAddPhoto: Bool, showCameraCell: Bool) {
        items = []
        offset = 0
        if showCameraCell {
            items.append(.camera(cameraIdent))
            offset += 1
        }
        
        if showAddPhoto {
            items.append(.addPhoto(addPhotoIdent))
            offset += 1
        }
        
        items.append(contentsOf: assets.map { Item.media(.init(asset: $0)) })
    }
    
    init(models: [MPPhotoModel], showAddPhoto: Bool, showCameraCell: Bool) {
        items = []
        offset = 0
        if showCameraCell {
            items.append(.camera(cameraIdent))
            offset += 1
        }
        
        if showAddPhoto {
            items.append(.addPhoto(addPhotoIdent))
            offset += 1
        }
        
        items.append(contentsOf: models.map { Item.media($0) })
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
