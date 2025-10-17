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
import Combine

final class MPAlbumPickerNavView: UIView {
    enum State {
        case album, segemented
    }
    
    enum SegmentedState {
        case all, selected
    }
    
    override var intrinsicContentSize: CGSize {
        UIView.layoutFittingExpandedSize
    }
    
    private var isShown: Bool!
    
    fileprivate var isEnabled: Bool = true {
        didSet {
            menuView.isEnabled = isEnabled
        }
    }
    
    fileprivate let menuView: MPTitleView = {
        let view = MPTitleView()
        return view
    }()
    
    fileprivate let selectedControl: UISegmentedControl = {
        let view = UISegmentedControl()
        view.insertSegment(withTitle: Lang.all, at: 0, animated: false)
        view.insertSegment(withTitle: Lang.chosen, at: 1, animated: false)
        return view
    }()
    
    fileprivate let controlContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .center
        view.distribution = .fillProportionally
        view.alpha = 0
        view.transform = .init(scaleX: 0.6, y: 0.6)
        return view
    }()
    
    fileprivate let hStack: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        return view
    }()
    
    fileprivate var isAnimating = false
    fileprivate var disposeBag = Set<AnyCancellable>()
    fileprivate var state: State = .album
    
    var sourceView: UIView {
        menuView.titleLabel
    }
    
    let albumMenuActionSubject = PassthroughSubject<(MPAlbumPickerNavView, Bool), Never>()
    let segmentActionsubject = PassthroughSubject<SegmentedState, Never>()
    let hideMenuHandler = PassthroughSubject<Void, Never>()
    
    var selectedCounter: Int = 0 {
        didSet {
            if selectedCounter != 0 {
                selectedControl.setTitle("\(Lang.chosen) \(selectedCounter)", forSegmentAt: 1)
            }
        }
    }
    
    var containerViewSize: CGFloat = UIScreenWidth() {
        didSet {
            layoutSubviews()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Logger.log("deinit MPAlbumPickerNavView")
    }
    
    init(title: String) {
        super.init(frame: .zero)
        isShown = false
        menuView.frame = frame
        addSubview(menuView)
        hStack.addArrangedSubview(selectedControl)
        controlContainer.addArrangedSubview(hStack)
        addSubview(controlContainer)
        selectedControl.frame.size.height = 30
        menuView.title = title
        
        selectedControl.setAction(.init(handler: { [weak self] (_) in
            self?.segmentActionsubject.send(.all)
        }), forSegmentAt: 0)
        
        selectedControl.setTitle(Lang.all, forSegmentAt: 0)
        selectedControl.selectedSegmentIndex = 0
        
        selectedControl.setAction(.init(handler: { [weak self] (_) in
            self?.segmentActionsubject.send(.selected)
        }), forSegmentAt: 1)
        
        hideMenuHandler
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.hideMenu()
            })
            .store(in: &disposeBag)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var minX: CGFloat = 50.0
		if let superSpSpMinX = superview?.superview?.superview?.frame.minX, superSpSpMinX > 0 {
			minX = superSpSpMinX
		} else if let superSpMinX = superview?.superview?.frame.minX, superSpMinX > 0 {
            minX = superSpMinX
        } else if let superMinX = superview?.frame.minX, superMinX > 0 {
            minX = superMinX
        }
        
        let rightOffset = containerViewSize - frame.width - minX
        
        let targetWidth = frame.width
        
        let leftOffset = rightOffset - minX
        
        menuView.frame = CGRect(x: leftOffset + 20, y: 0, width: targetWidth - (leftOffset + 20), height: frame.height)
        controlContainer.frame = CGRect(x: leftOffset, y: 0, width: targetWidth - leftOffset, height: frame.height)
    }
    
    private func toggleState() {
        switch state {
        case .album:
            menuView.transform = .init(scaleX: 0.6, y: 0.6)
            controlContainer.transform = .identity
            UIView.animate(withDuration: 0.18, animations: {
                self.menuView.alpha = 1.0
                self.menuView.transform = .identity
                self.controlContainer.alpha = 0.0
                self.controlContainer.transform = .init(scaleX: 0.6, y: 0.6)
            })
        case .segemented:
            selectedControl.selectedSegmentIndex = 0
            menuView.transform = .identity
            controlContainer.transform = .init(scaleX: 0.6, y: 0.6)
            UIView.animate(withDuration: 0.18, animations: {
                self.menuView.alpha = 0.0
                self.menuView.transform = .init(scaleX: 0.6, y: 0.6)
                self.controlContainer.alpha = 1.0
                self.controlContainer.transform = .identity
            })
        }
    }
    
    func setState(_ state: State) {
        guard self.state != state else { return }
        self.state = state
        toggleState()
    }
    
    private func show() {
        if isShown == false {
            showMenu()
        }
    }
    
//    private func hide() {
//        if isShown {
//            hideMenu()
//        }
//    }
    
    private func toggle() {
        if isShown {
            hideMenu()
        } else {
            showMenu()
        }
    }
    
    private func showMenu() {
        isShown = true
        menuView.rotateArrow(isShow: true)
        albumMenuActionSubject.send((self, true))
    }
    
    private func hideMenu() {
        guard isShown else { return }
        menuView.toggleHighlightState(false)
        menuView.rotateArrow(isShow: false)
        isShown = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isEnabled, state == .album else { return }
        menuView.toggleHighlightState(true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard isEnabled, state == .album else { return }
        menuView.toggleHighlightState(true)
        isShown ? hideMenu() : showMenu()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard isEnabled, state == .album else { return }
        menuView.toggleHighlightState(true)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: {
            self.menuView.toggleHighlightState(false)
        })
    }
    
    func setMenuTitle(_ title: String) {
        menuView.title = title
        layoutIfNeeded()
    }
}
