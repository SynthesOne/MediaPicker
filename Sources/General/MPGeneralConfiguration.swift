//
//  MPGeneralConfiguration.swift
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
// MPGeneralConfiguration+discardable
public final class MPGeneralConfiguration: NSObject {
    private override init() {
        super.init()
    }
    
    private static var single = MPGeneralConfiguration()
    
    public class func `default`() -> MPGeneralConfiguration {
        return MPGeneralConfiguration.single
    }
    
    public class func resetConfiguration() {
        MPGeneralConfiguration.single = MPGeneralConfiguration()
    }
    
    /// Allow select image media, if false - gif and live photo will not be select either
    public var allowImage = true
    
    /// Allow select gif media
    public var allowGif = true
    
    /// Allow select video media
    public var allowVideo = true
    
    /// Allow select live photo media
    public var allowLivePhoto = true
    
    /// Maximum number of media that can be selected
    public var maxMediaSelectCount = 20
}