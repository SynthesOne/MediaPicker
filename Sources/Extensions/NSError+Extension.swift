//
//  NSError+Extension.swift
//
//  Created by Валентин Панчишен on 22.04.2024.
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

extension NSError {
    convenience init(message: String) {
        let userInfo = [NSLocalizedDescriptionKey: message]
        self.init(domain: "com.MediaPicker.error", code: -1, userInfo: userInfo)
    }
}

extension NSError {
    static let videoMergeError = NSError(message: "Video merge failed")
    
    static let videoExportTypeError = NSError(message: "The mediaType of asset must be video")
    
    static let videoExportError = NSError(message: "Video export failed")
    
    static let assetSaveError = NSError(message: "Asset save failed")
    
    static let timeoutError = NSError(message: "Timeout")
}
