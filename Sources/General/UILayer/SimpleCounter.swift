//
//  SimpleCounter.swift
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

final class Counter: UIView {
    private let unreadCounter: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = Font.regular(13)
        view.text = "1"
        return view
    }()
    
    var text: String? {
        unreadCounter.text
    }
    
    func textWidth() -> CGFloat {
        unreadCounter.mp.textWidth()
    }
    
    fileprivate let uiConfig: MPUIConfiguration
    
    // MARK: Life Cycle
    init(uiConfig: MPUIConfiguration) {
        self.uiConfig = uiConfig
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        unreadCounter.textColor = uiConfig.navigationAppearance.tintColor
        addSubview(unreadCounter)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        unreadCounter.frame = bounds
    }
    
    func setCounter(_ counter: Int) {
        if let text, let currentCount = Int(text) {
            if counter > currentCount {
                let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
                bounceAnimation.values = [1.0, 1.2, 1.0]
                bounceAnimation.duration = 0.3
                bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic
                layer.add(bounceAnimation, forKey: nil)
            } else if counter < currentCount {
                let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
                bounceAnimation.values = [1.0, 0.8, 1.0]
                bounceAnimation.duration = 0.3
                bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic
                layer.add(bounceAnimation, forKey: nil)
            }
        }
        unreadCounter.text = "\(counter)"
    }
}

