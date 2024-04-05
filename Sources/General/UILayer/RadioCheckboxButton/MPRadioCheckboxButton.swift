//
//  MPRadioCheckboxButton.swift
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

public enum MPRadioCheckboxStyle {
    case square, circle, rounded(radius: CGFloat)
}

public class MPRadioCheckboxButton: UIControl {
    private var sizeChangeObserver: NSKeyValueObservation?
    
    public var isOn = false {
        didSet {
            if isOn != oldValue {
                updateSelectionState()
                callDelegate()
            }
        }
    }
    
    public var style: MPRadioCheckboxStyle = .circle {
        didSet {
            setupLayer()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        action({ [weak self] in self?.isOn.toggle() }, forEvent: .touchUpInside)
    }
    
    public func updateSelectionState() {
        if isOn {
            updateActiveLayer()
        } else {
            updateInactiveLayer()
        }
    }
    
    /// Setup layer that will for Radio and Checkbox button
    /// This method can be called mutliple times
    /// Do the stuff by overriding, then call super class method
    func setupLayer() {
        updateSelectionState()
    }
    
    /// Update active layer as button is selected
    func updateActiveLayer() { }
    
    /// Update inative later as button is deselected
    func updateInactiveLayer() { }
    
    /// Call delegate as button selection state changes
    func callDelegate() { }
}

// MARK:- frame change handler
extension MPRadioCheckboxButton {
    private func addObserverSizeChange() {
        sizeChangeObserver = observe(\MPRadioCheckboxButton.frame, changeHandler: sizeChangeObseveHandler)
    }
    
    private func sizeChangeObseveHandler(_ object: MPRadioCheckboxButton, _ change: NSKeyValueObservedChange<CGRect>) {
        setupLayer()
    }
}

extension CAShapeLayer {
    func animateStrokeEnd(from: CGFloat, to: CGFloat) {
        self.strokeEnd = from
        self.strokeEnd = to
    }
    
    func animatePath(start: CGPath, end: CGPath) {
        removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = start
        animation.toValue = end
        animation.isRemovedOnCompletion = true
        add(animation, forKey: "pathAnimation")
    }
}
