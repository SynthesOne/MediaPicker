//
//  MPImageOperation.swift
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

final class MPFetchImageOperation: Operation {
    private let model: MPPhotoModel
    
    private let progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)?
    
    private let completion: (UIImage?, PHAsset?) -> Void
    
    private var preIsExecuting = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return preIsExecuting
    }
    
    private var preIsFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return preIsFinished
    }
    
    private var preIsCancelled = false {
        willSet {
            willChangeValue(forKey: "isCancelled")
        }
        didSet {
            didChangeValue(forKey: "isCancelled")
        }
    }
    
    private var requestImageID = PHInvalidImageRequestID
    
    override var isCancelled: Bool {
        return preIsCancelled
    }
    
    init(
        model: MPPhotoModel,
        progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
        completion: @escaping ((UIImage?, PHAsset?) -> Void)
    ) {
        self.model = model
        self.progress = progress
        self.completion = completion
        super.init()
    }
    
    override func start() {
        if isCancelled {
            fetchFinish()
            return
        }
        preIsExecuting = true
        
        if MPGeneralConfiguration.default().allowGif, model.type == .gif {
            requestImageID = MPManager.fetchOriginalImageData(for: model.asset) { [weak self] data, _, isDegraded in
                if !isDegraded {
                    let image = UIImage.mp.gif(data: data)
                    self?.completion(image, nil)
                    self?.fetchFinish()
                }
            }
            return
        }
        
//        if isOriginal {
            requestImageID = MPManager.fetchOriginalImage(for: model.asset, progress: progress) { [weak self] image, isDegraded in
                if !isDegraded {
                    self?.completion(image?.mp.upOrientationImage(), nil)
                    self?.fetchFinish()
                }
            }
//        } else {
//            requestImageID = MPManager.fetchImage(for: model.asset, size: model.previewSize, progress: progress) { [weak self] image, isDegraded in
//                if !isDegraded {
//                    self?.completion(self?.scaleImage(image?.mp.upOrientationImage()), nil)
//                    self?.fetchFinish()
//                }
//            }
//        }
    }
    
    override func cancel() {
        super.cancel()
        PHImageManager.default().cancelImageRequest(requestImageID)
        preIsCancelled = true
        if isExecuting {
            fetchFinish()
        }
    }
    
    private func scaleImage(_ image: UIImage?) -> UIImage? {
        guard let i = image else {
            return nil
        }
        guard let data = i.jpegData(compressionQuality: 1) else {
            return i
        }
        let mUnit: CGFloat = 1024 * 1024
        
        if data.count < Int(0.2 * mUnit) {
            return i
        }
        let scale: CGFloat = (data.count > Int(mUnit) ? 0.6 : 0.8)
        
        guard let d = i.jpegData(compressionQuality: scale) else {
            return i
        }
        return UIImage(data: d)
    }
    
    private func fetchFinish() {
        preIsExecuting = false
        preIsFinished = true
    }
}
