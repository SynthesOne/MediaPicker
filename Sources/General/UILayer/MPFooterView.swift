//
//  MPFooterView.swift
//
//  Created by Валентин Панчишен on 11.04.2024.
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

final class FillButton: UIButton {
    var highlightColor: UIColor? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    var fillColor: UIColor? = nil {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightColor : fillColor
        }
    }
}

final class MPFooterView: UIView {
    private lazy var toolTipDescription: UILabel = {
       let view = UILabel()
        view.textAlignment = .left
        view.textColor = .secondaryLabel
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.text = Lang.limitedAccessTip
        view.lineBreakMode = .byWordWrapping
        view.numberOfLines = 0
        return view
    }()
    
    private lazy var toolTipButton: FillButton = {
        let view = FillButton(type: .custom)
        view.setTitle(Lang.toolTipControl, for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        let uiConfig = MPUIConfiguration.default()
        view.backgroundColor = uiConfig.navigationAppearance.tintColor
        view.fillColor = uiConfig.navigationAppearance.tintColor
        view.highlightColor = uiConfig.navigationAppearance.tintColor.mp.darker()
        view.contentVerticalAlignment = .center
        view.contentHorizontalAlignment = .center
        return view
    }()
    
    private let counter: Counter = {
       let view = Counter()
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private let actionButton: FillButton = {
        let view = FillButton(type: .custom)
        view.mp.setRadius(8)
        view.setTitleColor(.white, for: .normal)
        view.setTitle(Lang.cancelButton, for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        view.backgroundColor = .systemGray
        view.fillColor = .systemGray
        view.highlightColor = .systemGray.mp.darker()
        return view
    }()
    
    private let blurContainer: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: MPUIConfiguration.default().navigationAppearance.backgroundEffectStyle)
        let view = UIVisualEffectView(effect: blurEffect)
        return view
    }()
    
    private let showAddToolTip: Bool
    
    var actionButtonTap: (() -> ())? = nil
    var toolTipButtonTap: (() -> ())? = nil
    
    init(showAddToolTip: Bool) {
        self.showAddToolTip = showAddToolTip
        super.init(frame: .zero)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        self.mp.addSubviews(blurContainer, actionButton)
        if showAddToolTip {
            self.mp.addSubviews(toolTipDescription, toolTipButton)
            toolTipButton.mp.action({ [weak self] in self?.toolTipButtonTap?() }, forEvent: .touchUpInside)
        }
        actionButton.addSubview(counter)
        actionButton.mp.action({ [weak self] in self?.actionButtonTap?() }, forEvent: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurContainer.frame = bounds
        let sideInset = safeAreaInsets.left > 0 ? safeAreaInsets.left : 16
        if showAddToolTip {
            let (buttonWidth, buttonHeight, textWidth, textHeight) = simulateToolTipSizes(sideInset: sideInset)
            toolTipButton.mp.setRadius(buttonHeight / 2)
            toolTipButton.frame = .init(x: bounds.maxX - buttonWidth - sideInset, y: 12, width: buttonWidth, height: buttonHeight)
            toolTipDescription.frame = .init(x: sideInset, y: 12, width: textWidth, height: textHeight)
            let finalHeight = buttonHeight > textHeight ? buttonHeight : textHeight
            actionButton.frame = .init(x: sideInset, y: 24 + finalHeight, width: bounds.width - sideInset * 2, height: 44)
        } else {
            actionButton.frame = .init(x: sideInset, y: 8, width: bounds.width - sideInset * 2, height: 44)
        }
        updateCounterPosition()
    }
    
    override var intrinsicContentSize: CGSize {
        if showAddToolTip {
            let sideInset = safeAreaInsets.left > 0 ? safeAreaInsets.left : 16
            let (_, buttonHeight, _, textHeight) = simulateToolTipSizes(sideInset: sideInset)
            // We round to get an integer height, otherwise the view won't go all the way to the bottom
            let finalHeight = (buttonHeight > textHeight ? buttonHeight : textHeight).rounded(.up)
            return .init(width: super.intrinsicContentSize.width, height: finalHeight + 24 + 44)
        } else {
            return .init(width: super.intrinsicContentSize.width, height: 52)
        }
    }
    
    private func simulateToolTipSizes(sideInset: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let buttonWidth = (toolTipButton.titleLabel?.mp.textWidth() ?? 0.0) + 16
        let buttonHeight = (toolTipButton.titleLabel?.mp.textHeight(width: buttonWidth) ?? 0.0) + 8
        let textWidth = bounds.width - (buttonWidth + sideInset * 2 + 8)
        let textHeight = toolTipDescription.mp.textHeight(width: textWidth)
        
        return (buttonWidth, buttonHeight, textWidth, textHeight)
    }
    
    private func updateButtonActionButtond(hasCount: Bool) {
        if hasCount {
            actionButton.setTitle(Lang.attach, for: .normal)
            actionButton.backgroundColor = MPUIConfiguration.default().navigationAppearance.tintColor
            actionButton.fillColor = MPUIConfiguration.default().navigationAppearance.tintColor
            actionButton.highlightColor = MPUIConfiguration.default().navigationAppearance.tintColor.mp.darker()
        } else {
            actionButton.setTitle(Lang.cancelButton, for: .normal)
            actionButton.backgroundColor = .systemGray
            actionButton.fillColor = .systemGray
            actionButton.highlightColor = .systemGray.mp.darker()
        }
    }
    
    private func updateCounterPosition() {
        let sizeW = counter.textWidth() + 12
        let sizH = sizeW > 21 ? 21 : sizeW
        counter.mp.setRadius(sizH / 2)
        counter.frame = .init(x: (actionButton.titleLabel?.frame.maxX ?? 0) + 8, y: (44 / 2) - (sizH / 2), width: sizeW, height: sizH)
    }
    
    private func showCounterAnimation(completion: (() -> ())? = nil) {
        updateButtonActionButtond(hasCount: true)
        counter.alpha = 0
        counter.isHidden = false
        counter.transform = .init(scaleX: 0.01, y: 0.01)
        
        UIView.animate(withDuration: 0.18, animations: {
            self.counter.alpha = 1.0
            self.counter.transform = .identity
            self.updateCounterPosition()
        }) { (_) in
            completion?()
        }
    }
    
    private func hideCounterAnimation() {
        updateButtonActionButtond(hasCount: false)
        // It is necessary to remove animations to avoid glitch with bounce animation
        counter.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.18, animations: {
            self.counter.alpha = 0.0
            self.counter.transform = .init(scaleX: 0.01, y: 0.01)
        }, completion: { (_) in
            self.counter.isHidden = true
            self.counter.alpha = 1.0
            self.counter.transform = .identity
        })
    }
    
    func setCounter(_ counter: Int) {
        actionButton.setTitle(counter <= 0 ? Lang.cancelButton : Lang.attach, for: .normal)
        if counter == 1 && self.counter.isHidden {
            showCounterAnimation()
            self.counter.setCounter(counter)
            layoutSubviews()
        } else if counter <= 0 && !self.counter.isHidden {
            hideCounterAnimation()
        } else {
            self.counter.setCounter(counter)
            layoutSubviews()
        }
    }
}
