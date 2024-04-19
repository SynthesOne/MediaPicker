//
//  MPAlbumPickerNavView.swift
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

final class MPAlbumPickerNavView: UIView {
    override var intrinsicContentSize: CGSize {
        UIView.layoutFittingExpandedSize
    }
    
    var isShown: Bool!
    
    fileprivate var isEnabled: Bool = true {
        didSet {
            menuView.isEnabled = isEnabled
        }
    }
    
    fileprivate let menuView: MPTitleView = {
        let view = MPTitleView()
        return view
    }()
    
    fileprivate let isCenterAlignment: Bool
    
    var sourceView: UIView {
        menuView.titleLabel
    }
    
    var onTap: ((MPAlbumPickerNavView, Bool) -> ())? = nil
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Logger.log("deinit MPAlbumPickerNavView")
    }
    
    init(
        title: String,
        isCenterAlignment: Bool
    ) {
        self.isCenterAlignment = isCenterAlignment
        super.init(frame: .zero)
        isShown = false
        menuView.frame = frame
        addSubview(menuView)
        menuView.title = title
        menuView.isCenterAlignment = isCenterAlignment
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isCenterAlignment {
            var minX: CGFloat = 50.0
            if let superSpMinX = superview?.superview?.frame.minX, superSpMinX > 0 {
                minX = superSpMinX
            } else if let superMinX = superview?.frame.minX, superMinX > 0 {
                minX = superMinX
            }
            let offset: CGFloat = abs((frame.width + minX) - UIScreenWidth()) - minX
            var leftOffset = offset
            if leftOffset < 0 {
                leftOffset = 0
            }
            var targetOffset = leftOffset
            if isEnabled {
                targetOffset = leftOffset + 20
            }
            
            if leftOffset == 0 {
                targetOffset += offset
            }
            menuView.frame = CGRect(x: targetOffset, y: 0, width: frame.width - targetOffset, height: frame.height)
        } else {
            menuView.frame = CGRect(origin: .zero, size: .init(width: frame.width, height: frame.height))
        }
    }
    
    func show() {
        if isShown == false {
            showMenu()
        }
    }
    
    func hide() {
        if isShown {
            hideMenu()
        }
    }
    
    func toggle() {
        if isShown {
            hideMenu()
        } else {
            showMenu()
        }
    }
    
    func showMenu() {
        isShown = true
        menuView.rotateArrow(isShow: true)
        onTap?(self, true)
    }
    
    func hideMenu() {
        guard isShown else { return }
        menuView.toggleHighlightState(false)
        menuView.rotateArrow(isShow: false)
        isShown = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isEnabled else { return }
        menuView.toggleHighlightState(true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard isEnabled else { return }
        menuView.toggleHighlightState(true)
        isShown ? hideMenu() : showMenu()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard isEnabled else { return }
        menuView.toggleHighlightState(true)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: { [weak self] in
            self?.menuView.toggleHighlightState(false)
        })
    }
    
    func setMenuTitle(_ title: String) {
        menuView.title = title
        layoutIfNeeded()
    }
}
