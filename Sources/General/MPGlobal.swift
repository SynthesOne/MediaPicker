//
//  Global.swift
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
import Photos

let MaxImageWidth: CGFloat = 500
let UIScreenHeight = UIScreen.mp.current?.bounds.height ?? 1.0
let UIScreenWidth = UIScreen.mp.current?.bounds.width ?? 1.0
let UIScreenScale = UIScreen.mp.current?.scale ?? 1.0
let UIScreenPixel = 1.0 / UIScreenScale

func MPMainAsync(after: TimeInterval = 0, handler: @escaping (() -> ())) {
    if after > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + after, execute: handler)
    } else {
        if Thread.isMainThread {
            handler()
        } else {
            DispatchQueue.main.async(execute: handler)
        }
    }
}
