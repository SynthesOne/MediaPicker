//
//  MPNavigationViewController.swift
//
//  Created by Валентин Панчишен on 10.04.2024.
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

public struct MPNavigationAppearance {
    public var tintColor: UIColor
    public var shadowColor: UIColor
    public var backgroundEffectStyle: UIBlurEffect.Style
    
    public init(tintColor: UIColor, shadowColor: UIColor, backgroundEffectStyle: UIBlurEffect.Style) {
        self.tintColor = tintColor
        self.shadowColor = shadowColor
        self.backgroundEffectStyle = backgroundEffectStyle
    }
    
    static var `default`: Self = .init(
        tintColor: .systemPink,
        shadowColor: UIColor.mp.borderColor,
        backgroundEffectStyle: .regular
    )
}

class MPNavigationViewController: UINavigationController {
    private let uiConfig: MPUIConfiguration
    
    init(rootViewController: UIViewController, uiConfig: MPUIConfiguration) {
        self.uiConfig = uiConfig
        super.init(rootViewController: rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Logger.log("deinit MPNavigationViewController")
    }
    
    override func loadView() {
        super.loadView()
        configurationStyleNavigationBar()
    }
    
    private func configurationStyleNavigationBar() {
        view.backgroundColor = .none
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Font.medium(17),
            .foregroundColor: UIColor.label
        ]
        let largeAttributes: [NSAttributedString.Key: Any] = [
            .font: Font.medium(34),
            .foregroundColor: UIColor.label
        ]
        
        let scrollAppearance = UINavigationBarAppearance()
        scrollAppearance.configureWithOpaqueBackground()
        scrollAppearance.backgroundEffect = nil
        scrollAppearance.shadowColor = nil
        scrollAppearance.backgroundColor = uiConfig.primaryBackgroundColor
        scrollAppearance.titleTextAttributes = attributes
        scrollAppearance.largeTitleTextAttributes = largeAttributes
        
        
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.shadowImage = UIImage()
        standardAppearance.shadowColor = uiConfig.navigationAppearance.shadowColor
        standardAppearance.backgroundEffect = UIBlurEffect(style: uiConfig.navigationAppearance.backgroundEffectStyle)
        standardAppearance.titleTextAttributes = attributes
        standardAppearance.largeTitleTextAttributes = largeAttributes
        
        navigationBar.tintColor = uiConfig.navigationAppearance.tintColor
        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = scrollAppearance
        navigationBar.compactScrollEdgeAppearance = scrollAppearance
    }
}
