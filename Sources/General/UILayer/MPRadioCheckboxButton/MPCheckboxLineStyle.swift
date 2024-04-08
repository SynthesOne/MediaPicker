//
//  CheckboxLineStyle.swift
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

// MARK: CheckboxLineStyle
/// Define Checkbox style
public struct MPCheckboxLineStyle {
    let checkBoxHeight: CGFloat
    let checkmarkLineWidth: CGFloat
    let padding: CGFloat
    
    public init(checkBoxHeight: CGFloat, checkmarkLineWidth: CGFloat = -1, padding: CGFloat = 6) {
        self.checkBoxHeight = checkBoxHeight
        self.checkmarkLineWidth = checkmarkLineWidth
        self.padding = padding
    }
    
    public init(checkmarkLineWidth: CGFloat, padding: CGFloat = 6) {
        self.init(checkBoxHeight: 18, checkmarkLineWidth: checkmarkLineWidth, padding: padding)
    }
    
    public init(padding: CGFloat = 6) {
        self.init(checkmarkLineWidth: -1, padding: padding)
    }
    
    public var size: CGSize {
        return CGSize(width: checkBoxHeight, height: checkBoxHeight)
    }
}
