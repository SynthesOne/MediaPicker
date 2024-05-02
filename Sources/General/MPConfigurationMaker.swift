//
//  MPConfigurationMaker.swift
//
//  Created by Валентин Панчишен on 02.05.2024.
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

public protocol MPUIConfigMakerExtendable: NSObjectProtocol {
    func setShowCounterOnSelectionButton(_ value: Bool) -> MPConfigurationMakerExtendable
    func setSelectionButtonCornersStyle(_ value: MPCheckboxStyle) -> MPConfigurationMakerExtendable
    func setSelectionButtonColorStyle(_ value: MPCheckboxColor) -> MPConfigurationMakerExtendable
    func setNavigationAppearance(_ value: MPNavigationAppearance) -> MPConfigurationMakerExtendable
    func setPrimaryBackgroundColor(_ value: UIColor) -> MPConfigurationMakerExtendable
    func setShowCameraCell(_ value: Bool) -> MPConfigurationMakerExtendable
    func setUIConfiguration(_ value: MPUIConfiguration) -> MPConfigurationMakerExtendable
}

public protocol MPGeneralConfigMakerExtendable: NSObjectProtocol {
    func setAllowImage(_ value: Bool) -> MPConfigurationMakerExtendable
    func setAllowGif(_ value: Bool) -> MPConfigurationMakerExtendable
    func setAllowVideo(_ value: Bool) -> MPConfigurationMakerExtendable
    func setAllowLivePhoto(_ value: Bool) -> MPConfigurationMakerExtendable
    func setMaxMediaSelectCount(_ value: Int) -> MPConfigurationMakerExtendable
    func setBundleLangsDeploy(_ value: Bundle) -> MPConfigurationMakerExtendable
    func setKeysLangsDeploy(_ value: [String: String]) -> MPConfigurationMakerExtendable
    func setStringCatalogType(_ value: MPGeneralConfiguration.StringCatalogType) -> MPConfigurationMakerExtendable
    func setGeneralConfiguration(_ value: MPGeneralConfiguration) -> MPConfigurationMakerExtendable
}

public protocol MPConfigurationMakerExtendable: MPUIConfigMakerExtendable, MPGeneralConfigMakerExtendable {
    var uiConfig: MPUIConfiguration { get }
    var generalConfig: MPGeneralConfiguration { get }
    static var `default`: MPConfigurationMakerExtendable { get }
}

public final class MPConfigurationMaker: NSObject, MPConfigurationMakerExtendable {
    public static var `default`: MPConfigurationMakerExtendable {
        self.init()
    }
    
    public var uiConfig: MPUIConfiguration = .default()
    public var generalConfig: MPGeneralConfiguration = .default()
    
    override init() {
        super.init()
    }
}
