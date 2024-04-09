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
    /// - Parameter button: CheckboxButton
    func chechboxButtonDidSelect(_ button: MPCheckboxButton)
    
    /// Delegate call when Checkbox is deselected
    ///
    /// - Parameter button: CheckboxButton
    func chechboxButtonDidDeselect(_ button: MPCheckboxButton)
}

// MARK:- CheckboxButton
public class MPCheckboxButton: MPRadioCheckboxBaseButton {
    
    private var outerLayer = CAShapeLayer()
    private var checkMarkLayer = CAShapeLayer()
    
    // Make sure color did should not call while setting internal
    private var radioButtonColorDidSetCall = false
    
    /// Set you delegate handler
    public weak var delegate: MPCheckboxButtonDelegate?
    
    /// Duplicates the delegate method `chechboxButtonDidSelect`
    public var chechboxButtonDidSelect: ((MPCheckboxButton) -> ())?
    
    /// Duplicates the delegate method `chechboxButtonDidDeselect`
    public var chechboxButtonDidDeselect: ((MPCheckboxButton) -> ())?
    
    /// Set checkbox color to customise the buttons
    public var checkBoxColor: MPCheckboxColor! {
        didSet {
            if radioButtonColorDidSetCall {
                checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
                updateSelectionState()
            }
        }
    }
    
    /// Apply checkbox line to gcustomize checkbox button layout
    public var checkboxLine = MPCheckboxLineStyle() {
        didSet {
            setupLayer()
        }
    }
    
    /// Set default color of chebox
    override func setup() {
        checkBoxColor = MPCheckboxColor(activeColor: tintColor, inactiveColor: .clear, inactiveBorderColor: .lightGray, checkMarkColor: .white)
        style = .rounded(radius: 2)
        super.setup()
        radioButtonColorDidSetCall = true
    }
    
    /// Setup layer of check box
    override func setupLayer() {
        //contentEdgeInsets = UIEdgeInsets(top: 0, left: checkboxLine.checkBoxHeight + checkboxLine.padding, bottom: 0, right: 0)
        // Make inner later here
        let origin = CGPoint(x: 0.5, y: bounds.midY - (checkboxLine.checkBoxHeight/2))
        let rect = CGRect(origin: origin, size: checkboxLine.size)
        switch style {
        case .rounded(let radius):
            outerLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        case .circle:
            outerLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: checkboxLine.size.height/2).cgPath
        case .square:
            outerLayer.path = UIBezierPath(rect: rect).cgPath
        }
        outerLayer.lineWidth = 1
        outerLayer.removeFromSuperlayer()
        layer.insertSublayer(outerLayer, at: 0)
        
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
        
        checkMarkLayer.lineWidth = checkboxLine.checkmarkLineWidth == -1 ? max(checkboxLine.checkBoxHeight*0.1, 2) : checkboxLine.checkmarkLineWidth
        checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
        checkMarkLayer.path = path.cgPath
        checkMarkLayer.lineCap = .round
        checkMarkLayer.lineJoin = .round
        checkMarkLayer.fillColor = .none
        checkMarkLayer.removeFromSuperlayer()
        outerLayer.insertSublayer(checkMarkLayer, at: 0)
        
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
        checkMarkLayer.animateStrokeEnd(from: 0, to: 1)
        outerLayer.fillColor = checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        if let activeBorderColor = checkBoxColor.activeBorderColor {
            outerLayer.strokeColor = activeBorderColor.resolvedColor(with: traitCollection).cgColor
        } else {
            outerLayer.strokeColor = checkBoxColor.activeColor.resolvedColor(with: traitCollection).cgColor
        }
    }
    
    /// Update inactive layer apply animation
    override func updateInactiveLayer() {
        checkMarkLayer.animateStrokeEnd(from: 1, to: 0)
        outerLayer.fillColor = checkBoxColor.inactiveColor.resolvedColor(with: traitCollection).cgColor
        outerLayer.strokeColor = checkBoxColor.inactiveBorderColor.resolvedColor(with: traitCollection).cgColor
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection), radioButtonColorDidSetCall {
            checkMarkLayer.strokeColor = checkBoxColor.checkMarkColor.resolvedColor(with: traitCollection).cgColor
            updateSelectionState()
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let button: MPCheckboxButton = {
        let view = MPCheckboxButton(frame: CGRect(origin: .zero, size: .init(width: 24, height: 24)))
        view.contentMode = .center
        view.contentVerticalAlignment = .center
        view.style = .circle
        view.checkboxLine = .init(checkBoxHeight: 24)
        return view
    }()
    
    let viewController = UIViewController()
    viewController.view.backgroundColor = .systemBackground
    viewController.view.addSubview(button)
    button.center = viewController.view.center
    
    return viewController
}
