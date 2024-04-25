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
        view.font = Font.regular(15)
        view.text = Lang.limitedAccessTip
        view.lineBreakMode = .byWordWrapping
        view.numberOfLines = 0
        return view
    }()
    
    private lazy var toolTipButton: FillButton = {
        let view = FillButton(type: .custom)
        view.setTitle(Lang.toolTipControl, for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.titleLabel?.font = Font.regular(15)
        let uiConfig = MPUIConfiguration.default()
        view.backgroundColor = uiConfig.navigationAppearance.tintColor
        view.fillColor = uiConfig.navigationAppearance.tintColor
        view.highlightColor = uiConfig.navigationAppearance.tintColor.mp.darker()
        view.contentVerticalAlignment = .center
        view.contentHorizontalAlignment = .center
        return view
    }()
    
    private lazy var toolTipSubstrate: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        view.mp.setRadius(14)
        return view
    }()
    
    private let counter: Counter = {
        let view = Counter()
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private let cancelButton: FillButton = {
        let view = FillButton(type: .custom)
        let uiConfig = MPUIConfiguration.default()
        view.mp.setRadius(12)
        view.setTitleColor(uiConfig.navigationAppearance.tintColor, for: .normal)
        view.setTitle(Lang.cancelButton, for: .normal)
        view.titleLabel?.font = Font.regular(17)
        view.backgroundColor = uiConfig.navigationAppearance.tintColor.withAlphaComponent(0.25)
        view.fillColor = uiConfig.navigationAppearance.tintColor.withAlphaComponent(0.25)
        view.highlightColor = uiConfig.navigationAppearance.tintColor.withAlphaComponent(0.25).mp.darker()
        return view
    }()
    
    private let attachButton: FillButton = {
        let view = FillButton(type: .custom)
        let uiConfig = MPUIConfiguration.default()
        view.mp.setRadius(12)
        view.setTitleColor(.white, for: .normal)
        view.setTitle(Lang.attach, for: .normal)
        view.titleLabel?.font = Font.regular(17)
        view.backgroundColor = uiConfig.navigationAppearance.tintColor
        view.fillColor = uiConfig.navigationAppearance.tintColor
        view.highlightColor = uiConfig.navigationAppearance.tintColor.mp.darker()
        view.alpha = 0
        return view
    }()
    
    private let blurContainer: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: MPUIConfiguration.default().navigationAppearance.backgroundEffectStyle)
        let view = UIVisualEffectView(effect: blurEffect)
        return view
    }()
    
    private let showAddToolTip: Bool
    private var isAnimating = false
    
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
        clipsToBounds = true
        attachButton.addSubview(counter)
        self.mp.addSubviews(blurContainer, cancelButton, attachButton)
        if showAddToolTip {
            addSubview(toolTipSubstrate)
            toolTipSubstrate.mp.addSubviews(toolTipDescription, toolTipButton)
            toolTipButton.mp.action({ [weak self] in self?.toolTipButtonTap?() }, forEvent: .touchUpInside)
        }
        attachButton.mp.action({ [weak self] in self?.actionButtonTap?() }, forEvent: .touchUpInside)
        cancelButton.mp.action({ [weak self] in self?.actionButtonTap?() }, forEvent: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !isAnimating else { return }
        blurContainer.frame = bounds
        let sideInset = safeAreaInsets.left > 0 ? safeAreaInsets.left : 16
        if showAddToolTip {
            let (buttonWidth, buttonHeight, textWidth, textHeight) = simulateToolTipSizes(sideInset: sideInset)
            let finalTipContentHeight = buttonHeight > textHeight ? buttonHeight : textHeight
            let finalTipHeight = finalTipContentHeight + 32
            toolTipSubstrate.frame = .init(x: sideInset, y: 16, width: bounds.width - sideInset * 2, height: finalTipHeight)
            toolTipButton.mp.setRadius(buttonHeight / 2)
            toolTipButton.frame = .init(x: (bounds.maxX - sideInset * 2) - buttonWidth - 16, y: finalTipHeight / 2 - buttonHeight / 2, width: buttonWidth, height: buttonHeight)
            toolTipDescription.frame = .init(x: 16, y: finalTipHeight / 2 - textHeight / 2, width: textWidth, height: textHeight)
            if counter.isHidden {
                cancelButton.frame = .init(x: sideInset, y: 28 + finalTipHeight, width: bounds.width - sideInset * 2, height: 44)
                attachButton.frame = .init(x: sideInset, y: 28 + finalTipHeight + 44, width: bounds.width - sideInset * 2, height: 44)
            } else {
                attachButton.frame = .init(x: sideInset, y: 28 + finalTipHeight, width: bounds.width - sideInset * 2, height: 44)
                let oldTransform = cancelButton.transform
                cancelButton.transform = .identity
                cancelButton.frame.origin.x = sideInset
                cancelButton.frame.size.width = bounds.width - sideInset * 2
                cancelButton.transform = oldTransform
            }
        } else {
            if counter.isHidden {
                cancelButton.frame = .init(x: sideInset, y: 8, width: bounds.width - sideInset * 2, height: 44)
                attachButton.frame = .init(x: sideInset, y: 52, width: bounds.width - sideInset * 2, height: 44)
            } else {
                attachButton.frame = .init(x: sideInset, y: 8, width: bounds.width - sideInset * 2, height: 44)
                let oldTransform = cancelButton.transform
                cancelButton.transform = .identity
                cancelButton.frame.origin.x = sideInset
                cancelButton.frame.size.width = bounds.width - sideInset * 2
                cancelButton.transform = oldTransform
            }
        }
        updateCounterPosition()
    }
    
    override var intrinsicContentSize: CGSize {
        if showAddToolTip {
            let sideInset = safeAreaInsets.left > 0 ? safeAreaInsets.left : 16
            let (_, buttonHeight, _, textHeight) = simulateToolTipSizes(sideInset: sideInset)
            // We round to get an integer height, otherwise the view won't go all the way to the bottom
            let finalTipContentHeight = buttonHeight > textHeight ? buttonHeight : textHeight
            let finalTipHeight = (finalTipContentHeight + 32).rounded(.up)
            return .init(width: super.intrinsicContentSize.width, height: finalTipHeight + 28 + 44)
        } else {
            return .init(width: super.intrinsicContentSize.width, height: 52)
        }
    }
    
    private func simulateToolTipSizes(sideInset: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let buttonWidth = (toolTipButton.titleLabel?.mp.textWidth() ?? 0.0) + 28
        let buttonHeight = (toolTipButton.titleLabel?.mp.textHeight(width: buttonWidth) ?? 0.0) + 14
        let textWidth = (bounds.width - sideInset * 2) - (buttonWidth + 32 + 8)
        let textHeight = toolTipDescription.mp.textHeight(width: textWidth)
        
        return (buttonWidth, buttonHeight, textWidth, textHeight)
    }
    
    private func updateCounterPosition() {
        let sizeW = counter.textWidth() + 12
        let sizH = sizeW > 21 ? 21 : sizeW
        counter.mp.setRadius(sizH / 2)
        counter.frame = .init(x: (attachButton.titleLabel?.frame.maxX ?? 0) + 8, y: (44 / 2) - (sizH / 2), width: sizeW, height: sizH)
    }
    
    private func showCounterAnimation() {
        counter.alpha = 0
        counter.isHidden = false
        counter.transform = .init(scaleX: 0.01, y: 0.01)
        
        UIView.animate(withDuration: 0.18, animations: {
            self.counter.alpha = 1.0
            self.counter.transform = .identity
            self.updateCounterPosition()
        })
    }
    
    private func hideCounterAnimation() {
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
    
    private func hideCancelAnimation() {
        let oldCancelFrame = cancelButton.frame
        isAnimating = true
        UIView.animate(withDuration: 0.25, animations: {
            let transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            let finalT = transform.concatenating(.init(translationX: 0, y: -44))
            self.cancelButton.transform = finalT
            self.cancelButton.alpha = 0
            self.attachButton.alpha = 1.0
            self.attachButton.frame.origin.y = oldCancelFrame.minY
            self.layoutIfNeeded()
        },completion: { [weak self] (_) in
            self?.isAnimating = false
        })
    }
    
    private func hideAttachAnimation() {
        let oldAttachFrame = attachButton.frame
        isAnimating = true
        UIView.animate(withDuration: 0.25, animations: {
            self.cancelButton.transform = .identity
            self.cancelButton.alpha = 1.0
            self.attachButton.alpha = 0.0
            self.attachButton.frame.origin.y = oldAttachFrame.minY + 44
            self.layoutIfNeeded()
        },completion: { [weak self] (_) in
            self?.isAnimating = false
        })
    }
    
    func setCounter(_ counter: Int) {
        if counter == 1 && self.counter.isHidden {
            hideCancelAnimation()
            showCounterAnimation()
            self.counter.setCounter(counter)
            layoutSubviews()
        } else if counter <= 0 && !self.counter.isHidden {
            hideAttachAnimation()
            hideCounterAnimation()
        } else {
            self.counter.setCounter(counter)
            layoutSubviews()
        }
    }
}
