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
    private var sizeChangeObserver: NSKeyValueObservation?
    
    private lazy var counterLabel: UILabel = {
       let view = UILabel()
        view.font = .systemFont(ofSize: 15, weight: .semibold)
        view.textAlignment = .center
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.5
        return view
    }()
    
    private var outerLayer = CAShapeLayer()
    private var checkMarkLayer = CAShapeLayer()
    private var backgroundLayer = CAShapeLayer()
    private var selfSize: CGFloat = 24
    
    /// Set checkbox color to customise the buttons
    private var checkBoxColor: MPCheckboxColor! {
        didSet {
            checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
            updateSelectionState()
        }
    }
    
    private var style: MPCheckboxStyle = .circle {
        didSet {
            setupLayer()
        }
    }
    
    /// Indicates the index of the selected media
    var counter: Int = 1 {
        didSet {
            if MPUIConfiguration.default().showCounterOnSelectionButton && counter != 0 {
                counterLabel.text = "\(counter)"
            }
        }
    }
    
    var isOn = false {
        didSet {
            if isOn != oldValue {
                updateSelectionState()
                animationBlock()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        sizeChangeObserver?.invalidate()
        sizeChangeObserver = nil
        Logger.log("deinit MPCheckboxButton")
    }
    
    func updateSelectionState() {
        if isOn {
            updateActiveLayer()
        } else {
            updateInactiveLayer()
        }
    }
    
    /// Set default color of chebox
    func setup() {
        checkBoxColor = MPUIConfiguration.default().selectionButtonColorStyle
        style = MPUIConfiguration.default().selectionButtonCornersStyle
        if MPUIConfiguration.default().showCounterOnSelectionButton {
            addSubview(counterLabel)
            counterLabel.textColor = MPUIConfiguration.default().selectionButtonColorStyle.checkMarkColor
            counterLabel.isHidden = true
        }
        addObserverSizeChange()
        setupLayer()
    }

    /// Setup layer of check box
    func setupLayer() {
        let origin = CGPoint(x: 0, y: 0)
        let rect = CGRect(origin: origin, size: .init(width: selfSize, height: selfSize))
        switch style {
        case .rounded(let radius):
            outerLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        case .circle:
            outerLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: selfSize / 2).cgPath
        case .square:
            outerLayer.path = UIBezierPath(rect: rect).cgPath
        }
        backgroundLayer.path = UIBezierPath(roundedRect: .init(origin: .init(x: selfSize / 2, y: selfSize / 2), size: .zero), cornerRadius: .zero).cgPath
        backgroundLayer.fillColor = checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        outerLayer.fillColor = .none
        outerLayer.lineWidth = 1
        outerLayer.shadowColor = UIColor.black.cgColor
        outerLayer.shadowOpacity = 0.4
        outerLayer.shadowRadius = 1.0
        outerLayer.shadowOffset = .zero
        outerLayer.removeFromSuperlayer()
        layer.insertSublayer(outerLayer, at: 0)
        layer.insertSublayer(backgroundLayer, at: 0)
        
        if !MPUIConfiguration.default().showCounterOnSelectionButton {
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
            checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
            checkMarkLayer.path = path.cgPath
            checkMarkLayer.lineCap = .round
            checkMarkLayer.lineJoin = .round
            checkMarkLayer.fillColor = .none
            checkMarkLayer.removeFromSuperlayer()
            outerLayer.insertSublayer(checkMarkLayer, at: 0)
        } else {
            counterLabel.frame = bounds
            bringSubviewToFront(counterLabel)
        }
        updateSelectionState()
    }
    
    /// Update active layer and apply animation
    func updateActiveLayer() {
        if let activeBorderColor = checkBoxColor.activeBorderColor {
            outerLayer.strokeColor = activeBorderColor.resolvedColor(with: traitCollection).cgColor
        } else {
            outerLayer.strokeColor = checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        }
    }
    
    /// Update inactive layer apply animation
    func updateInactiveLayer() {
        outerLayer.strokeColor = checkBoxColor.inactiveBorderColor.resolvedColor(with: traitCollection).cgColor
    }
    
    func animationBlock() {
        if isOn {
            if !MPUIConfiguration.default().showCounterOnSelectionButton {
                checkMarkLayer.mp.animateStrokeEnd(from: 0, to: 1)
            }
            
            // Bounce animation
            let pulse = CASpringAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.85
            pulse.toValue = 1.0
            pulse.damping = 2.0
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
            let fromPath = backgroundLayer.path
            
            // Create a new path.
            let _radius: CGFloat
            switch style {
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
            if MPUIConfiguration.default().showCounterOnSelectionButton {
                counterLabel.mp.setIsHidden(false)
            }
        } else {
            if !MPUIConfiguration.default().showCounterOnSelectionButton {
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
            switch style {
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
            if MPUIConfiguration.default().showCounterOnSelectionButton {
                counterLabel.mp.setIsHidden(true)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
            updateSelectionState()
        }
    }
}

extension MPCheckboxButton {
    private func addObserverSizeChange() {
        sizeChangeObserver = observe(\MPCheckboxButton.frame, changeHandler: sizeChangeObseveHandler)
    }
    
    private func sizeChangeObseveHandler(_ object: MPCheckboxButton, _ change: NSKeyValueObservedChange<CGRect>) {
        setupLayer()
    }
}
