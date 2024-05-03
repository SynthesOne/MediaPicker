//
//  CheckboxButton.swift
//
//  Created by Валентин Панчишен on 08.04.2024.
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

// MARK:- CheckboxButton
final class MPCheckboxButton: MPControl {
    fileprivate let animationId = "path"
    
    private lazy var counterLabel: UILabel = {
       let view = UILabel()
        view.textAlignment = .center
        return view
    }()
    
    private var outerLayer = CAShapeLayer()
    private var checkMarkLayer = CAShapeLayer()
    private var backgroundLayer = CAShapeLayer()
    
    private var _checkBoxColor: MPCheckboxColor! {
        didSet {
            updateSelectionState(isAnimate: false)
        }
    }
    
    private var _style: MPCheckboxStyle = .circle {
        didSet {
            setupLayer()
        }
    }
    
    private var _showCounterInCheckbox: Bool = false {
        didSet {
            if _showCounterInCheckbox {
                if !subviews.contains(counterLabel) {
                    addSubview(counterLabel)
                    counterLabel.textColor = _checkBoxColor.checkMarkColor
                    counterLabel.isHidden = true
                    counterLabel.font = Font.semibold(selfSize - 9)
                }
            } else {
                counterLabel.removeFromSuperview()
            }
        }
    }
    
    var showCounterInCheckbox: Bool? {
        didSet {
            if let showCounterInCheckbox {
                _showCounterInCheckbox = showCounterInCheckbox
            }
        }
    }
    
    /// Set checkbox color to customise the buttons
    var checkBoxColor: MPCheckboxColor? = nil {
        didSet {
            if let checkBoxColor {
                _checkBoxColor = checkBoxColor
            }
        }
    }
    
    /// Set checkbox corners style to customise the buttons
    var style: MPCheckboxStyle? = nil {
        didSet {
            if let style {
                _style = style
            }
        }
    }
    
    /// Update buttons size
    var selfSize: CGFloat = 24 {
        didSet {
            counterLabel.font = Font.semibold(selfSize - 9)
            setupLayer()
        }
    }
    
    /// Indicates the index of the selected media
    var counter: Int = 1 {
        didSet {
            if _showCounterInCheckbox && counter != 0 {
                counterLabel.text = "\(counter)"
            }
        }
    }
    
    var uiConfig: MPUIConfiguration {
        didSet {
            _checkBoxColor = uiConfig.selectionButtonColorStyle
            _showCounterInCheckbox = uiConfig.showCounterOnSelectionButton
            _style = uiConfig.selectionButtonCornersStyle
        }
    }
    
    fileprivate var isOn = false
    
    func setIsOn(_ isOn: Bool, isAnimate: Bool = true) {
        guard self.isOn != isOn else { return }
        self.isOn = isOn
        updateSelectionState(isAnimate: isAnimate)
    }
    
    init(frame: CGRect, uiConfig: MPUIConfiguration) {
        self.uiConfig = uiConfig
        super.init(frame: frame)
        setup()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayer()
    }
    
    deinit {
        Logger.log("deinit MPCheckboxButton")
    }
    
    func updateSelectionState(isAnimate: Bool) {
        checkMarkLayer.strokeColor = _checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
        if _showCounterInCheckbox {
            counterLabel.textColor = _checkBoxColor.checkMarkColor
        }
        if isOn {
            updateActiveLayer(isAnimate: isAnimate)
        } else {
            updateInactiveLayer(isAnimate: isAnimate)
        }
        if isAnimate {
            animationBlock()
        }
    }
    
    /// Set default color of chebox
    private func setup() {
        if let checkBoxColor {
            _checkBoxColor = checkBoxColor
        } else {
            _checkBoxColor = uiConfig.selectionButtonColorStyle
        }
        
        if let showCounterInCheckbox {
            _showCounterInCheckbox = showCounterInCheckbox
        } else {
            _showCounterInCheckbox = uiConfig.showCounterOnSelectionButton
        }
        
        if let style {
            _style = style
        } else {
            _style = uiConfig.selectionButtonCornersStyle
        }
    }

    /// Setup layer of check box
    private func setupLayer() {
        let origin = CGPoint(x: 0, y: 0)
        let rect = CGRect(origin: origin, size: .init(width: selfSize, height: selfSize))
        switch _style {
        case .rounded(let radius):
            outerLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        case .circle:
            outerLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: selfSize / 2).cgPath
        case .square:
            outerLayer.path = UIBezierPath(rect: rect).cgPath
        }
        backgroundLayer.path = UIBezierPath(roundedRect: .init(origin: .init(x: selfSize / 2, y: selfSize / 2), size: .zero), cornerRadius: .zero).cgPath
        backgroundLayer.fillColor = _checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        outerLayer.fillColor = .none
        outerLayer.lineWidth = 1.5
        outerLayer.shadowColor = UIColor.black.cgColor
        outerLayer.shadowOpacity = 0.4
        outerLayer.shadowRadius = 1.0
        outerLayer.shadowOffset = .zero
        outerLayer.removeFromSuperlayer()
        layer.insertSublayer(outerLayer, at: 0)
        layer.insertSublayer(backgroundLayer, at: 0)
        
        if !_showCounterInCheckbox {
            let path = UIBezierPath()
            var xPos: CGFloat = (rect.width * 0.25) + origin.x
            var yPos = rect.midY
            path.move(to: CGPoint(x: xPos, y: yPos))
            
            var checkMarkLength = (rect.width/2 - xPos)
            
            [45.0, -45.0].forEach {
                xPos = xPos + checkMarkLength * CGFloat(cos($0 * .pi/180))
                yPos = yPos + checkMarkLength * CGFloat(sin($0 * .pi/180))
                path.addLine(to: CGPoint(x: xPos, y: yPos))
                checkMarkLength *= 2
            }
            
            checkMarkLayer.lineWidth = 2
            checkMarkLayer.strokeColor = _checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
            checkMarkLayer.path = path.cgPath
            checkMarkLayer.lineCap = .round
            checkMarkLayer.lineJoin = .round
            checkMarkLayer.fillColor = .none
            checkMarkLayer.removeFromSuperlayer()
            backgroundLayer.insertSublayer(checkMarkLayer, at: 0)
        } else {
            counterLabel.frame = bounds
            bringSubviewToFront(counterLabel)
        }
        updateSelectionState(isAnimate: false)
    }
    
    /// Update active layer and apply animation
    private func updateActiveLayer(isAnimate: Bool) {
        if let activeBorderColor = _checkBoxColor.activeBorderColor {
            outerLayer.strokeColor = activeBorderColor.resolvedColor(with: traitCollection).cgColor
            if activeBorderColor == _checkBoxColor.activeColor {
                outerLayer.shadowColor = UIColor.clear.cgColor
            } else {
                outerLayer.shadowColor = UIColor.black.cgColor
            }
        } else {
            outerLayer.strokeColor = _checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
            outerLayer.shadowColor = UIColor.clear.cgColor
        }
        backgroundLayer.fillColor = _checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        if !isAnimate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundLayer.removeAnimation(forKey: animationId)
            let _radius: CGFloat
            switch _style {
            case .rounded(let radius):
                _radius = radius
            case .circle:
                _radius = selfSize / 2
            case .square:
                _radius = 0
            }
            backgroundLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: selfSize, height: selfSize), cornerRadius: _radius).cgPath
            
            if _showCounterInCheckbox {
                counterLabel.mp.setIsHidden(false, duration: 0.0)
            } else {
                checkMarkLayer.mp.animateStrokeEnd(from: 0, to: 1)
            }
            CATransaction.commit()
        }
    }
    
    /// Update inactive layer apply animation
    private func updateInactiveLayer(isAnimate: Bool) {
        outerLayer.strokeColor = _checkBoxColor.inactiveBorderColor.resolvedColor(with: traitCollection).cgColor
        outerLayer.shadowColor = UIColor.black.cgColor
        if !isAnimate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundLayer.removeAnimation(forKey: animationId)
            backgroundLayer.path = UIBezierPath(roundedRect: .init(origin: .init(x: selfSize / 2, y: selfSize / 2), size: .zero), cornerRadius: .zero).cgPath
            
            if _showCounterInCheckbox {
                counterLabel.mp.setIsHidden(true, duration: 0.0)
            } else {
                checkMarkLayer.mp.animateStrokeEnd(from: 1, to: 0)
            }
            CATransaction.commit()
        }
    }
    
    private func animationBlock() {
        if isOn {
            if !_showCounterInCheckbox {
                checkMarkLayer.mp.animateStrokeEnd(from: 0, to: 1)
            }
            
            // Bounce animation
            let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            bounceAnimation.values = [0.85, 0.95, 1.0, 1.1, 1.2, 1.1, 1.0]
            bounceAnimation.duration = TimeInterval(0.3)
            bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic
            layer.add(bounceAnimation, forKey: nil)
            
            // Background filling animation
            let animation = CABasicAnimation(keyPath: animationId)
            animation.duration = 0.25
            animation.fillMode = .forwards
            animation.timingFunction = .init(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.isRemovedOnCompletion = false
            
            // Create current path
            let fromPath = UIBezierPath(roundedRect: .init(origin: .init(x: selfSize / 2, y: selfSize / 2), size: .zero), cornerRadius: .zero).cgPath
            
            // Create a new path.
            let _radius: CGFloat
            switch _style {
            case .rounded(let radius):
                _radius = radius
            case .circle:
                _radius = selfSize / 2
            case .square:
                _radius = 0
            }
            let newPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: selfSize, height: selfSize), cornerRadius: _radius).cgPath
            
            // Set start and end values.
            animation.fromValue = fromPath
            animation.toValue = newPath
            
            // Start the animation.
            backgroundLayer.add(animation, forKey: animationId)
            if _showCounterInCheckbox {
                counterLabel.mp.setIsHidden(false)
            }
        } else {
            if !_showCounterInCheckbox {
                checkMarkLayer.mp.animateStrokeEnd(from: 1, to: 0)
            }
            
            // Bounce animation
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.85
            pulse.toValue = 1.0
            pulse.duration = 0.3
            
            layer.add(pulse, forKey: nil)
            
            // Background filling animation
            let animationId = "path"
            let animation = CABasicAnimation(keyPath: animationId)
            animation.duration = 0.25
            animation.fillMode = .forwards
            animation.timingFunction = .init(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.isRemovedOnCompletion = false
            
            // Create current path
            let _radius: CGFloat
            switch _style {
            case .rounded(let radius):
                _radius = radius
            case .circle:
                _radius = selfSize / 2
            case .square:
                _radius = 0
            }
            let fromPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: selfSize, height: selfSize), cornerRadius: _radius).cgPath
            
            // Create a new path.
            let newPath = UIBezierPath(roundedRect: CGRect(x: selfSize / 2, y: selfSize / 2, width: 0, height: 0), cornerRadius: 0).cgPath
            
            // Set start and end values.
            animation.fromValue = fromPath
            animation.toValue = newPath
            
            // Start the animation.
            backgroundLayer.add(animation, forKey: animationId)
            if _showCounterInCheckbox {
                counterLabel.mp.setIsHidden(true)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateSelectionState(isAnimate: false)
        }
    }
}
