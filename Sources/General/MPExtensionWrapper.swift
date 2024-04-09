//
//  MPExtensionsWrapper.swift
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
    

import Foundation
import UIKit
import Photos

public struct MPExtensionWrapper<Base> {
    public let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol MPExtensionCompatible: AnyObject { }
public protocol MPExtensionCompatibleValue { }

extension MPExtensionCompatible {
    public var mp: MPExtensionWrapper<Self> {
        get { MPExtensionWrapper(self) }
        set { }
    }
    
    public static var mp: MPExtensionWrapper<Self>.Type {
        get { MPExtensionWrapper<Self>.self }
        set { }
    }
}

extension MPExtensionCompatibleValue {
    public var mp: MPExtensionWrapper<Self> {
        get { MPExtensionWrapper(self) }
        set { }
    }
    
    public static var mp: MPExtensionWrapper<Self>.Type {
        get { MPExtensionWrapper<Self>.self }
        set { }
    }
}

extension UIControl: MPExtensionCompatible { }
extension UIApplication: MPExtensionCompatible { }
extension UIScreen: MPExtensionCompatible { }
extension PHAsset: MPExtensionCompatible { }

extension UIAction.Identifier: MPExtensionCompatibleValue { }