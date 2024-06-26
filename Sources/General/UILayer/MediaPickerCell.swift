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

final class ObsImageView: UIImageView {
    var changeIsHidden: ((Bool) -> ())? = nil
    
    override var isHidden: Bool {
        get {
            super.isHidden
        }
        set {
            changeIsHidden?(newValue)
            super.isHidden = newValue
        }
    }
}

final class MediaPickerCell: CollectionViewCell {
    
    private let selectBtnWH: CGFloat = 24
    
    private lazy var bottomShadowView: ViewGradient = {
        let view = ViewGradient()
        view.startColor = .clear
        view.endColor = .black.withAlphaComponent(0.4)
        return view
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = Font.regular(13)
        label.textAlignment = .right
        label.textColor = .white
        return label
    }()
    
    private var imageIdentifier = ""
    
    private var smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    private var bigImageReqeustID: PHImageRequestID = PHInvalidImageRequestID
    
    private let imageView: ObsImageView = {
        let view = ObsImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let selectionButton: MPCheckboxButton = {
        let view = MPCheckboxButton(frame: .zero, uiConfig: .default())
        view.contentMode = .center
        view.contentVerticalAlignment = .center
        view.increasedInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        return view
    }()
    
    weak var delegate: MediaPickerCellDelegate?
    
    var referencedView: UIView {
        imageView
    }
    
    var referencedImage: UIImage? {
        imageView.image
    }
    
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
    
    var isOn = false {
        didSet {
            selectionButton.setIsOn(isOn)
        }
    }
    
    var uiConfig: MPUIConfiguration = .default() {
        didSet {
            selectionButton.uiConfig = uiConfig
        }
    }
    
    deinit {
        Logger.log("deinit MediaPickerCell")
    }
    
    override func setupSubviews() {
        contentView.addSubview(imageView)
        contentView.addSubview(selectionButton)
        contentView.addSubview(bottomShadowView)
        bottomShadowView.addSubview(descLabel)
        selectionButton.mp.action({ [weak self] in self?.selectionBlock() }, forEvent: .touchUpInside)
        imageView.changeIsHidden = { [weak self] (isHidden) in
            self?.handleTransitionForPreview(isHidden)
        }
    }
    
    override func adaptationLayout() {
        imageView.frame = bounds
        selectionButton.frame = .init(x: bounds.maxX - 8 - selectBtnWH, y: 8, width: selectBtnWH, height: selectBtnWH)
        bottomShadowView.frame = CGRect(x: 0, y: bounds.height - 25, width: bounds.width, height: 25)
        descLabel.frame = CGRect(x: 0, y: 4, width: bounds.width - 8, height: 17)
    }
    
    override func reuseBlock() {
        selectionButton.setIsOn(false, isAnimate: false)
    }
    
    private func configureCell() {
        if model.type == .video {
            bottomShadowView.isHidden = false
            descLabel.text = model.duration
        } else if model.type == .gif {
            bottomShadowView.isHidden = true
        } else if model.type == .livePhoto {
            bottomShadowView.isHidden = true
        } else {
            bottomShadowView.isHidden = true
        }
        
        selectionButton.setIsOn(model.isSelected, isAnimate: false)
        
        fetchSmallImage()
    }
    
    private func selectionBlock() {
        delegate?.onCheckboxTap(inCell: self)
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
        smallImageRequestID = MPManager.fetchImage(for: model.asset, size: size, completion: { image, isDegraded in
            if self.imageIdentifier == self.model.id {
                self.imageView.image = image
            }
            if !isDegraded {
                self.smallImageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    private func handleTransitionForPreview(_ isHidden: Bool) {
        selectionButton.mp.setIsHidden(isHidden, duration: 0.3)
    }
    
    override func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {
        switch dragState {
        case .none:
            contentView.alpha = 1
            selectionButton.alpha = 1
        case .lifting:
            selectionButton.alpha = 0
        case .dragging:
            if contentView.alpha == 1 {
                contentView.alpha = 0
            } else {
                contentView.alpha = 1
                selectionButton.alpha = 1
            }
        @unknown default:
            break
        }
    }
}

