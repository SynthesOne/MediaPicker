//
//  MPRadioCheckboxButton.swift
//
//  Created by Валентин Панчишен on 05.04.2024.
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

private extension UIAction.Identifier {
    static func descriptIdent(_ rawValue: UInt) -> UIAction.Identifier {
        .init(String(rawValue))
    }
}

protocol Actionable: AnyObject {
    func action(_ action: @escaping () -> (), forEvent event: UIControl.Event)
}

extension Actionable where Self: UIControl {
    func action(_ action: @escaping () -> (), forEvent event: UIControl.Event) {
        addAction(.init(identifier: .descriptIdent(event.rawValue), handler: { _ in action() }), for: event)
    }
}

extension UIControl: Actionable { }
