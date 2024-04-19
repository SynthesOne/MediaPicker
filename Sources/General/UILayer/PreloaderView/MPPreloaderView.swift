//
//  MPPreloaderView.swift
//
//  Created by Валентин Панчишен on 16.04.2024.
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

// MARK: - Custom Preloader for WebView
final class MPPreloaderView: UIView {
    
    // MARK: - Initialization
    public init(frame: CGRect,
                color: UIColor,
                lineWidth: CGFloat
    ) {
        self.color = color
        self.lineWidth = lineWidth
        super.init(frame: frame)
        
        backgroundColor = .none
    }
    
    public convenience init(color: UIColor, lineWidth: CGFloat) {
        self.init(frame: .zero, color: color, lineWidth: lineWidth)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = frame.width / 2
        
        let path = UIBezierPath(
            ovalIn:
                CGRect(
                    x: 0,
                    y: 0,
                    width: bounds.width,
                    height: bounds.width
                )
        )
        
        shapeLayer.path = path.cgPath
    }
    
    // MARK: - Animations
    
    public func animateStroke() {
        let startAnimation = MPStrokeAnimation(
            type: .start,
            beginTime: 0.25,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 0.75
        )
        
        let endAnimation = MPStrokeAnimation(
            type: .end,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 0.75
        )
        
        let strokeAnimationGroup = CAAnimationGroup()
        strokeAnimationGroup.duration = 1
        strokeAnimationGroup.repeatDuration = .infinity
        strokeAnimationGroup.animations = [startAnimation, endAnimation]
        strokeAnimationGroup.isRemovedOnCompletion = false
        
        shapeLayer.add(strokeAnimationGroup, forKey: nil)
        
        layer.addSublayer(shapeLayer)
    }
    
    public func animateRotation() {
        let rotationAnimation = MPRotationAnimation(
            direction: .z,
            fromValue: 0,
            toValue: CGFloat.pi * 2,
            duration: 2,
            repeatCount: .greatestFiniteMagnitude
        )
        rotationAnimation.isRemovedOnCompletion = false
        layer.add(rotationAnimation, forKey: nil)
    }
    
    // MARK: - Properties
    var color = UIColor()
    let lineWidth: CGFloat
    
    private lazy var shapeLayer: PreloaderShapeLayer = {
        PreloaderShapeLayer(strokeColor: color, lineWidth: lineWidth)
    }()
    
    var isAnimating: Bool = false {
        didSet {
            if isAnimating {
                animateStroke()
                animateRotation()
            } else {
                shapeLayer.removeFromSuperlayer()
                layer.removeAllAnimations()
            }
        }
    }
    
    func updateColor(_ color: UIColor) {
        shapeLayer.strokeColor = color.cgColor
    }
}

