//
//  MPTitleView.swift
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

final class MPTitleView: UIView {
    let VStack: UIStackView = {
        let view = UIStackView()
        view.distribution = .fill
        view.axis = .vertical
        view.alignment = .center
        return view
    }()
    
    private let HStack: UIStackView = {
       let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = 4
        return view
    }()
    
    private let titleLabel: UILabel = {
       let view = UILabel()
        view.font = .systemFont(ofSize: 17, weight: .medium)
        view.textColor = .label
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return view
    }()
    
    private let arrowView: UIImageView = {
      let view = UIImageView()
        view.image = UIImage(systemName: "chevron.down.circle.fill")?.mp.template
        view.tintColor = .label
        return view
    }()
    
    private let container: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return view
    }()
    
    private let fillColor = UIColor.label
    private let highlightColor = UIColor.label.withAlphaComponent(0.5)
    
    var isEnabled: Bool = true {
        didSet {
            container.isHidden = !isEnabled
        }
    }
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    var isCenterAlignment: Bool = false {
        didSet {
            VStack.alignment = isCenterAlignment ? .center : .leading
        }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //VStack.frame = bounds
        //arrowView.frame = container.bounds
    }
    
    private func setup() {
        setupSubviews()
        setupLayout()
    }
    
    private func setupSubviews() {
        container.addSubview(arrowView)
        HStack.mp.addArrangedSubviews(titleLabel, container)
        VStack.addArrangedSubview(HStack)
        addSubview(VStack)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            VStack.leftAnchor.constraint(equalTo: self.leftAnchor),
            VStack.rightAnchor.constraint(equalTo: self.rightAnchor),
            VStack.topAnchor.constraint(equalTo: self.topAnchor),
            VStack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 16),
            container.heightAnchor.constraint(equalToConstant: 16),
            arrowView.leftAnchor.constraint(equalTo: container.leftAnchor),
            arrowView.rightAnchor.constraint(equalTo: container.rightAnchor),
            arrowView.topAnchor.constraint(equalTo: container.topAnchor),
            arrowView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    func rotateArrow(isShow: Bool) {
        UIView.animate(withDuration: 0.3,
                       animations: { [weak self] in
            guard let strongSelf = self else { return }
            if isShow {
                strongSelf.arrowView.transform = CGAffineTransform.identity.rotated(by: 180 * CGFloat(Double.pi))
                strongSelf.arrowView.transform = CGAffineTransform.identity.rotated(by: -1 * CGFloat(Double.pi))
            } else {
                strongSelf.arrowView.transform = CGAffineTransform.identity
            }
        })
    }
    
    func toggleHighlightState(_ isHighlight: Bool) {
        titleLabel.textColor = isHighlight ? highlightColor : fillColor
        arrowView.tintColor = isHighlight ? highlightColor : fillColor
    }
}

