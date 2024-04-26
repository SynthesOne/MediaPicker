//
//  UILabel+MPExtension.swift
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

extension MPExtensionWrapper where Base: UILabel {
    func textWidth(withText text: String? = nil) -> CGFloat {
        UILabel.mp.textWidth(label: base, text: text)
    }
    
    func textHeight(width: CGFloat? = nil, withText text: String? = nil) -> CGFloat {
        UILabel.mp.textHeight(label: base, width: width, text: text)
    }
    
    static func textHeight(label: UILabel, width: CGFloat?, text: String?) -> CGFloat {
        var _text: String = ""
        if let text {
            _text = text
        } else if let labelText = label.text {
            _text = labelText
        } else {
            return 0.0
        }
        if let width {
            return textHeight(withWidth: width, font: label.font, text: _text)
        } else {
            return textHeight(withWidth: textWidth(label: label, text: _text), font: label.font, text: _text)
        }
    }
    
    static func textHeight(withWidth width: CGFloat, font: UIFont, text: String) -> CGFloat {
        let size = CGSize(width: width, height: 1000)
        
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        let attributes = [NSAttributedString.Key.font: font]
        
        let rectangleHeight = String(text).boundingRect(with: size, options: options, attributes: attributes, context: nil).height
        
        return rectangleHeight
    }
    
    static func textWidth(label: UILabel, text: String?) -> CGFloat {
        var _text: String = ""
        if let text {
            _text = text
        } else if let labelText = label.text {
            _text = labelText
        } else {
            return 0.0
        }
        return textWidth(label: label, text: _text)
    }
    
    static func textWidth(label: UILabel, text: String) -> CGFloat {
        UILabel.mp.textWidth(font: label.font, text: text)
    }
    
    static func textWidth(font: UIFont, text: String) -> CGFloat {
        UILabel.mp.textSize(font: font, text: text).width
    }
    
    static func textSize(font: UIFont, text: String, width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height))
        label.numberOfLines = 0
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.size
    }
}
