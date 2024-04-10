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

// MARK:- CheckboxButtonDelegate
public protocol MPCheckboxButtonDelegate: AnyObject {
    /// Delegate call when Checkbox is selected
    ///
    /// - Parameter button: MPCheckboxButton
    func chechboxButtonDidSelect(_ button: MPCheckboxButton)
    
    /// Delegate call when Checkbox is deselected
    ///
    /// - Parameter button: MPCheckboxButton
    func chechboxButtonDidDeselect(_ button: MPCheckboxButton)
}

// MARK:- CheckboxButton
public class MPCheckboxButton: MPRadioCheckboxBaseButton {
    
    private lazy var counterLabel: UILabel = {
       let view = UILabel()
        view.font = .systemFont(ofSize: 15, weight: .semibold)
        view.textAlignment = .center
        return view
    }()
    
    private var outerLayer = CAShapeLayer()
    private var checkMarkLayer = CAShapeLayer()
    private var bacgroundLayer = CAShapeLayer()
    private var selfSize: CGFloat = 24
    
    /// UI Configurator
    private let uiConfig = MPUIConfiguration.default()
    
    /// Set you delegate handler
    public weak var delegate: MPCheckboxButtonDelegate?
    
    /// Set checkbox color to customise the buttons
    private var checkBoxColor: MPCheckboxColor! {
        didSet {
            checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
            updateSelectionState()
        }
    }
    
    /// Indicates the index of the selected media
    public var counter: Int = 1 {
        didSet {
            if uiConfig.showCounterOnSelectionButton {
                counterLabel.text = "\(counter)"
            }
        }
    }
    
    /// Duplicates the delegate method `chechboxButtonDidSelect`
    public var chechboxButtonDidSelect: ((MPCheckboxButton) -> ())?
    
    /// Duplicates the delegate method `chechboxButtonDidDeselect`
    public var chechboxButtonDidDeselect: ((MPCheckboxButton) -> ())?
    
    /// Set default color of chebox
    override func setup() {
        checkBoxColor = uiConfig.selectionButtonColorStyle
        style = uiConfig.selectionButtonCornersStyle
        if uiConfig.showCounterOnSelectionButton {
            addSubview(counterLabel)
            counterLabel.textColor = uiConfig.selectionButtonColorStyle.checkMarkColor
            counterLabel.isHidden = true
        }
        super.setup()
    }

    /// Setup layer of check box
    override func setupLayer() {
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
        bacgroundLayer.path = UIBezierPath(roundedRect: .init(origin: .init(x: selfSize / 2, y: selfSize / 2), size: .zero), cornerRadius: .zero).cgPath
        bacgroundLayer.fillColor = checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        outerLayer.fillColor = .none
        outerLayer.lineWidth = 1
        outerLayer.removeFromSuperlayer()
        layer.insertSublayer(outerLayer, at: 0)
        layer.insertSublayer(bacgroundLayer, at: 0)
        
        if !uiConfig.showCounterOnSelectionButton {
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
        super.setupLayer()
    }
    
    /// Delegate call
    override func callDelegate() {
        super.callDelegate()
        if isOn {
            delegate?.chechboxButtonDidSelect(self)
            chechboxButtonDidSelect?(self)
        } else {
            delegate?.chechboxButtonDidDeselect(self)
            chechboxButtonDidDeselect?(self)
        }
    }
    
    /// Update active layer and apply animation
    override func updateActiveLayer() {
        if !uiConfig.showCounterOnSelectionButton {
            checkMarkLayer.animateStrokeEnd(from: 0, to: 1)
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
        let fromPath = UIBezierPath(roundedRect: CGRect(x: selfSize / 2, y: selfSize / 2, width: 0, height: 0), cornerRadius: 0).cgPath
        
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
        bacgroundLayer.add(animation, forKey: animationId)
        
        if let activeBorderColor = checkBoxColor.activeBorderColor {
            outerLayer.strokeColor = activeBorderColor.resolvedColor(with: traitCollection).cgColor
        } else {
            outerLayer.strokeColor = checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        }
        
        if uiConfig.showCounterOnSelectionButton {
            counterLabel.mp.setIsHidden(false)
        }
    }
    
    /// Update inactive layer apply animation
    override func updateInactiveLayer() {
        if !uiConfig.showCounterOnSelectionButton {
            checkMarkLayer.animateStrokeEnd(from: 1, to: 0)
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
        bacgroundLayer.add(animation, forKey: animationId)
        
        outerLayer.strokeColor = checkBoxColor.inactiveBorderColor.resolvedColor(with: traitCollection).cgColor
        
        if uiConfig.showCounterOnSelectionButton {
            counterLabel.mp.setIsHidden(true)
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
            updateSelectionState()
        }
    }
}
