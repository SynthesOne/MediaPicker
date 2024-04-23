//
//  MPAlbumListCell.swift
//
//  Created by Валентин Панчишен on 10.04.2024.
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

final class MPAlbumListCell: CollectionViewCell {
    
    private let albumPreviewSize: CGFloat = 24
    
    private let vStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 2
        return view
    }()
    
    private let hStack: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        view.spacing = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let albumName: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .label
        return view
    }()
    
    private let countLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 13, weight: .regular)
        view.textColor = .secondaryLabel
        return view
    }()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.mp.setRadius(8)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var imageIdentifier: String?
    
    override func setupSubviews() {
        vStack.mp.addArrangedSubviews(albumName, countLabel)
        hStack.mp.addArrangedSubviews(vStack, imageView)
        contentView.addSubview(hStack)
    }
    
    override func adaptationLayout() {
        NSLayoutConstraint.activate([
            hStack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            imageView.widthAnchor.constraint(equalToConstant: albumPreviewSize),
            imageView.heightAnchor.constraint(equalToConstant: albumPreviewSize)
        ])
    }
    
    func configureCell(model: MPAlbumModel) {
        
        albumName.text = model.title
        countLabel.text = "\(model.count)"
        
        
        imageIdentifier = model.headImageAsset?.localIdentifier
        if let asset = model.headImageAsset {
            MPManager.fetchImage(for: asset, size: CGSize(width: albumPreviewSize, height: albumPreviewSize)) { image, _ in
                if self.imageIdentifier == model.headImageAsset?.localIdentifier {
                    self.imageView.image = image
                }
            }
        }
    }
    
    override func highlightedAnimation() {
        contentView.backgroundColor = isHighlighted ? UIColor.mp.selectedColor : .clear
    }
    
    override func selectedAnimation() {
        contentView.backgroundColor = isSelected ? UIColor.mp.selectedColor : .clear
    }
}

