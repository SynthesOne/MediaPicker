//
//  MPPhotoModel.swift
//
//  Created by Валентин Панчишен on 08.04.2024.
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

public struct MPPhotoModel {
    public let id: String
    public let asset: PHAsset
    public var type: MPPhotoModel.MediaType = .unknown
    public var duration = ""
    public var isSelected = false
    
    private var pre_dataSize: CGFloat?
    public mutating func dataSize() -> CGFloat? {
        if let pre_dataSize {
            return pre_dataSize
        }
        
        let size = MPManager.fetchAssetSize(forAsset: asset)
        pre_dataSize = size
        
        return size
    }
    
    public var seconds: Int {
        guard type == .video else { return 0 }
        return Int(round(asset.duration))
    }
    
    public var ratio: CGFloat {
        CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
    }
    
    public var previewSize: CGSize {
        if ratio > 1 {
            let h = min(UIScreenHeight, MaxImageWidth) * UIScreenScale
            let w = h * ratio
            return .init(width: w, height: h)
        } else {
            let w = min(UIScreenWidth, MaxImageWidth) * UIScreenScale
            let h = w / ratio
            return .init(width: w, height: h)
        }
    }
    
    public init(asset: PHAsset) {
        id = asset.localIdentifier
        self.asset = asset
        
        type = transformAssetTypeToLocal(forAsset: asset)
        
        if type == .video {
            duration = transformDurationToString(forAsset: asset)
        }
    }
    
    public func transformAssetTypeToLocal(forAsset asset: PHAsset) -> MPPhotoModel.MediaType {
        switch asset.mediaType {
        case .image:
            if asset.mp.isGif {
                return .gif
            }
            
            if asset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }
            
            return .image
        case .video:
            return .video
        default:
            return .unknown
        }
    }
    
    public func transformDurationToString(forAsset asset: PHAsset) -> String {
        let dur = Int(round(asset.duration))
        
        switch dur {
        case 0..<60:
            return String(format: "00:%02d", dur)
        case 60..<3600:
            let m = dur / 60
            let s = dur % 60
            return String(format: "%02d:%02d", m, s)
        case 3600...:
            let h = dur / 3600
            let m = (dur % 3600) / 60
            let s = dur % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        default:
            return ""
        }
    }
}

extension MPPhotoModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func ==(lhs: MPPhotoModel, rhs: MPPhotoModel) -> Bool {
        lhs.id == rhs.id
    }
}

public extension MPPhotoModel {
    enum MediaType: Int {
        case unknown = 0
        case image
        case gif
        case livePhoto
        case video
    }
}

extension MPPhotoModel {
    enum Section: Hashable {
        case main
    }
}
