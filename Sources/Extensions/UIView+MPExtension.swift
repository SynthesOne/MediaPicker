//
//  UIView+MPExtension.swift
//
//  Created by Валентин Панчишен on 09.04.2024.
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

extension MPExtensionWrapper where Base: UIView {
    func setIsHidden(_ hidden: Bool, duration: CGFloat = 0.25) {
        if base.isHidden && !hidden {
            base.alpha = 0.0
            base.isHidden = false
        }
        
        UIView.animate(withDuration: duration, animations: {
            base.alpha = hidden ? 0.0 : 1.0
        }) { (_) in
            base.isHidden = hidden
        }
    }
    
    func addSubviews(_ subviews: UIView...) {
        subviews.forEach {
            base.addSubview($0)
        }
    }
    
    var globalFrame: CGRect? {
        base.superview?.convert(base.frame, to: nil)
    }
    
    func setRadius(_ radius: CGFloat) {
        base.layer.masksToBounds = true
        base.layer.cornerRadius = radius
    }
}
