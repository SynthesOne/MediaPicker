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
    private let counter: Counter = {
       let view = Counter()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 9
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private let actionButton: FillButton = {
        let view = FillButton(type: .custom)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        view.setTitleColor(.white, for: .normal)
        view.setTitle("Cancel", for: .normal)
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
    
    var onTap: (() -> ())? = nil
    
    init() {
        super.init(frame: .zero)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        //backgroundColor = .red
        self.mp.addSubviews(blurContainer, actionButton)
        actionButton.addSubview(counter)
        actionButton.mp.action({ [weak self] in self?.onTap?() }, forEvent: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurContainer.frame = bounds
        actionButton.frame = .init(x: 8, y: 8, width: bounds.width - 16, height: 44)
        updateCounterPosition()
    }
    
    func setCounter(_ counter: Int) {
        actionButton.setTitle(counter <= 0 ? "Cancel" : "Add", for: .normal)
        if counter == 1 && self.counter.isHidden {
            showCounterAnimation()
            self.counter.setCounter(counter)
        } else if counter <= 0 && !self.counter.isHidden {
            hideCounterAnimation()
        } else {
            self.counter.setCounter(counter)
        }
    }
    
    private func updateButtonActionButtond(hasCount: Bool) {
        if hasCount {
            actionButton.setTitle("Add", for: .normal)
            actionButton.backgroundColor = MPUIConfiguration.default().navigationAppearance.tintColor
            actionButton.fillColor = MPUIConfiguration.default().navigationAppearance.tintColor
            actionButton.highlightColor = MPUIConfiguration.default().navigationAppearance.tintColor.mp.darker()
        } else {
            actionButton.setTitle("Cancel", for: .normal)
            actionButton.backgroundColor = .systemGray
            actionButton.fillColor = .systemGray
            actionButton.highlightColor = .systemGray.mp.darker()
        }
    }
    
    private func updateCounterPosition() {
        counter.frame = .init(x: (actionButton.titleLabel?.frame.maxX ?? 0) + 8, y: 13, width: counter.textWidth + 12, height: 18)
    }
    
    private func showCounterAnimation(completion: (() -> ())? = nil) {
        updateButtonActionButtond(hasCount: true)
        counter.alpha = 0
        counter.isHidden = false
        counter.transform = .init(scaleX: 0.01, y: 0.01)
        
        UIView.animate(withDuration: 0.18, animations: { [weak self] in
            self?.counter.alpha = 1.0
            self?.counter.transform = .identity
            self?.layoutIfNeeded()
            self?.updateCounterPosition()
        }) { (_) in
            completion?()
        }
    }
    
    private func hideCounterAnimation() {
        updateButtonActionButtond(hasCount: false)
        // It is necessary to remove animations to avoid glitch with bounce animation
        counter.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.18, animations: { [weak self] in
            self?.counter.alpha = 0.0
            self?.counter.transform = .init(scaleX: 0.01, y: 0.01)
            self?.layoutIfNeeded()
        }, completion: { [weak self] (_) in
            self?.counter.isHidden = true
            self?.counter.alpha = 1.0
            self?.counter.transform = .identity
        })
    }
}