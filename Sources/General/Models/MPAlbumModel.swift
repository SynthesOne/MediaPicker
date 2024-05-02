//
//  MPAlbumModel.swift
//
//  Created by Валентин Панчишен on 09.04.2024.
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

public struct MPAlbumModel {
    public let title: String
    
    public var count: Int {
        return result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool
    
    public var headImageAsset: PHAsset? {
        return result.lastObject
    }
    
    public var models: [MPPhotoModel] = []
    
    private let generalConfig: MPGeneralConfiguration
    
    public init(
        title: String,
        result: PHFetchResult<PHAsset>,
        collection: PHAssetCollection,
        option: PHFetchOptions,
        isCameraRoll: Bool,
        generalConfig: MPGeneralConfiguration
    ) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
        self.generalConfig = generalConfig
    }
    
    public mutating func refetchPhotos() {
        let models = MPManager.fetchPhoto(
            in: result,
            allowImage: generalConfig.allowImage,
            allowVideo: generalConfig.allowVideo
        )
        self.models = []
        self.models.append(contentsOf: models)
    }
    
    mutating func refreshResult() {
        result = PHAsset.fetchAssets(in: collection, options: option)
    }
}

extension MPAlbumModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(count)
        hasher.combine(headImageAsset?.localIdentifier)
    }
    
    public static func ==(lhs: MPAlbumModel, rhs: MPAlbumModel) -> Bool {
        return lhs.title == rhs.title &&
            lhs.count == rhs.count &&
            lhs.headImageAsset?.localIdentifier == rhs.headImageAsset?.localIdentifier
    }
}

extension MPAlbumModel {
    enum Section: Hashable {
        case main
    }
}
