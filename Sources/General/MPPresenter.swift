//
//  MPPresenter.swift
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

public final class MPPresenter: NSObject {
    private weak var sender: UIViewController?
    private var preSelectedResults: [MPPhotoModel]
    private var selectedResult: (([MPResultModel]) -> ())? = nil
    private var preSelectedResult: (([MPPhotoModel]) -> ())? = nil
    private var config: MPConfigurationMakerExtendable = MPConfigurationMaker()
    //private var uiConfig: MPUIConfiguration = .default()
    //private var generalConfig: MPGeneralConfiguration = .default()
    
    private let fetchImageQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    
    public init(sender: UIViewController?, preSelectedResults: [MPPhotoModel] = []) {
        self.sender = sender
        self.preSelectedResults = preSelectedResults
        super.init()
        fetchSelectedResult()
    }
    
    deinit {
        Logger.log("deinit MPPresenter")
    }
    
    public func showMediaPicker(
        configuration: ((MPConfigurationMakerExtendable) -> (MPConfigurationMakerExtendable))? = nil,
        selectedResult: @escaping ([MPResultModel]) -> (),
        customPresentationStyle: ((UINavigationController) -> ())? = nil
    ) {
        self.selectedResult = selectedResult
        if let newConfig = configuration?(config) {
            config = newConfig
        }
        //uiConfiguration?(&uiConfig)
        //generalConfiguration?(&generalConfig)
        
        Lang.generalConfig = config.generalConfig
        
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            showNoAuthAlert()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: { (status) in
                MPMainAsync {
                    if status == .denied {
                        self.showNoAuthAlert()
                    } else if status == .authorized {
                        self.showLibraryMP(customPresentationStyle: customPresentationStyle)
                    }
                }
            })
        } else {
            showLibraryMP(customPresentationStyle: customPresentationStyle)
        }
        
    }
    
    private func showNoAuthAlert() {
        let alert = Alert(message: Lang.notAuthPhotos, {
            Action.cancel(Lang.ok)
        })
        
        if isIpad {
            alert.popoverPresentationController?.sourceView = sender?.view
        }
        
        sender?.present(alert, animated: true)
    }
    
    private func showLibraryMP(customPresentationStyle: ((MPNavigationViewController) -> ())? = nil) {
        MPManager.getCameraRollAlbum(generalConfig: config.generalConfig, limitCount: 20, completion: { (album) in
            let gallery = MPViewController(albumModel: album, selectedResults: self.preSelectedResults, uiConfig: self.config.uiConfig, generalConfig: self.config.generalConfig)
            gallery.preSelectedResult = self.preSelectedResult
            let navWrapper = MPNavigationViewController(rootViewController: gallery, uiConfig: self.config.uiConfig)
            
            if let customPresentationStyle {
                customPresentationStyle(navWrapper)
            } else {
                let sheet = navWrapper.sheetPresentationController
                sheet?.detents = [.medium(), .large()]
                sheet?.selectedDetentIdentifier = .medium
            }
            
            self.sender?.present(navWrapper, animated: true)
        })
    }
    
    private func fetchSelectedResult() {
        preSelectedResult = { [weak self] (selectedModels) in
            guard let strongSelf = self, !selectedModels.isEmpty else {
                self?.sender?.presentedViewController?.dismiss(animated: true)
                return
            }
            let callback = { (models: [MPResultModel], errorAssets: [PHAsset], errorIndexs: [Int]) in
                func call() {
                    self?.selectedResult?(models)
                }
                
                self?.sender?.presentedViewController?.dismiss(animated: true) {
                    call()
                }
            }
            
            var results: [MPResultModel?] = Array(repeating: nil, count: selectedModels.count)
            var errorAssets: [PHAsset] = []
            var errorIndexs: [Int] = []
            
            var sucCount = 0
            let totalCount = selectedModels.count
            
            for (i, m) in selectedModels.enumerated() {
                let operation = MPFetchImageOperation(model: m, generalConfig: strongSelf.config.generalConfig) { (image) in
                    sucCount += 1
                    
                    if let image {
                        let model = MPResultModel(m, image: image, index: i)
                        results[i] = model
                    } else {
                        errorAssets.append(m.asset)
                        errorIndexs.append(i)
                    }
                    
                    guard sucCount >= totalCount else { return }
                    
                    callback(
                        results.compactMap { $0 },
                        errorAssets,
                        errorIndexs
                    )
                }
                strongSelf.fetchImageQueue.addOperation(operation)
            }
        }
    }
    
}
