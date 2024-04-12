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

@available(iOS 17.0, *)
#Preview {
    let uiConfig = MPUIConfiguration.default()

    let viewController = UIViewController()
    viewController.view.backgroundColor = .systemBackground
    viewController.view.insetsLayoutMarginsFromSafeArea = false
    
    let button: UIButton = {
        let view = UIButton(frame: .init(origin: .zero, size: .init(width: 120, height: 44)))
        view.setTitle("Add", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .systemRed
        return view
    }()
    
    let button2: UIButton = {
        let view = UIButton(frame: .init(origin: .zero, size: .init(width: 120, height: 44)))
        view.setTitle("Subtract", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .systemRed
        return view
    }()
    
    let footer = MPFooterView()
    viewController.view.mp.addSubviews(button, button2, footer)
    button.center = viewController.view.center
    button2.center = .init(x: viewController.view.center.x, y: viewController.view.center.y + 52)
    var counter = 0
    button.mp.action({
        counter += 1
        footer.setCounter(counter)
    }, forEvent: .touchUpInside)
    
    button2.mp.action({
        counter -= 1
        footer.setCounter(counter)
    }, forEvent: .touchUpInside)
    
    footer.frame = .init(
        x: 0,
        y: viewController.view.safeAreaLayoutGuide.layoutFrame.maxY - 88,
        width: viewController.view.bounds.width,
        height: 88
    )
    
    return viewController
}
