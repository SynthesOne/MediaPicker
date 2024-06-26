//
//  MPProgressRing.swift
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

/// A fillable progress ring drawing.
class MPProgressRing: UIView {
    
    // MARK: Properties
    
    /// Sets the line width for progress ring and groove ring.
    /// - Note: If you need separate customization use the `ringWidth` and `grooveWidth` properties
    var lineWidth: CGFloat = 10 {
        didSet {
            ringWidth = lineWidth
            grooveWidth = lineWidth
        }
    }
    
    /// The line width of the progress ring.
    var ringWidth: CGFloat = 10 {
        didSet {
            ringLayer.lineWidth = ringWidth
        }
    }

    /// The line width of the groove ring.
    var grooveWidth: CGFloat = 10 {
        didSet {
            grooveLayer.lineWidth = grooveWidth
        }
    }
    
    /// The first gradient color of the track.
    var startColor: UIColor = .systemPink {
        didSet { gradientLayer.colors = [startColor.resolvedColor(with: traitCollection).cgColor, endColor.resolvedColor(with: traitCollection).cgColor] }
    }
    
    /// The second gradient color of the track.
    var endColor: UIColor = .systemRed {
        didSet { gradientLayer.colors = [startColor.resolvedColor(with: traitCollection).cgColor, endColor.resolvedColor(with: traitCollection).cgColor] }
    }
    
    /// The groove color in which the fillable ring resides.
    var grooveColor: UIColor = UIColor.systemGray.withAlphaComponent(0.2) {
        didSet { grooveLayer.strokeColor = grooveColor.resolvedColor(with: traitCollection).cgColor }
    }
    
    /// The start angle of the ring to begin drawing.
    var startAngle: CGFloat = -.pi / 2 {
        didSet { ringLayer.path = ringPath() }
    }

    /// The end angle of the ring to end drawing.
    var endAngle: CGFloat = 1.5 * .pi {
        didSet { ringLayer.path = ringPath() }
    }
    
    /// The starting poin of the gradient. Default is (x: 0.5, y: 0)
    var startGradientPoint: CGPoint = .init(x: 0.5, y: 0) {
        didSet { gradientLayer.startPoint = startGradientPoint }
    }
    
    /// The ending position of the gradient. Default is (x: 0.5, y: 1)
    var endGradientPoint: CGPoint = .init(x: 0.5, y: 1) {
        didSet { gradientLayer.endPoint = endGradientPoint }
    }

    /// Duration of the ring's fill animation. Default is 2.0
    var duration: TimeInterval = 2.0
    
    /// Timing function of the ring's fill animation. Default is `.easeOutExpo`
    var timingFunction: ALTimingFunction = .easeOutExpo

    /// The radius of the ring.
    var ringRadius: CGFloat {
        var radius = min(bounds.height, bounds.width) / 2 - ringWidth / 2
        if ringWidth < grooveWidth {
            radius -= (grooveWidth - ringWidth) / 2
        }
        return radius
    }
    
    /// The radius of the groove.
    var grooveRadius: CGFloat {
        var radius = min(bounds.height, bounds.width) / 2 - grooveWidth / 2
        if grooveWidth < ringWidth {
            radius -= (ringWidth - grooveWidth) / 2
        }
        return radius
    }
    
    /// The progress of the ring between 0 and 1. The ring will fill based on the value.
    private(set) var progress: CGFloat = 0

    private let ringLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.fillColor = nil
        layer.strokeStart = 0
        return layer
    }()
    
    private let grooveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.fillColor = nil
        layer.strokeStart = 0
        layer.strokeEnd = 1
        return layer
    }()
    
    private let gradientLayer = CAGradientLayer()

    // MARK: Life Cycle
    public init() {
        super.init(frame: .zero)
        setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mp.setRadius(frame.width / 2)
        configureRing()
        styleRingLayer()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        styleRingLayer()
    }

    // MARK: Methods
    
    /// Set the progress value of the ring. The ring will fill based on the value.
    ///
    /// - Parameters:
    ///   - value: Progress value between 0 and 1.
    ///   - animated: Flag for the fill ring's animation.
    ///   - completion: Closure called after animation ends
    func setProgress(_ value: Float, animated: Bool = true, completion: (() -> Void)? = nil) {
        layoutIfNeeded()
        let value = CGFloat(min(value, 1.0))
        let oldValue = ringLayer.presentation()?.strokeEnd ?? progress
        progress = value
        ringLayer.strokeEnd = progress
        guard animated else {
            layer.removeAnimation(forKey: "rotate.anim")
            ringLayer.removeAnimation(forKey: "fill")
            completion?()
            return
        }

        CATransaction.begin()
        let path = #keyPath(CAShapeLayer.strokeEnd)
        let fill = CABasicAnimation(keyPath: path)
        fill.fromValue = oldValue
        fill.toValue = value
        fill.duration = duration
        fill.timingFunction = timingFunction.function
        CATransaction.setCompletionBlock(completion)
        ringLayer.add(fill, forKey: "fill")
        if layer.animation(forKey: "rotate.anim") == nil {
            animateRotation()
        }
        CATransaction.commit()
    }

    
    private func setup() {
        preservesSuperviewLayoutMargins = true
        layer.addSublayer(grooveLayer)
        layer.addSublayer(gradientLayer)
        styleRingLayer()
    }

    private func styleRingLayer() {
        grooveLayer.strokeColor = grooveColor.resolvedColor(with: traitCollection).cgColor
        grooveLayer.lineWidth = grooveWidth
        
        ringLayer.lineWidth = ringWidth
        ringLayer.strokeColor = UIColor.black.resolvedColor(with: traitCollection).cgColor
        ringLayer.strokeEnd = min(progress, 1.0)
        
        gradientLayer.colors = [startColor.resolvedColor(with: traitCollection).cgColor, endColor.resolvedColor(with: traitCollection).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1)
        
        gradientLayer.shadowColor = startColor.resolvedColor(with: traitCollection).cgColor
        gradientLayer.shadowOffset = .zero
    }

    private func configureRing() {
        let ringPath = self.ringPath()
        let groovePath = self.groovePath()
        grooveLayer.frame = bounds
        grooveLayer.path = groovePath
        
        ringLayer.frame = bounds
        ringLayer.path = ringPath
        
        gradientLayer.frame = bounds
        gradientLayer.mask = ringLayer
    }

    private func ringPath() -> CGPath {
        let center = CGPoint(x: bounds.origin.x + frame.width / 2.0, y: bounds.origin.y + frame.height / 2.0)
        let circlePath = UIBezierPath(arcCenter: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return circlePath.cgPath
    }
    
    private func groovePath() -> CGPath {
        let center = CGPoint(x: bounds.origin.x + frame.width / 2.0, y: bounds.origin.y + frame.height / 2.0)
        let circlePath = UIBezierPath(arcCenter: center, radius: grooveRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return circlePath.cgPath
    }
    
    private func animateRotation() {
        layer.removeAnimation(forKey: "rotate.anim")
        
        let rotationAnimation = MPRotationAnimation(
            direction: .z,
            fromValue: 0,
            toValue: .pi * 2,
            duration: 2,
            repeatCount: .greatestFiniteMagnitude
        )

        layer.add(rotationAnimation, forKey: "rotate.anim")
    }
}

enum ALTimingFunction: String, CaseIterable, Hashable {
    case `default`
    case linear
    case easeIn
    case easeOut
    case easeInEaseOut
    case easeInSine
    case easeOutSine
    case easeInOutSine
    case easeInQuad
    case easeOutQuad
    case easeInOutQuad
    case easeInCubic
    case easeOutCubic
    case easeInOutCubic
    case easeInQuart
    case easeOutQuart
    case easeInOutQuart
    case easeInQuint
    case easeOutQuint
    case easeInOutQuint
    case easeInExpo
    case easeOutExpo
    case easeInOutExpo
    case easeInCirc
    case easeOutCirc
    case easeInOutCirc
    case easeInBack
    case easeOutBack
    case easeInOutBack
    
    var function: CAMediaTimingFunction {
        switch self {
        case .`default`:
            return CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
        case .linear:
            return CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        case .easeIn:
            return CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        case .easeOut:
            return CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        case .easeInEaseOut:
            return CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        case .easeInSine:
            return CAMediaTimingFunction(controlPoints: 0.47, 0, 0.745, 0.715)
        case .easeOutSine:
            return CAMediaTimingFunction(controlPoints: 0.39, 0.575, 0.565, 1)
        case .easeInOutSine:
            return CAMediaTimingFunction(controlPoints: 0.445, 0.05, 0.55, 0.95)
        case .easeInQuad:
            return CAMediaTimingFunction(controlPoints: 0.55, 0.085, 0.68, 0.53)
        case .easeOutQuad:
            return CAMediaTimingFunction(controlPoints: 0.25, 0.46, 0.45, 0.94)
        case .easeInOutQuad:
            return CAMediaTimingFunction(controlPoints: 0.455, 0.03, 0.515, 0.955)
        case .easeInCubic:
            return CAMediaTimingFunction(controlPoints: 0.55, 0.055, 0.675, 0.19)
        case .easeOutCubic:
            return CAMediaTimingFunction(controlPoints: 0.215, 0.61, 0.355, 1)
        case .easeInOutCubic:
            return CAMediaTimingFunction(controlPoints: 0.645, 0.045, 0.355, 1)
        case .easeInQuart:
            return CAMediaTimingFunction(controlPoints: 0.895, 0.03, 0.685, 0.22)
        case .easeOutQuart:
            return CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1)
        case .easeInOutQuart:
            return CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1)
        case .easeInQuint:
            return CAMediaTimingFunction(controlPoints: 0.755, 0.05, 0.855, 0.06)
        case .easeOutQuint:
            return CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
        case .easeInOutQuint:
            return CAMediaTimingFunction(controlPoints: 0.86, 0, 0.07, 1)
        case .easeInExpo:
            return CAMediaTimingFunction(controlPoints: 0.95, 0.05, 0.795, 0.035)
        case .easeOutExpo:
            return CAMediaTimingFunction(controlPoints: 0.19, 1, 0.22, 1)
        case .easeInOutExpo:
            return CAMediaTimingFunction(controlPoints: 1, 0, 0, 1)
        case .easeInCirc:
            return CAMediaTimingFunction(controlPoints: 0.6, 0.04, 0.98, 0.335)
        case .easeOutCirc:
            return CAMediaTimingFunction(controlPoints: 0.075, 0.82, 0.165, 1)
        case .easeInOutCirc:
            return CAMediaTimingFunction(controlPoints: 0.785, 0.135, 0.15, 0.86)
        case .easeInBack:
            return CAMediaTimingFunction(controlPoints: 0.6, -0.28, 0.735, 0.045)
        case .easeOutBack:
            return CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275)
        case .easeInOutBack:
            return CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
        }
    }
}
