//
//  File.swift
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

enum Lang {
    static var generalConfig = MPGeneralConfiguration.default()
    
    static var toolTipControl: String {
        Lang.tr("MPToolTipControl")
    }
    
    static var cancel: String {
        Lang.tr("MPCancel")
    }
    
    static var ok: String {
        Lang.tr("MPOk")
    }
    
    static var notAuthPhotos: String {
        Lang.tr("MPNotAuthPhotos")
    }
    
    static var unknownAlbum: String {
        Lang.tr("MPUnknownAlbum")
    }
    
    static var attach: String {
        Lang.tr("MPAttach")
    }
    
    static var errorSaveImage: String {
        Lang.tr("MPErrorSaveImage")
    }
    
    static var errorSaveVideo: String {
        Lang.tr("MPErrorSaveVideo")
    }
    
    static var сameraUnavailable: String {
        Lang.tr("MPCameraUnavailable")
    }
    
    static var cameraAccessMessage: String {
        Lang.tr("MPCameraAccessMessage")
    }
    
    static var changeSettings: String {
        Lang.tr("MPChangeSettings")
    }
    
    static var selectMorePhotos: String {
        Lang.tr("MPSelectMorePhotos")
    }
    
    static var recents: String {
        Lang.tr("MPRecents")
    }
    
    static var limitedAccessTip: String {
        Lang.tr("MPLimitedAccessTip")
    }
    
    static var cancelSelect: String {
        Lang.tr("MPCancelSelect")
    }
    
    static var yes: String {
        Lang.tr("MPYes")
    }
    
    static var no: String {
        Lang.tr("MPNo")
    }
    
    static var сloudError: String {
        Lang.tr("MPCloudError")
    }
    
    static var all: String {
        Lang.tr("MPAll")
    }
    
    static var chosen: String {
        Lang.tr("MPChosen")
    }
    
    static var ddDescription: String {
        Lang.tr("MPddDescription")
    }
}

extension Lang {
    static func tr(_ key: String) -> String {
        let bundle: Bundle
        
        var _key = key
        if generalConfig.keysLangsDeploy.isEmpty {
            bundle = generalConfig.bundleLangsDeploy ?? .module
        } else {
            if let deployKey = generalConfig.keysLangsDeploy[key] {
                _key = deployKey
                bundle = generalConfig.bundleLangsDeploy ?? .module
            } else {
                bundle = .module
            }
        }
        
        switch generalConfig.stringCatalogType {
        case .xcstrings:
            return .locale(_key, bundle: bundle)
        case .lproj:
            let selectedLanguage = Locale.preferredLanguages.first ?? "en"
            guard let path = bundle.path(forResource: selectedLanguage, ofType: "lproj"),
                  let bundle = Bundle(path: path)
            else {
                return ""
            }
            let format = NSLocalizedString(_key, tableName: nil, bundle: bundle, value: "", comment: "")
            return String(format: format, locale: Locale.current)
        }
    }
}
