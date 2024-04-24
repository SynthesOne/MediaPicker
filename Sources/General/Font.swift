//
//  Font.swift
//
//  Created by Валентин Панчишен on 24.04.2024.
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

extension MPExtensionWrapper where Base: UIFont {
    static func font(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if let customFontName = MPFontDeploy.nameSpace?[weight] {
            return UIFont(name: customFontName, size: size) ?? .systemFont(ofSize: size, weight: weight)
        }
        
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}

enum Font {
    static func regular(_ size: CGFloat) -> UIFont {
        UIFont.mp.font(size, weight: .regular)
    }
    
    static func medium(_ size: CGFloat) -> UIFont {
        UIFont.mp.font(size, weight: .medium)
    }
    
    static func semibold(_ size: CGFloat) -> UIFont {
        UIFont.mp.font(size, weight: .semibold)
    }
}
