//
//  MediaPickerCell.swift
//
//  Created by Валентин Панчишен on 05.04.2024.
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

final class MediaPickerCell: CollectionViewCell {
    
    private let selectBtnWH: CGFloat = 24
    
    private let containerView = UIView()
    
    private lazy var bottomShadowView: ViewGradient = {
        let view = ViewGradient()
        view.startColor = .clear
        view.endColor = .black.withAlphaComponent(0.4)
        return view
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .right
        label.textColor = .white
        return label
    }()
    
    private var imageIdentifier = ""
    
    private var smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    private var bigImageReqeustID: PHImageRequestID = PHInvalidImageRequestID
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    let selectionButton: MPCheckboxButton = {
        let view = MPCheckboxButton(frame: .zero)
        view.contentMode = .center
        view.contentVerticalAlignment = .center
        view.increasedInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        return view
    }()
    
    var model: MPPhotoModel! {
        didSet {
            configureCell()
        }
    }
    
    var index = 1 {
        didSet {
            selectionButton.counter = index
        }
    }
    
    override func setupSubviews() {
        contentView.addSubview(imageView)
        contentView.addSubview(containerView)
        containerView.addSubview(selectionButton)
        containerView.addSubview(bottomShadowView)
        bottomShadowView.addSubview(descLabel)
        selectionButton.mp.action(selectionBlock, forEvent: .touchUpInside)
    }
    
    override func setupLayout() {
        
    }
    
    override func adaptationLayout() {
        imageView.frame = bounds
        containerView.frame = bounds
        selectionButton.frame = .init(x: bounds.maxX - 8 - selectBtnWH, y: 8, width: selectBtnWH, height: selectBtnWH)
        bottomShadowView.frame = CGRect(x: 0, y: bounds.height - 25, width: bounds.width, height: 25)
        descLabel.frame = CGRect(x: 0, y: 4, width: bounds.width - 8, height: 17)
    }
    
    override func reuseBlock() {
        
    }
    
    private func configureCell() {
        let generalConfig = MPGeneralConfiguration.default()
        
        if model.type == .video {
            bottomShadowView.isHidden = false
            descLabel.text = model.duration
        } else if model.type == .gif {
            bottomShadowView.isHidden = false
            descLabel.text = "GIF"
        } else if model.type == .livePhoto {
            bottomShadowView.isHidden = false
            descLabel.text = "Live"
        } else {
            bottomShadowView.isHidden = true
        }
        
        selectionButton.isOn = model.isSelected
        
        if model.isSelected {
            fetchBigImage()
        } else {
            cancelFetchBigImage()
        }
        
        fetchSmallImage()
    }
    
    private func selectionBlock() {
        selectionButton.isOn.toggle()
    }
    
    private func fetchSmallImage() {
        let size: CGSize
        let maxSideLength = bounds.width * 2
        if model.ratio > 1 {
            let w = maxSideLength * model.ratio
            size = CGSize(width: w, height: maxSideLength)
        } else {
            let h = maxSideLength / model.ratio
            size = CGSize(width: maxSideLength, height: h)
        }
        
        if smallImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(smallImageRequestID)
        }
        
        imageIdentifier = model.id
        imageView.image = nil
        smallImageRequestID = MPManager.fetchImage(for: model.asset, size: size, completion: { [weak self] image, isDegraded in
            if self?.imageIdentifier == self?.model.id {
                self?.imageView.image = image
            }
            if !isDegraded {
                self?.smallImageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    private func fetchBigImage() {
        cancelFetchBigImage()
        
        bigImageReqeustID = MPManager.fetchOriginalImageData(for: model.asset, progress: { [weak self] progress, _, _, _ in
            if self?.model.isSelected == true {
                //self?.progressView.isHidden = false
                //self?.progressView.progress = max(0.1, progress)
                self?.imageView.alpha = 0.5
                if progress >= 1 {
                    //self?.resetProgressViewStatus()
                }
            } else {
                self?.cancelFetchBigImage()
            }
        }, completion: { [weak self] _, _, _ in
            //self?.resetProgressViewStatus()
        })
    }
    
    private func cancelFetchBigImage() {
        if bigImageReqeustID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(bigImageReqeustID)
        }
        //resetProgressViewStatus()
    }
}

