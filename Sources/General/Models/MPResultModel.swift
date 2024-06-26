//
//  MPResultModel.swift
//
//  Created by Валентин Панчишен on 15.04.2024.
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

public struct MPResultModel {
    public enum ImageExtType: String {
        case png, jpg, gif, heic
    }
    
    public let asset: PHAsset
    
    public let image: UIImage
    
    /// The order in which the user selects the models in the album. This index is not necessarily equal to the order of the model's index in the array, as some PHAssets requests may fail.
    public let index: Int
    
    public let type: MPPhotoModel.MediaType
    
    public let size: Int?
    
    public var fullFileName: String? {
        asset.mp.fileName
    }
    
    public var fileName: String? {
        fullFileName?.fileName()
    }
    
    public var fileExtension: String? {
        fullFileName?.fileExtension()
    }
    
    public var mimeType: String {
        getMimeType(for: fileExtension)
    }
    
    /// Save asset original data to file url. Support save image and video.
    /// - Note: Asynchronously write to a local file. Calls completionHandler block on the main queue. If the asset object is in iCloud, it will be downloaded first and then written in the method.
    public func saveAsset(toFile fileUrl: URL, completion: @escaping ((Error?) -> Void)) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestExportSession(
            forVideo: asset,
            options: options,
            exportPreset: AVAssetExportPresetPassthrough,
            resultHandler: { (session, info) in
                let error = info?[PHImageErrorKey] as? Error
                if let session {
                    session.outputURL = fileUrl
                    session.outputFileType = .mp4
                    session.exportAsynchronously {
                        completion(error)
                    }
                } else {
                    completion(error)
                }
            }
        )
    }
    
    private func getMimeType(for mediaExtension: String?) -> String {
        guard let mediaExtension,
              let type = UTType(filenameExtension: mediaExtension),
              let mimeType = type.preferredMIMEType else {
            return "application/octet-stream"
        }
        
        return mimeType as String
    }
}

extension MPResultModel {
    init(_ model: MPPhotoModel, image: UIImage, index: Int) {
        asset = model.asset
        type = model.type
        size = MPManager.fetchAssetSize(forAsset: model.asset)
        self.image = image
        self.index = index
    }
}

extension MPResultModel: Equatable {
    public static func ==(lhs: MPResultModel, rhs: MPResultModel) -> Bool {
        return lhs.asset == rhs.asset
    }
}
