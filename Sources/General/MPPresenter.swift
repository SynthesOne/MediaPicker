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
    public weak var sender: UIViewController?
    private let selectedResults: [MPPhotoModel]
    
    public init(sender: UIViewController? = nil, selectedResults: [MPPhotoModel] = []) {
        self.sender = sender
        self.selectedResults = selectedResults
        super.init()
    }
    
    public func showMediaPicker() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            showNoAuthAlert()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: { [weak self] (status) in
                MPMainAsync {
                    if status == .denied {
                        self?.showNoAuthAlert()
                    } else if status == .authorized {
                        self?.showLibraryMP()
                    }
                }
            })
        } else {
            showLibraryMP()
        }
        
    }
    
    private func showNoAuthAlert() {
        let alert = Alert(message: "Enable access to upload photos and attach them", {
            Action.cancel("ok")
        })
        
        sender?.present(alert, animated: true)
    }
    
    private func showLibraryMP() {
        MPManager.getCameraRollAlbum(allowSelectImage: true, allowSelectVideo: true, completion: { [weak self] (album) in
            let gallery = MPViewController(albumModel: album)
            
            let sheet = gallery.sheetPresentationController
            sheet?.detents = [.medium(), .large()]
            
            self?.sender?.present(gallery, animated: true)
        })
    }
    
}
