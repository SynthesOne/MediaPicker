//
//  MPUIConfiguration.swift
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

public struct MPUIConfiguration {
    private init() { }
    
    public static func `default`() -> MPUIConfiguration {
        return MPUIConfiguration()
    }
    
    /// Shows on the counter selection button
    /// Default value is true
    /// If false, there will be a check mark instead of counter
    public var showCounterOnSelectionButton = true
    
    /// Color scheme for the selection button
    public var selectionButtonColorStyle = MPCheckboxColor.default
    
    /// Selection button rounding style
    public var selectionButtonCornersStyle = MPCheckboxStyle.circle
    
    /// Define primary color of library
    public var navigationAppearance = MPNavigationAppearance.default
    
    /// Define background colors of main screen
    public var primaryBackgroundColor = UIColor.systemBackground
    
    /// Allow show camera cell
    public var showCameraCell = true
    
    /// Custom font name for use inside library
    public var customFontName: [UIFont.Weight: String]? {
        didSet {
            MPFontDeploy.nameSpace = customFontName
        }
    }
	
	/// If access is denied to Photo
	/// Determines whether to show a button to open settings
	public var showOpenSettingsButton = true
}

enum MPFontDeploy {
    static var nameSpace: [UIFont.Weight: String]?
}
